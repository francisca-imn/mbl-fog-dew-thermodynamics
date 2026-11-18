# ==============================================================================
# reports.R
#
# Plots of the .docx reports and the functions that render them with Quarto
# (code/reports/*.qmd). The reports read the objects computed by
# run_pipeline.R from a cache file (output/_cache/pipeline.rds).
# ==============================================================================

save_report_cache <- function(classification, thermo, cfg) {
  dir_cache <- file.path(cfg$dir_reports, "_cache")
  dir.create(dir_cache, recursive = TRUE, showWarnings = FALSE)
  file <- file.path(normalizePath(dir_cache), "pipeline.rds")
  saveRDS(list(classification = classification,
               automatic = attr(classification, "automatic"),
               thermo = thermo, cfg = cfg), file)
  file
}

find_quarto <- function() {
  q <- Sys.getenv("QUARTO_PATH")
  if (nzchar(q) && file.exists(q)) return(q)
  q <- Sys.which("quarto")
  if (nzchar(q)) return(unname(q))
  if (requireNamespace("quarto", quietly = TRUE)) {
    q <- tryCatch(quarto::quarto_path(), error = function(e) NULL)
    if (!is.null(q) && nzchar(q)) return(q)
  }
  # RStudio and Positron ship their own Quarto
  candidates <- c("/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
                  "/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto",
                  "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe")
  candidates <- candidates[file.exists(candidates)]
  if (length(candidates) > 0) return(candidates[1])
  stop("Quarto was not found. Install it (https://quarto.org) or set the ",
       "environment variable QUARTO_PATH to the quarto executable.")
}

render_report <- function(name, cache, cfg) {
  qmd <- file.path(cfg$root, "code", "reports", paste0(name, ".qmd"))
  dir.create(cfg$dir_reports, recursive = TRUE, showWarnings = FALSE)
  out_dir <- normalizePath(cfg$dir_reports)
  message("Rendering ", name, ".docx")
  status <- system2(find_quarto(),
                    c("render", shQuote(qmd), "--to", "docx",
                      "--output-dir", shQuote(out_dir),
                      "-P", shQuote(paste0("cache:", cache)),
                      "-P", shQuote(paste0("root:", cfg$root))))
  if (status != 0) stop("Quarto could not render ", qmd)
  invisible(file.path(out_dir, paste0(name, ".docx")))
}

pretty_date <- function(d) paste0(format(d, "%B"), " ", as.integer(format(d, "%d")), ", ", format(d, "%Y"))


