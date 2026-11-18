# ==============================================================================
# pipeline_core.R
#
# Configuration, input table, fog/dew classification and thermodynamic
# variables. Used by run_pipeline.R.
#
# Internal column names are kept in Spanish (estacion, temperatura, humedad,
# presion, viento_vel_m_s, radiacion_w_m2, visibilidad, niebla_final,
# rocio_final, FLC, clasif_evento) for compatibility with the derived files of
# the original processing (see the data dictionary in the README).
# ==============================================================================

# Internal name of each variable of the input table
internal_names <- c(
  datetime    = "datetime",
  station     = "estacion",
  z_m         = "z_m",
  temperature = "temperatura",
  rh          = "humedad",
  pressure    = "presion",
  wind_speed  = "viento_vel_m_s",
  radiation   = "radiacion_w_m2",
  visibility  = "visibilidad",
  fog_water   = "niebla_final",
  dew_water   = "rocio_final",
  flc         = "FLC"
)

required_columns <- c("datetime", "station", "z_m", "temperature", "rh",
                      "wind_speed", "fog_water", "dew_water")

# Gathers the settings of run_pipeline.R into one list (cfg) and checks them
build_config <- function(env) {
  get0e <- function(x, default = NULL) get0(x, envir = env, ifnotfound = default)
  cfg <- list(
    outputs                  = get0e("outputs"),
    input_file               = get0e("input_file"),
    columns                  = get0e("columns"),
    year                     = get0e("year"),
    reference_station        = get0e("reference_station"),
    main_station             = get0e("main_station"),
    excluded_stations        = get0e("excluded_stations", character(0)),
    visibility_fog_threshold = get0e("visibility_fog_threshold", 1000),
    night_radiation_max      = get0e("night_radiation_max", 5),
    manual_corrections_file  = get0e("manual_corrections_file"),
    output_classification    = get0e("output_classification"),
    output_thermodynamics    = get0e("output_thermodynamics"),
    dir_figures              = get0e("dir_figures", "figures"),
    dir_results              = get0e("dir_results", "results"),
    dir_reports              = get0e("dir_reports", "output"),
    daily_days               = get0e("daily_days", "aw"),
    daily_dpi                = get0e("daily_dpi", 150),
    report_dpi               = get0e("report_dpi", 300),
    threshold_lines          = get0e("threshold_lines", list()),
    tendency_stations        = get0e("tendency_stations"),
    paper                    = get0e("paper", list()),
    root                     = normalizePath(getwd())
  )

  # every switch of section 1 must exist and be TRUE/FALSE
  switches <- c("derived_tables", "statistics_events", "seasonal_thresholds",
                "paper_figures_png", "docx_classification", "docx_daily_profiles",
                "docx_temporal_tendencies", "docx_paper_figures")
  missing_sw <- setdiff(switches, names(cfg$outputs))
  if (length(missing_sw) > 0) stop("Missing switches in `outputs`: ", paste(missing_sw, collapse = ", "))
  for (s in switches) {
    if (!isTRUE(cfg$outputs[[s]]) && !isFALSE(cfg$outputs[[s]])) stop("`outputs$", s, "` must be TRUE or FALSE")
  }
  if (!file.exists(cfg$input_file)) stop("Input file not found: ", cfg$input_file,
                                         "\n(run it from the repository root; for Cerro Oyarbide, build it first with",
                                         " Rscript code/prep_oyarbide/03_standard_table.R)")
  missing_cols <- setdiff(required_columns, names(cfg$columns)[!is.na(cfg$columns)])
  if (length(missing_cols) > 0) stop("`columns` must name: ", paste(missing_cols, collapse = ", "))
  cfg
}