# ------------------------------------------------------------------------------
# Daily classification: half-month panels (one facet per day) with the
# visibility (1000 m threshold), the classification band and the FLC band
# ------------------------------------------------------------------------------
plot_half_month <- function(df, month_int, half_month = 1, days = NULL, title_suffix = "",
                            vis_threshold = 1000, facet_ncol = 4) {

  dsub <- df %>%
    filter(month(fecha) == month_int) %>%
    filter(if (half_month == 1) day(fecha) <= 15 else day(fecha) > 15)
  if (!is.null(days)) dsub <- dsub %>% filter(fecha %in% days)

  if (nrow(dsub) == 0) return(NULL)

  band_h <- 500
  y_cls  <- -500
  y_goes <- -1200

  dsub <- dsub %>%
    mutate(class_fac = factor(clasif_evento, levels = c("NIEBLA", "ROCIO", "SIN_EVENTO")))

  ggplot(dsub, aes(x = ts_10)) +
    geom_tile(aes(y = y_goes, alpha = fog_sat), fill = "grey30", height = band_h, width = 600) +
    scale_alpha_continuous(range = c(0.15, 0.9), na.value = 0, guide = "none") +
    geom_tile(aes(y = y_cls, fill = class_fac), height = band_h, width = 600) +
    scale_fill_manual(values = c("NIEBLA" = "#6baed6", "ROCIO" = "#c97a4a", "SIN_EVENTO" = "#bdbdbd"),
                      labels = c("NIEBLA" = "Fog", "ROCIO" = "Dew", "SIN_EVENTO" = "No AW"),
                      name = "Classification", drop = FALSE, na.value = "white") +
    geom_line(aes(y = vis_m, group = fecha), color = "#08519c", linewidth = 0.35, na.rm = TRUE) +
    geom_hline(yintercept = vis_threshold, linetype = "dashed", color = "red", linewidth = 0.35) +
    geom_hline(yintercept = 0, color = "black", linewidth = 0.4) +
    scale_y_continuous(limits = c(-1700, 5000),
                       breaks = c(-1200, -500, 0, 1000, 2000, 3000, 4000, 5000),
                       labels = c("FLC", "Classif.", "0", "1000", "2000", "3000", "4000", "5000"),
                       expand = expansion(mult = c(0.01, 0.03)), oob = scales::squish) +
    scale_x_datetime(date_breaks = "2 hours", date_labels = "%H:%M") +
    facet_wrap(~ fecha, ncol = facet_ncol, scales = "free_x") +
    labs(x = "Time (UTC)", y = "Visibility (m)",
         title = paste0(month.name[month_int], " ", year(min(dsub$fecha)),
                        if (half_month == 1) ", days 1-15" else ", days 16-end", title_suffix)) +
    theme_bw(base_size = 8) +
    theme(legend.position = "bottom",
          strip.text = element_text(face = "bold"),
          axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
          axis.text.y = element_text(face = "bold"),
          plot.margin = margin(6, 6, 6, 42))
}


# ------------------------------------------------------------------------------
# Daily vertical profiles: hourly profiles (minute 00) of θ, q and U and of
# their vertical gradients relative to the reference station, one figure per day
# ------------------------------------------------------------------------------
prepare_hourly_profiles <- function(thermo, cfg) {
  hourly <- thermo %>%
    filter(minute(datetime) == 0, !estacion %in% cfg$excluded_stations) %>%
    add_gradients(cfg) %>%
    mutate(fecha = as.Date(datetime), hora = hour(datetime))

  # classification of the main station at each hour, assigned to every station
  cls <- thermo %>%
    filter(estacion == cfg$main_station, minute(datetime) == 0) %>%
    distinct(datetime, .keep_all = TRUE) %>%
    select(datetime, clase = clasif_evento)

  hourly %>%
    left_join(cls, by = "datetime") %>%
    transmute(fecha, hora, estacion, z_m,
              clase = factor(recode(clase, !!!regime_labels, .missing = "No data"),
                             levels = c("Fog", "Dew", "No AW", "No data")),
              theta = theta_K, q = q_gkg, U = viento_vel_m_s,
              dtheta = 1000 * grad_theta, dq = 1000 * grad_q, dU = 1000 * grad_u)
}

profile_panel_labels <- c(
  theta  = "theta~(K)",
  q      = "q~(g~kg^{-1})",
  U      = "U~(m~s^{-1})",
  dtheta = "partialdiff*theta/partialdiff*z~(10^{-3}~K~m^{-1})",
  dq     = "partialdiff*q/partialdiff*z~(10^{-3}~g~kg^{-1}~m^{-1})",
  dU     = "partialdiff*U/partialdiff*z~(10^{-3}~s^{-1})"
)