# Reads the input table and renames its columns to the internal names
read_standard_table <- function(cfg) {
  cols <- cfg$columns[!is.na(cfg$columns)]
  header <- names(read_csv(cfg$input_file, n_max = 0, show_col_types = FALSE))
  absent <- setdiff(unname(cols), header)
  if (length(absent) > 0) stop("Columns not found in ", cfg$input_file, ": ", paste(absent, collapse = ", "))

  # explicit types: guessing from the first rows fails for variables that only
  # exist at the main station (e.g. visibility would be read as logical)
  types <- setNames(rep(list(col_double()), length(cols)), unname(cols))
  types[[cols[["datetime"]]]] <- col_datetime()
  types[[cols[["station"]]]]  <- col_character()

  std <- read_csv(cfg$input_file, col_types = do.call(cols_only, types))
  std <- std[, unname(cols)]
  names(std) <- internal_names[names(cols)]

  # optional variables that do not exist are created as NA
  for (v in setdiff(names(internal_names), names(cols))) std[[internal_names[[v]]]] <- NA_real_

  std <- std %>%
    mutate(datetime = as.POSIXct(datetime, tz = "UTC")) %>%
    filter(year(datetime) == cfg$year)

  stations <- unique(std$estacion)
  for (s in c(cfg$reference_station, cfg$main_station)) {
    if (!s %in% stations) stop("Station '", s, "' not found in the input table")
  }
  if (any(is.na(std$z_m))) stop("Every row needs the station altitude (z_m)")
  z_by_station <- std %>% distinct(estacion, z_m) %>% count(estacion)
  if (any(z_by_station$n > 1)) stop("Each station must have a single altitude (z_m)")

  main <- std %>% filter(estacion == cfg$main_station)
  if (all(is.na(main$visibilidad)) && all(is.na(main$FLC))) {
    warning("The main station has neither visibility nor FLC: records with water cannot be classified")
  }
  std
}

z_of <- function(thermo_or_std, station) {
  thermo_or_std$z_m[thermo_or_std$estacion == station][1]
}