plot_day_profiles <- function(day, hourly, classification, cfg) {
  d <- hourly %>% filter(fecha == day)
  if (nrow(d) == 0) return(NULL)

  long <- d %>%
    pivot_longer(c(theta, q, U, dtheta, dq, dU), names_to = "variable", values_to = "value") %>%
    filter(!is.na(value)) %>%
    mutate(variable = factor(profile_panel_labels[variable], levels = profile_panel_labels)) %>%
    arrange(variable, hora, z_m)
  if (nrow(long) == 0) return(NULL)

  # stations evenly spaced on the Y axis (as in Figures 5 and 6 of the paper)
  z_levels <- sort(unique(hourly$z_m))
  long <- long %>% mutate(y = match(z_m, z_levels))
  y_main <- match(hourly$z_m[hourly$estacion == cfg$main_station][1], z_levels)

  zero_lines <- tibble(variable = factor(profile_panel_labels[c("dtheta", "dq", "dU")],
                                         levels = profile_panel_labels), x = 0)
  thr <- bind_rows(
    tibble(variable = profile_panel_labels[["dtheta"]], x = 1000 * cfg$threshold_lines$grad_theta),
    tibble(variable = profile_panel_labels[["dq"]],     x = 1000 * cfg$threshold_lines$grad_q)
  ) %>% mutate(variable = factor(variable, levels = profile_panel_labels))

  # duration (h) of fog and dew at the main station on this day
  dur <- classification %>% filter(fecha == day) %>%
    summarise(fog = sum(clasif_evento == "NIEBLA", na.rm = TRUE) / 6,
              dew = sum(clasif_evento == "ROCIO", na.rm = TRUE) / 6)
  ref_z <- hourly$z_m[hourly$estacion == cfg$reference_station][1]

  ggplot(long, aes(x = value, y = y, group = hora, color = hora)) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = y_main - 0.4, ymax = y_main + 0.4,
             fill = "#f3f1ea", color = NA) +
    geom_vline(data = zero_lines, aes(xintercept = x), linetype = "dashed",
               color = "grey40", linewidth = 0.4) +
    geom_vline(data = thr, aes(xintercept = x), linetype = "dotted",
               color = "red3", linewidth = 0.6) +
    geom_path(alpha = 0.75, linewidth = 0.6) +
    # white halo for the fog and dew hours
    geom_point(data = long %>% filter(clase %in% c("Fog", "Dew")),
               color = "white", size = 3.2) +
    geom_point(aes(shape = clase), size = 1.9, show.legend = TRUE) +
    scale_color_viridis_c(option = "turbo", limits = c(0, 23), breaks = seq(0, 21, 3),
                          name = "Hour (UTC)",
                          guide = guide_colorbar(barwidth = unit(7, "cm"), order = 1)) +
    scale_shape_manual(values = c("Fog" = 17, "Dew" = 15, "No AW" = 16, "No data" = 1),
                       drop = FALSE, name = paste0("Class at ", station_label(cfg$main_station)),
                       guide = guide_legend(order = 2, override.aes = list(size = 2.5, color = "grey20"))) +
    scale_y_continuous(breaks = seq_along(z_levels), labels = paste0(z_levels, " m"),
                       expand = expansion(add = 0.5)) +
    facet_wrap(~ variable, ncol = 3, scales = "free_x", labeller = label_parsed) +
    labs(
      title = paste0(pretty_date(day), ": fog ", sprintf("%.1f", dur$fog), " h, dew ",
                     sprintf("%.1f", dur$dew), " h at ", station_label(cfg$main_station)),
      subtitle = paste0("Hourly profiles (minute 00, UTC). Gradients relative to ",
                        station_label(cfg$reference_station), " (", ref_z,
                        " m). Dotted red lines: thresholds; shaded band: ",
                        station_label(cfg$main_station), "."),
      x = NULL, y = "Altitude (m a.s.l.)"
    ) +
    theme_bw(base_size = 9) +
    theme(
      legend.position = "bottom",
      legend.box = "vertical",
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(size = 7.5, color = "grey30"),
      strip.background = element_rect(fill = "#f9f9f7"),
      panel.grid.minor = element_blank()
    )
}


# ------------------------------------------------------------------------------
# Temporal tendencies: accumulated change after each occurrence type
# ------------------------------------------------------------------------------
tendency_theme <- function() {
  theme_classic(base_size = 9) +
    theme(
      legend.title    = element_blank(),
      legend.position = "bottom",
      axis.line       = element_line(color = "#c3c2b7"),
      axis.ticks      = element_line(color = "#c3c2b7"),
      panel.grid.major.y = element_line(color = "#ecebe6", linewidth = 0.3),
      panel.border    = element_rect(color = "#c3c2b7", fill = NA, linewidth = 0.4),
      strip.background = element_rect(fill = "#e9e5d9", color = NA),
      strip.text      = element_text(face = "bold"),
      plot.title      = element_text(face = "bold", size = 10)
    )
}