# Reads the manual corrections (.R defining `manual_corrections`, or .csv)
read_manual_corrections <- function(file) {
  if (is.null(file) || is.na(file)) return(NULL)
  if (!file.exists(file)) stop("Manual corrections file not found: ", file)
  if (grepl("\\.csv$", file, ignore.case = TRUE)) {
    mc <- read_csv(file, show_col_types = FALSE) %>%
      mutate(start = ymd_hms(start, tz = "UTC"), end = ymd_hms(end, tz = "UTC"))
  } else {
    e <- new.env()
    sys.source(file, envir = e)
    mc <- get("manual_corrections", envir = e)
  }
  stopifnot(all(c("start", "end", "occurrence") %in% names(mc)),
            all(mc$occurrence %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")))
  mc
}

# ------------------------------------------------------------------------------
# Classification of the records of the main station (manuscript, Eq. 1)
#   1. no water in any collector                    -> SIN_EVENTO (no AW)
#   2. visibility available: < threshold -> NIEBLA (fog), otherwise ROCIO (dew)
#   3. visibility missing:   FLC = 1 -> NIEBLA, FLC = 0 -> ROCIO
#   4. manual corrections (only on records with water)
# Returns the records of the main station with the classification columns.
# ------------------------------------------------------------------------------
classify_occurrences <- function(std, cfg, manual = TRUE) {
  vis_thr <- cfg$visibility_fog_threshold

  auto <- std %>%
    filter(estacion == cfg$main_station) %>%
    mutate(
      ts_10 = floor_date(datetime, "10 minutes"),
      fecha = as.Date(ts_10),
      vis_m = visibilidad,
      # instrumental collection: 1 if the collector registered water
      fog_cap = if_else(!is.na(niebla_final) & niebla_final > 0, 1L, 0L),
      dew_cap = if_else(!is.na(rocio_final)  & rocio_final  > 0, 1L, 0L),
      any_cap = if_else(fog_cap == 1L | dew_cap == 1L, 1L, 0L),
      # satellite fog and low clouds; NA when there is no satellite data
      fog_sat = case_when(is.na(FLC) ~ NA_integer_, FLC == 1 ~ 1L, TRUE ~ 0L)
    ) %>%
    mutate(
      clasif_evento = case_when(
        any_cap == 0L ~ "SIN_EVENTO",

        !is.na(vis_m) & vis_m <  vis_thr ~ "NIEBLA",
        !is.na(vis_m) & vis_m >= vis_thr ~ "ROCIO",

        is.na(vis_m) & fog_sat == 1L ~ "NIEBLA",
        is.na(vis_m) & fog_sat == 0L ~ "ROCIO",

        TRUE ~ NA_character_
      )
    ) %>%
    filter(year(fecha) == cfg$year)

  if (!manual) return(auto)

  corrections <- read_manual_corrections(cfg$manual_corrections_file)
  out <- auto
  if (!is.null(corrections)) {
    for (i in seq_len(nrow(corrections))) {
      out <- out %>%
        mutate(
          clasif_evento = if_else(
            datetime >= corrections$start[i] &
              datetime <= corrections$end[i] &
              any_cap == 1,
            corrections$occurrence[i],
            clasif_evento
          )
        )
    }
  }
  attr(out, "automatic") <- auto$clasif_evento
  out
}

# ------------------------------------------------------------------------------
# Pressure, potential temperature (θ) and specific humidity (q) of every record.
# The classification of the main station is assigned to every station at the
# same time step. Pressure: measured, or hypsometric from the reference station
# with the mean temperature of the layer. θ referred to the reference pressure.
# q from the Magnus formula.
# ------------------------------------------------------------------------------
add_thermodynamics <- function(std, classification, cfg) {
  R  <- 287        # J kg-1 K-1
  Cp <- 1004.67    # J kg-1 K-1
  g  <- 9.80665    # m s-2
  epsilon <- 0.622

  z_ref <- z_of(std, cfg$reference_station)

  dat <- std %>%
    left_join(classification %>% select(datetime, clasif_evento), by = "datetime")

  reference <- dat %>%
    filter(estacion == cfg$reference_station) %>%
    select(datetime, P1 = presion, T1_C = temperatura)

  dat %>%
    left_join(reference, by = "datetime") %>%
    mutate(
      T_K  = temperatura + 273.15,
      T1_K = T1_C + 273.15,
      Tmedia_K = (T_K + T1_K) / 2
    ) %>%
    mutate(
      z1 = z_ref,
      delta_z = z_m - z1,
      presion_calc = P1 * exp(-(g * delta_z) / (R * Tmedia_K)),
      presion_final = if_else(is.na(presion) & !is.na(P1), presion_calc, presion)
    ) %>%
    mutate(
      theta_K = T_K * (P1 / presion_final)^(R / Cp)
    ) %>%
    mutate(
      es_hPa = 6.112 * exp((17.67 * temperatura) / (temperatura + 243.5)),
      e_hPa  = (humedad / 100) * es_hPa,
      q_kgkg = (epsilon * e_hPa) / (presion_final - (1 - epsilon) * e_hPa),
      q_gkg  = q_kgkg * 1000
    )
}

# Vertical gradients between each station and the reference station, every
# 10 min (0 at the reference station)
add_gradients <- function(thermo, cfg) {
  ref <- cfg$reference_station
  z_ref <- z_of(thermo, ref)
  thermo %>%
    group_by(datetime) %>%
    mutate(
      theta_ref  = theta_K[estacion == ref][1],
      q_ref      = q_gkg[estacion == ref][1],
      u_ref      = viento_vel_m_s[estacion == ref][1],
      grad_theta = if_else(z_m == z_ref, 0, (theta_K - theta_ref) / (z_m - z_ref)),
      grad_q     = if_else(z_m == z_ref, 0, (q_gkg - q_ref) / (z_m - z_ref)),
      grad_u     = if_else(z_m == z_ref, 0, (viento_vel_m_s - u_ref) / (z_m - z_ref))
    ) %>%
    ungroup()
}

# Days of the daily reports
select_days <- function(classification, cfg) {
  if (inherits(cfg$daily_days, "Date")) return(sort(cfg$daily_days))
  all_days <- sort(unique(classification$fecha))
  if (identical(cfg$daily_days, "all")) return(all_days)
  if (identical(cfg$daily_days, "aw")) {
    return(sort(unique(classification$fecha[classification$clasif_evento %in% c("NIEBLA", "ROCIO")])))
  }
  stop("`daily_days` must be \"aw\", \"all\" or a vector of dates")
}

# Shared labels and colours
regime_labels <- c("NIEBLA" = "Fog", "ROCIO" = "Dew", "SIN_EVENTO" = "No AW")
regime_colours <- c("Fog" = "#4292c6", "Dew" = "#c97a4a", "No AW" = "#7f7f7f")
as_regime <- function(x) {
  factor(recode(x, !!!regime_labels), levels = c("Fog", "Dew", "No AW"))
}
station_label <- function(x) str_remove(x, "_")