variable_labels <- c(q = "partialdiff*q~(g~kg^{-1})",
                     theta = "partialdiff*theta~(K)",
                     U = "partialdiff*U~(m~s^{-1})")

plot_tendency_curves <- function(tend, facet_rows, facet_cols, title = NULL) {
  ggplot(tend, aes(lag_min, media, color = regimen, fill = regimen)) +
    geom_hline(yintercept = 0, color = "#c3c2b7", linewidth = 0.4) +
    geom_vline(xintercept = 60, color = "#c3c2b7", linetype = "22", linewidth = 0.4) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, color = NA) +
    geom_line(linewidth = 0.7) +
    scale_color_manual(values = regime_colours, drop = FALSE) +
    scale_fill_manual(values = regime_colours, drop = FALSE) +
    scale_x_continuous(breaks = seq(0, 120, 30)) +
    facet_grid(rows = vars({{ facet_rows }}), cols = vars({{ facet_cols }}),
               scales = "free_y", labeller = label_parsed) +
    labs(x = "Minutes after the record", y = NULL, title = title) +
    tendency_theme()
}

# Mean diurnal cycle (hour of day, UTC) of the 1-h change ∂φ = φ(t + 60 min) − φ(t)
# at the main station, by occurrence type of the record at t
diurnal_tendency <- function(thermo, cfg) {
  thermo %>%
    filter(estacion == cfg$main_station) %>%
    distinct(datetime, .keep_all = TRUE) %>%
    select(datetime, clasif_evento, q = q_gkg, theta = theta_K, U = viento_vel_m_s) %>%
    complete(datetime = seq(min(datetime), max(datetime), by = "10 min")) %>%
    arrange(datetime) %>%
    mutate(across(c(q, theta, U), ~ lead(.x, 6) - .x),
           hour = hour(datetime)) %>%
    filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
    pivot_longer(c(q, theta, U), names_to = "variable", values_to = "d") %>%
    group_by(variable, clasif_evento, hour) %>%
    summarise(media = mean(d, na.rm = TRUE),
              se = sd(d, na.rm = TRUE) / sqrt(sum(!is.na(d))),
              n = sum(!is.na(d)), .groups = "drop") %>%
    mutate(regimen = as_regime(clasif_evento),
           lo = media - 1.96 * se, hi = media + 1.96 * se,
           variable_lab = factor(variable_labels[variable], levels = variable_labels))
}

plot_diurnal_tendency <- function(dt, min_n = 10) {
  # hours with too few records are left empty (the lines are broken there)
  dt <- dt %>%
    complete(nesting(variable, variable_lab), regimen, hour = 0:23) %>%
    mutate(across(c(media, lo, hi), ~ if_else(!is.na(n) & n >= min_n, .x, NA_real_)))
  ggplot(dt, aes(hour, media, color = regimen, fill = regimen)) +
    geom_hline(yintercept = 0, color = "#c3c2b7", linewidth = 0.4) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, color = NA, na.rm = TRUE) +
    geom_line(linewidth = 0.6, na.rm = TRUE) +
    geom_point(size = 1, na.rm = TRUE) +
    scale_color_manual(values = regime_colours, drop = FALSE) +
    scale_fill_manual(values = regime_colours, drop = FALSE) +
    scale_x_continuous(breaks = seq(0, 21, 3), limits = c(0, 23)) +
    facet_wrap(~ variable_lab, ncol = 1, scales = "free_y", labeller = label_parsed) +
    labs(x = "Hour of the record (UTC)", y = "Mean change in the next 60 min") +
    tendency_theme()
}
