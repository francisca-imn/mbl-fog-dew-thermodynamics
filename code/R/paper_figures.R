# ==============================================================================
# paper_figures.R
#
# Figures 2 to 9 and A1 of the manuscript (PNG, 300 dpi) and the values used in
# the text (CSV in results/paper_values/). The plotting code is the one of the
# original figure notebooks; only the inputs (stations, dates, altitudes) come
# from the configuration of run_pipeline.R.
#
#   Figure 2   fig02_classification_summary.png      classification summary
#   Figure 3   fig03_typical_days.png                typical fog and dew days
#   Figure A1  figA1_particular_cases.png            particular cases
#   Figure 4   fig04_seasonal_diurnal_distribution.png
#   Figure 5   fig05_profiles_typical_days.png       vertical profiles, typical days
#   Figure 6   fig06_vertical_gradients.png          mean vertical gradients
#   Figure 7   fig07_diurnal_cycle.png               diurnal cycle, fog and dew night
#   Figure 8   fig08_temporal_tendencies_day_night.png
#   Figure 9   fig09_temporal_tendencies_stations.png
# Figure 1 (map and photographs) is not produced by code.
# ==============================================================================

paper_figure_files <- c(
  "2"  = "fig02_classification_summary.png",
  "3"  = "fig03_typical_days.png",
  "4"  = "fig04_seasonal_diurnal_distribution.png",
  "5"  = "fig05_profiles_typical_days.png",
  "6"  = "fig06_vertical_gradients.png",
  "7"  = "fig07_diurnal_cycle.png",
  "8"  = "fig08_temporal_tendencies_day_night.png",
  "9"  = "fig09_temporal_tendencies_stations.png",
  "A1" = "figA1_particular_cases.png"
)

make_paper_figures <- function(classification, thermo, cfg) {
  dir.create(cfg$dir_figures, recursive = TRUE, showWarnings = FALSE)
  dir_val <- file.path(cfg$dir_results, "paper_values")
  dir.create(dir_val, recursive = TRUE, showWarnings = FALSE)

  fig02_classification_summary(classification, cfg, dir_val)
  fig03_typical_days(classification, cfg)
  fig04_distribution(classification, cfg, dir_val)
  fig05_06_stability(thermo, cfg, dir_val)
  fig07_diurnal_cycle(thermo, cfg, dir_val)
  fig08_tendencies_day_night(thermo, cfg, dir_val)
  fig09_tendencies_stations(thermo, cfg, dir_val)
  invisible(TRUE)
}

save_fig <- function(plot, file, width, height, cfg) {
  ggsave(file.path(cfg$dir_figures, file), plot, width = width, height = height,
         dpi = 300, bg = "white")
}


# ------------------------------------------------------------------------------
# Figure 2 (Section 3.1): classification of the AW occurrences at the main station
#   (A) share of the 10-min records of the year with AW and with no AW
#   (B) collector-based classification (SFC only, SDC only, both collectors)
#   (C) reclassification based on visibility and satellite FLC detection
# ------------------------------------------------------------------------------
fig02_classification_summary <- function(clasif, cfg, dir_val) {

  n_total <- nrow(clasif)
  pct <- function(x) round(100 * sum(x, na.rm = TRUE) / n_total, 2)

  pct_sin  <- pct(clasif$clasif_evento == "SIN_EVENTO")
  pct_agua <- round(100 - pct_sin, 2)

  # % of the year in each category (collector-based: which collector registered water)
  instrumental <- tibble(
    categoria = c("Fog", "Fog + Dew", "Dew"),
    pct_anual = with(clasif, c(pct(fog_cap == 1 & dew_cap == 0),
                               pct(fog_cap == 1 & dew_cap == 1),
                               pct(fog_cap == 0 & dew_cap == 1)))
  )
  clasificado <- tibble(
    categoria = c("Fog", "Dew"),
    pct_anual = with(clasif, c(pct(clasif_evento == "NIEBLA"), pct(clasif_evento == "ROCIO")))
  )

  col_cat <- c("Fog" = "#4292c6", "Fog + Dew" = "#8c6bb1", "Dew" = "#c97a4a",
               "No AW" = "#e3e2dc", "Atmospheric water" = "#525252")

  tema_titulo <- theme(plot.title = element_text(face = "bold", size = 10, hjust = 0),
                       plot.subtitle = element_text(size = 8.5, color = "grey35", hjust = 0))

  # (A) bar of the whole year
  barra <- tibble(categoria = factor(c("Atmospheric water", "No AW"),
                                     levels = c("No AW", "Atmospheric water")),
                  pct = c(pct_agua, pct_sin))

  pA <- ggplot(barra, aes(x = 1, y = pct, fill = categoria)) +
    geom_col(width = 0.6, color = "white", linewidth = 0.6) +
    geom_text(data = barra %>% filter(categoria == "No AW"),
              aes(y = pct_agua + pct_sin / 2,
                  label = paste0("No AW, ", sprintf("%.1f", pct), "%")),
              size = 3.2, color = "grey30") +
    # atmospheric water label inside the dark rectangle, in white
    annotate("text", x = 1, y = pct_agua / 2, size = 2.35, color = "white",
             fontface = "bold", lineheight = 0.9,
             label = paste0("Atmospheric\nwater ", sprintf("%.1f", pct_agua), "%")) +
    coord_flip(clip = "off") +
    scale_fill_manual(values = col_cat) +
    scale_y_continuous(expand = expansion(add = 0)) +
    labs(title = paste0("(A) AW occurrences in ", cfg$year)) +
    theme_void() + tema_titulo +
    theme(legend.position = "none", plot.margin = margin(4, 12, 8, 12))

  # (B) and (C) donuts with the distribution within the atmospheric water window
  dona <- function(d, titulo) {
    d <- d %>%
      mutate(categoria = factor(categoria, levels = categoria),
             pct_interno = 100 * pct_anual / sum(pct_anual),
             ymax = cumsum(pct_interno), ymin = lag(ymax, default = 0),
             mid = (ymin + ymax) / 2,
             pequeno = pct_interno < 8,
             etiqueta = if_else(pequeno,
                                paste0(categoria, " ", sprintf("%.1f", pct_interno), "%"),
                                paste0(str_replace(categoria, " \\+ ", " +\n"), "\n", sprintf("%.1f", pct_interno), "%")))
    ggplot(d) +
      geom_rect(aes(ymin = ymin, ymax = ymax, xmin = 1.9, xmax = 4, fill = categoria),
                color = "white", linewidth = 0.8) +
      # labels inside the ring (large sectors) or outside (small sectors)
      geom_text(data = d %>% filter(!pequeno),
                aes(x = 2.95, y = mid, label = etiqueta),
                color = "white", fontface = "bold", size = 3, lineheight = 0.9) +
      geom_segment(data = d %>% filter(pequeno),
                   aes(x = 4, xend = 4.45, y = mid, yend = mid),
                   color = "grey45", linewidth = 0.3) +
      geom_text(data = d %>% filter(pequeno),
                aes(x = 4.75, y = mid, label = etiqueta),
                color = "grey20", size = 3, hjust = 0.5) +
      annotate("text", x = 0, y = 0, label = paste0(sprintf("%.1f", pct_agua), "%\nof the year"),
               size = 2.9, color = "grey35", lineheight = 0.9) +
      coord_polar(theta = "y", clip = "off") +
      xlim(c(0, 4.9)) +
      scale_fill_manual(values = col_cat) +
      labs(title = titulo) +
      theme_void() + tema_titulo +
      theme(legend.position = "none", plot.margin = margin(4, 8, 4, 8))
  }

  pB <- dona(instrumental, "(B) Collectors classification (SFC and SDC)")
  pC <- dona(clasificado,  "(C) Visibility and GOES-16 FLC reclassification")

  fig_resumen <- pA / (pB | pC) + plot_layout(heights = c(0.22, 1))

  save_fig(fig_resumen, paper_figure_files[["2"]], 9, 5, cfg)

  bind_rows(
    instrumental %>% mutate(scheme = "Collectors"),
    clasificado  %>% mutate(scheme = "Reclassification")
  ) %>%
    group_by(scheme) %>%
    mutate(pct_within_aw = round(100 * pct_anual / sum(pct_anual), 1)) %>%
    ungroup() %>%
    bind_rows(tibble(scheme = "Year", categoria = c("No AW", "Atmospheric water"),
                     pct_anual = c(pct_sin, pct_agua))) %>%
    rename(category = categoria, pct_of_year = pct_anual) %>%
    write_csv(file.path(dir_val, "fig02_classification_summary.csv"))
}


# ------------------------------------------------------------------------------
# Figure 3 (typical fog and dew days) and Figure A1 (particular cases).
# Visibility at the main station (1000 m threshold) and three bands every
# 10 min: reclassification, collector-based detection and satellite FLC.
# ------------------------------------------------------------------------------
fig03_typical_days <- function(oya1211_clasif_manual, cfg) {

  td <- cfg$paper$typical_days %>% mutate(date = ymd(date))
  dias_niebla <- as.character(td$date[td$group == "fog"])
  dias_rocio  <- as.character(td$date[td$group == "dew"])
  dias_otros  <- as.character(td$date[td$group == "other"])

  dias_seleccionados <- td %>% transmute(fecha = date, etiqueta = label)

  label_dias <- setNames(dias_seleccionados$etiqueta, as.character(dias_seleccionados$fecha))

  # Collector-based detection (before the reclassification), from fog_cap/dew_cap
  col_captacion <- c(
    "Fog"           = "#4292c6",
    "Dew"           = "#c97a4a",
    "Both"          = "#8c6bb1",
    "No AW" = "#e3e2dc"
  )
  col_clasif <- c("Fog" = "#4292c6", "Dew" = "#c97a4a", "No AW" = "#e3e2dc")

  dsub <- oya1211_clasif_manual %>%
    inner_join(dias_seleccionados, by = "fecha") %>%
    mutate(
      fecha = as.character(fecha),
      clasif_fac = factor(
        recode(clasif_evento, "NIEBLA" = "Fog", "ROCIO" = "Dew", "SIN_EVENTO" = "No AW"),
        levels = c("Fog", "Dew", "No AW")
      ),
      captacion_fac = case_when(
        fog_cap == 1 & dew_cap == 1 ~ "Both",
        fog_cap == 1 & dew_cap == 0 ~ "Fog",
        fog_cap == 0 & dew_cap == 1 ~ "Dew",
        TRUE                        ~ "No AW"
      ),
      captacion_fac = factor(captacion_fac, levels = names(col_captacion)),
      captacion_color = col_captacion[as.character(captacion_fac)]
    )

  band_h <- 500
  y_cls  <- -500
  y_inst <- -1200
  y_goes <- -1900

  plot_fila_dias <- function(df, fechas_grupo, ncol_grupo, titulo_grupo, mostrar_x = FALSE) {

    d <- df %>%
      filter(fecha %in% fechas_grupo) %>%
      mutate(fecha = factor(fecha, levels = fechas_grupo))

    ggplot(d, aes(x = ts_10)) +
      # FLC (GOES-16)
      geom_tile(aes(y = y_goes, alpha = fog_sat), fill = "#525252",
                height = band_h, width = 600) +
      scale_alpha_continuous(range = c(0.15, 0.9), na.value = 0, guide = "none") +
      # Collector-based detection: one layer per category with a fixed colour (outside
      # aes), so that it does not interfere with the discrete scale of the reclassification
      lapply(names(col_captacion), function(k) {
        geom_tile(data = filter(d, captacion_fac == k), aes(y = y_inst),
                  fill = col_captacion[[k]], height = band_h, width = 600)
      }) +
      # Reclassification
      geom_tile(aes(y = y_cls, fill = clasif_fac),
                height = band_h, width = 600) +
      scale_fill_manual(
        values = col_clasif,
        name = "Reclassification",
        drop = FALSE
      ) +
      # Visibility
      geom_line(aes(y = vis_m, group = fecha), color = "#08306b",
                linewidth = 0.5, na.rm = TRUE) +
      geom_hline(yintercept = 1000, linetype = "22", color = "#8b1a1a", linewidth = 0.45) +
      geom_hline(yintercept = 0, color = "#c3c2b7", linewidth = 0.4) +
      scale_y_continuous(
        limits = c(-2400, 5000),
        breaks = c(-1900, -1200, -500, 0, 1000, 2000, 3000, 4000, 5000),
        labels = c("FLC", "Collectors", "Reclassif.", "0", "1000", "2000", "3000", "4000", "5000"),
        expand = expansion(mult = c(0.01, 0.03))
      ) +
      scale_x_datetime(date_breaks = "3 hours", date_labels = "%H:%M") +
      facet_wrap(~ fecha, ncol = ncol_grupo, scales = "free_x",
                 labeller = as_labeller(label_dias, default = label_parsed)) +
      labs(
        x = if (mostrar_x) "Time (UTC)" else NULL,
        y = "Visibility (m)",
        title = titulo_grupo
      ) +
      theme_classic(base_size = 10) +
      theme(
        legend.position = "bottom",
        axis.line        = element_line(color = "#c3c2b7"),
        axis.ticks       = element_line(color = "#c3c2b7"),
        panel.border     = element_rect(color = "#c3c2b7", fill = NA, linewidth = 0.4),
        panel.grid.major.y = element_line(color = "#ecebe6", linewidth = 0.3),
        strip.background = element_rect(fill = "#f9f9f7", color = NA),
        strip.text       = element_text(face = "bold"),
        axis.text.x      = element_text(angle = 90, vjust = 0.5, hjust = 1),
        axis.text.y      = element_text(color = "grey30"),
        plot.title       = element_text(face = "bold", size = 10),
        plot.margin      = margin(4, 6, 4, 6)
      )
  }

  # Shared legends (reclassification + collectors)
  p_legend_clasif <- ggplot(
    tibble(k = factor(names(col_clasif), levels = names(col_clasif)), x = 1, y = 1),
    aes(x, y, fill = k)
  ) +
    geom_tile() +
    scale_fill_manual(values = col_clasif,
                      name = "Reclassification", drop = FALSE) +
    guides(fill = guide_legend(title.position = "top", title.hjust = 0.5)) +
    theme(legend.position = "bottom")

  p_legend_captacion <- ggplot(
    tibble(k = factor(names(col_captacion), levels = names(col_captacion)), x = 1, y = 1),
    aes(x, y, fill = k)
  ) +
    geom_tile() +
    scale_fill_manual(values = col_captacion, name = "Collectors", drop = FALSE) +
    guides(fill = guide_legend(title.position = "top", title.hjust = 0.5)) +
    theme(legend.position = "bottom")

  fila_legends <- wrap_elements(cowplot::get_legend(p_legend_clasif)) |
    wrap_elements(cowplot::get_legend(p_legend_captacion))

  # Figure 3
  p_niebla <- plot_fila_dias(dsub, dias_niebla, ncol_grupo = 2, titulo_grupo = "Fog")
  p_rocio  <- plot_fila_dias(dsub, dias_rocio,  ncol_grupo = 2, titulo_grupo = "Dew", mostrar_x = TRUE)

  fig_dias_tipicos <- wrap_plots(
    p_niebla + theme(legend.position = "none"),
    p_rocio  + theme(legend.position = "none"),
    fila_legends,
    ncol = 1,
    heights = c(1, 1, 0.15)
  )

  save_fig(fig_dias_tipicos, paper_figure_files[["3"]], 10, 8, cfg)

  # Figure A1
  p_otros <- plot_fila_dias(dsub, dias_otros, ncol_grupo = 3,
                            titulo_grupo = "No AW and particular cases", mostrar_x = TRUE)

  fig_casos_particulares <- wrap_plots(
    p_otros + theme(legend.position = "none"),
    fila_legends,
    ncol = 1,
    heights = c(1, 0.22)
  )

  save_fig(fig_casos_particulares, paper_figure_files[["A1"]], 10, 5, cfg)
}


# ------------------------------------------------------------------------------
# Figure 4: seasonal (A, B) and diurnal (C, D) distribution of fog and dew and
# of the water collected, collector-based vs reclassified
# ------------------------------------------------------------------------------
fig04_distribution <- function(classification, cfg, dir_val) {

  oya <- classification %>%
    filter(!is.na(niebla_final), !is.na(rocio_final))

  months_en <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

  oya <- oya %>%
    mutate(
      water_total = niebla_final + rocio_final,
      collection  = water_total > 0,
      month       = factor(months_en[month(datetime)], levels = months_en),
      hour_num    = hour(datetime),
      # classified scheme: final classification
      type_final  = recode(clasif_evento, "NIEBLA" = "Fog", "ROCIO" = "Dew",
                           "SIN_EVENTO" = "No occurrence")
    )

  # mean of the summed water (per day-hour or per day) over the units with water only.
  # unit = "hour": sum per date x hour (L m-2 h-1); unit = "day": sum per date (L m-2 day-1)
  mean_by <- function(df, group, scheme_label, unit) {
    df %>%
      filter(value > 0) %>%
      mutate(date = as.Date(datetime)) %>%
      group_by({{ group }}, date, h = if (unit == "hour") hour(datetime) else 0L) %>%
      summarise(sum_L = sum(value) / 1000, .groups = "drop") %>%
      filter(sum_L > 0) %>%
      group_by({{ group }}) %>%
      summarise(mean = mean(sum_L), n_obs = n(), .groups = "drop") %>%
      mutate(scheme = scheme_label)
  }

  # Instrumental: water of the collector of each phenomenon whenever it registered water.
  # Classified: water of the collector of the classified phenomenon (SFC for fog, SDC for dew)
  water_by <- function(group, unit) {
    bind_rows(
      mean_by(oya %>% filter(niebla_final > 0) %>% transmute(datetime, {{ group }}, value = niebla_final),
              {{ group }}, "Instrumental", unit) %>% mutate(phenomenon = "Fog"),
      mean_by(oya %>% filter(type_final == "Fog") %>% transmute(datetime, {{ group }}, value = niebla_final),
              {{ group }}, "Classified", unit) %>% mutate(phenomenon = "Fog"),
      mean_by(oya %>% filter(rocio_final > 0) %>% transmute(datetime, {{ group }}, value = rocio_final),
              {{ group }}, "Instrumental", unit) %>% mutate(phenomenon = "Dew"),
      mean_by(oya %>% filter(type_final == "Dew") %>% transmute(datetime, {{ group }}, value = rocio_final),
              {{ group }}, "Classified", unit) %>% mutate(phenomenon = "Dew")
    ) %>%
      transmute({{ group }}, value = mean, n_obs, phenomenon, criterion = scheme)
  }

  # monthly panels: sum of the water of ALL the 10-min records of each month
  # (records with no AW occurrence add 0), L m-2 month-1
  water_sum_by <- function(group) {
    oya %>%
      group_by({{ group }}) %>%
      summarise(
        Fog_Instrumental = sum(niebla_final) / 1000,
        Fog_Classified   = sum(niebla_final[type_final == "Fog"]) / 1000,
        Dew_Instrumental = sum(rocio_final) / 1000,
        Dew_Classified   = sum(rocio_final[type_final == "Dew"]) / 1000,
        n_obs = n(),
        .groups = "drop"
      ) %>%
      pivot_longer(c(starts_with("Fog_"), starts_with("Dew_")),
                   names_to = c("phenomenon", "criterion"), names_sep = "_",
                   values_to = "value") %>%
      transmute({{ group }}, value, n_obs, phenomenon, criterion)
  }

  # monthly panels: frequency (%) over ALL the 10-min records of each month
  freq_total_by <- function(group) {
    oya %>%
      group_by({{ group }}) %>%
      summarise(
        total            = n(),
        Fog_Instrumental = sum(niebla_final > 0),
        Fog_Classified   = sum(type_final == "Fog"),
        Dew_Instrumental = sum(rocio_final > 0),
        Dew_Classified   = sum(type_final == "Dew"),
        .groups = "drop"
      ) %>%
      pivot_longer(c(starts_with("Fog_"), starts_with("Dew_")),
                   names_to = c("phenomenon", "criterion"), names_sep = "_",
                   values_to = "n") %>%
      mutate(value = n / total * 100)
  }

  # hourly panels: frequency (%) per group over the records with atmospheric water
  freq_by <- function(group) {
    base  <- oya %>% filter(collection)
    total <- base %>% count({{ group }}, name = "total")
    bind_rows(
      base %>% filter(niebla_final > 0) %>% count({{ group }}, name = "n") %>%
        mutate(phenomenon = "Fog", criterion = "Instrumental"),
      base %>% filter(rocio_final > 0) %>% count({{ group }}, name = "n") %>%
        mutate(phenomenon = "Dew", criterion = "Instrumental"),
      base %>% filter(type_final == "Fog") %>% count({{ group }}, name = "n") %>%
        mutate(phenomenon = "Fog", criterion = "Classified"),
      base %>% filter(type_final == "Dew") %>% count({{ group }}, name = "n") %>%
        mutate(phenomenon = "Dew", criterion = "Classified")
    ) %>%
      left_join(total, by = join_by({{ group }})) %>%
      mutate(value = n / total * 100)
  }

  levels_water <- c("Water, instrumental", "Water, classified (fog)", "Water, classified (dew)")
  levels_freq  <- c("Frequency, instrumental", "Frequency, classified (fog)", "Frequency, classified (dew)")

  add_key <- function(df, kind) {
    df %>% mutate(
      phenomenon = factor(phenomenon, levels = c("Fog", "Dew")),
      key = case_when(
        criterion == "Instrumental" ~ paste0(kind, ", instrumental"),
        phenomenon == "Fog"         ~ paste0(kind, ", classified (fog)"),
        TRUE                        ~ paste0(kind, ", classified (dew)")
      ),
      key = factor(key, levels = if (kind == "Water") levels_water else levels_freq)
    )
  }

  water_month <- water_sum_by(month)        %>% add_key("Water")
  water_hour  <- water_by(hour_num, "hour") %>% add_key("Water")
  freq_month  <- freq_total_by(month) %>% add_key("Frequency")
  freq_hour   <- freq_by(hour_num)  %>% add_key("Frequency")

  col_water <- c("Water, instrumental"     = "#bdbdbd",
                 "Water, classified (fog)" = "#4292c6",
                 "Water, classified (dew)" = "#c97a4a")
  col_freq  <- c("Frequency, instrumental"     = "#252525",
                 "Frequency, classified (fog)" = "#08306b",
                 "Frequency, classified (dew)" = "#7f2704")
  lt_freq   <- c("Frequency, instrumental"     = "22",
                 "Frequency, classified (fog)" = "solid",
                 "Frequency, classified (dew)" = "solid")
  sh_freq   <- c("Frequency, instrumental"     = 1,
                 "Frequency, classified (fog)" = 16,
                 "Frequency, classified (dew)" = 16)

  theme_comb <- theme_classic(base_size = 10) +
    theme(
      legend.title    = element_blank(),
      legend.position = "bottom",
      axis.line       = element_line(color = "#c3c2b7"),
      axis.ticks      = element_line(color = "#c3c2b7"),
      panel.grid.major.y = element_line(color = "#ecebe6", linewidth = 0.3),
      plot.title      = element_text(face = "bold", size = 10)
    )

  off <- cfg$paper$fig04_local_offset

  panel <- function(water, freq, x, phen, title, hourly = FALSE,
                    freq_max = 100, freq_step = 25) {
    a <- water %>% filter(phenomenon == phen)
    f <- freq  %>% filter(phenomenon == phen)
    k <- max(a$value, na.rm = TRUE) * 1.05 / freq_max   # freq_max (%) = top of the water axis

    p <- ggplot() +
      geom_col(data = a, aes(x = {{ x }}, y = value, fill = key),
               position = position_dodge(width = 0.8, preserve = "single"),
               width = 0.75, na.rm = TRUE) +
      geom_line(data = f, aes(x = {{ x }}, y = value * k, color = key,
                              linetype = key, group = key),
                linewidth = 0.5, na.rm = TRUE) +
      geom_point(data = f, aes(x = {{ x }}, y = value * k, color = key, shape = key),
                 size = 1.5, stroke = 0.6, na.rm = TRUE) +
      scale_fill_manual(values = col_water, drop = FALSE) +
      scale_color_manual(values = col_freq, drop = FALSE) +
      scale_linetype_manual(values = lt_freq, drop = FALSE) +
      scale_shape_manual(values = sh_freq, drop = FALSE) +
      scale_y_continuous(
        name = if (hourly) expression(Mean~hourly~water~(L~m^{-2}~h^{-1}))
               else expression(Monthly~water~(L~m^{-2}~month^{-1})),
        limits = c(0, freq_max * k),
        expand = expansion(mult = c(0, 0.02)),
        sec.axis = sec_axis(transform = ~ . / k,
                            name = "Frequency",
                            breaks = seq(0, freq_max, freq_step))
      ) +
      labs(title = title, x = if (hourly) "Hour of day (UTC)" else NULL) +
      theme_comb +
      theme(legend.box = "vertical", legend.spacing.y = unit(0, "pt"))

    # months always in calendar order (also when a month has no data in a series)
    if (!hourly) p <- p + scale_x_discrete(limits = months_en)

    if (hourly) {
      p <- p + scale_x_continuous(
        breaks = 0:23, labels = sprintf("%02d", 0:23),
        expand = expansion(add = 0.6),
        sec.axis = sec_axis(transform = ~ ., breaks = 0:23,
                            labels = sprintf("%02d", (0:23 + off) %% 24),
                            name = cfg$paper$fig04_local_label)
      ) +
        theme(axis.text.x = element_text(size = 6.5),
              axis.text.x.top = element_text(size = 6.5))
    }
    p
  }

  # common frequency axis for A and B, rounded up to the next 5%
  freq_max_month <- ceiling(max(freq_month$value, na.rm = TRUE) / 5) * 5

  pA <- panel(water_month, freq_month, month,    "Fog", "(A) Fog, monthly",
              freq_max = freq_max_month, freq_step = 5)
  pB <- panel(water_month, freq_month, month,    "Dew", "(B) Dew, monthly",
              freq_max = freq_max_month, freq_step = 5)
  pC <- panel(water_hour,  freq_hour,  hour_num, "Fog", "(C) Fog, hourly", hourly = TRUE)
  pD <- panel(water_hour,  freq_hour,  hour_num, "Dew", "(D) Dew, hourly", hourly = TRUE)

  fig_distribution <- (pA | pB) / (pC | pD) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

  save_fig(fig_distribution, paper_figure_files[["4"]], 11, 8, cfg)

  # values used in the text of Section 3.1
  long <- function(d, g, what) {
    d %>% transmute(group = as.character({{ g }}), quantity = what,
                    phenomenon = as.character(phenomenon), criterion, value,
                    n = if ("n_obs" %in% names(d)) n_obs else n)
  }
  bind_rows(
    long(freq_month,  month,    "frequency_pct_of_all_records"),
    long(freq_hour,   hour_num, "frequency_pct_of_aw_records"),
    long(water_month, month,    "water_L_m2_month"),
    long(water_hour,  hour_num, "mean_water_L_m2_h_on_hours_with_water")
  ) %>%
    write_csv(file.path(dir_val, "fig04_distribution.csv"))

  oya %>%
    filter(type_final %in% c("Fog", "Dew")) %>%
    mutate(water_class = if_else(type_final == "Fog", niebla_final, rocio_final)) %>%
    group_by(type_final) %>%
    summarise(n = n(), n_pos = sum(water_class > 0), mean_pos = mean(water_class[water_class > 0]),
              total = sum(water_class), .groups = "drop") %>%
    mutate(share_total = total / sum(total)) %>%
    write_csv(file.path(dir_val, "fig04_water_by_classified_type.csv"))
}


# ------------------------------------------------------------------------------
# Figures 5 and 6 (Section 3.2): vertical profiles on typical days and mean
# vertical gradients relative to the coastal reference station
# ------------------------------------------------------------------------------
fig05_06_stability <- function(thermo, cfg, dir_val) {

  ref    <- cfg$reference_station
  z_ref  <- z_of(thermo, ref)
  z_main <- z_of(thermo, cfg$main_station)
  main_lab <- paste0(z_main, " m")

  dat <- thermo

  # Gradients relative to the coastal reference, every 10 min
  grad <- dat %>%
    group_by(datetime) %>%
    mutate(
      theta_ref = theta_K[estacion == ref][1],
      q_ref     = q_gkg[estacion == ref][1],
      u_ref     = viento_vel_m_s[estacion == ref][1]
    ) %>%
    ungroup() %>%
    mutate(
      grad_theta = (theta_K - theta_ref) / (z_m - z_ref),
      grad_q     = (q_gkg - q_ref) / (z_m - z_ref),
      grad_u     = (viento_vel_m_s - u_ref) / (z_m - z_ref)
    ) %>%
    filter(z_m != z_ref, !estacion %in% cfg$excluded_stations,
           clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"))

  resumen <- grad %>%
    pivot_longer(c(grad_q, grad_theta, grad_u), names_to = "variable", values_to = "valor") %>%
    group_by(variable, clasif_evento, z_m) %>%
    summarise(media = mean(valor, na.rm = TRUE), sd = sd(valor, na.rm = TRUE),
              mediana = median(valor, na.rm = TRUE), n = sum(!is.na(valor)), .groups = "drop") %>%
    # reference point: gradient 0 by definition (no standard deviation)
    bind_rows(expand_grid(variable = c("grad_q", "grad_theta", "grad_u"),
                          clasif_evento = c("NIEBLA", "ROCIO", "SIN_EVENTO"),
                          z_m = z_ref, media = 0, sd = NA_real_, mediana = 0, n = NA_integer_)) %>%
    mutate(
      regimen = factor(recode(clasif_evento, "NIEBLA" = "Fog", "ROCIO" = "Dew",
                              "SIN_EVENTO" = "No AW"),
                       levels = c("Fog", "Dew", "No AW")),
      estacion_lab = factor(paste0(z_m, " m"), levels = paste0(sort(unique(z_m)), " m")),
      y = as.numeric(estacion_lab) + case_when(regimen == "Fog" ~ 0.2,
                                               regimen == "Dew" ~ 0,
                                               TRUE ~ -0.2)
    ) %>%
    arrange(variable, regimen, z_m)   # order by altitude so that geom_path joins the points correctly

  # ---- Figure 6 ----
  col_reg <- c("Fog" = "#4292c6", "Dew" = "#c97a4a", "No AW" = "#7f7f7f")
  niveles_y <- levels(resumen$estacion_lab)
  y_1211 <- which(niveles_y == main_lab)

  tema_grad <- theme_classic(base_size = 10) +
    theme(
      legend.title    = element_blank(),
      legend.position = "bottom",
      axis.line       = element_line(color = "#c3c2b7"),
      axis.ticks      = element_line(color = "#c3c2b7"),
      panel.grid.major.x = element_line(color = "#ecebe6", linewidth = 0.3),
      plot.title      = element_text(face = "bold", size = 10)
    )

  # means of this study at the main station (units of 10^-3), computed from the data
  media_1211 <- function(var, regs) {
    1000 * mean(grad[[var]][grad$z_m == z_main & grad$clasif_evento %in% regs], na.rm = TRUE)
  }
  m_fog <- media_1211("grad_theta", "NIEBLA")
  m_dew <- media_1211("grad_theta", "ROCIO")

  lr_th <- cfg$paper$lobos_roco_grad_theta
  lr_q  <- cfg$paper$lobos_roco_grad_q
  umbrales <- tribble(
    ~variable,    ~x,    ~color,    ~etiqueta,                ~nivel,
    "grad_theta", m_fog, "#4292c6", sprintf("%.2f", m_fog),   1,
    "grad_theta", lr_th, "#8b1a1a", format(lr_th),            2,
    "grad_theta", m_dew, "#c97a4a", sprintf("%.2f", m_dew),   3,
    "grad_q",     lr_q,  "#8b1a1a", format(lr_q),             1
  )
  # Lobos Roco et al. (2018): dark red; this study: blue (fog), orange (dew)

  panel_grad <- function(var, titulo, xlab, xlim = NULL) {
    d <- resumen %>% filter(variable == var)
    u <- umbrales %>% filter(variable == var)
    p <- ggplot(d, aes(y = y, color = regimen)) +
      annotate("rect", xmin = -Inf, xmax = Inf, ymin = y_1211 - 0.45, ymax = y_1211 + 0.45,
               fill = "#f3f1ea", color = NA) +
      geom_vline(xintercept = 0, color = "#c3c2b7", linewidth = 0.4)
    if (nrow(u) > 0) {
      p <- p +
        geom_vline(data = u, aes(xintercept = x), color = u$color,
                   linetype = "22", linewidth = 0.45, inherit.aes = FALSE)
    }
    p <- p +
      geom_segment(aes(x = (media - sd) * 1000, xend = (media + sd) * 1000, yend = y),
                   linewidth = 1.1, alpha = 0.2, lineend = "round") +
      geom_path(aes(x = media * 1000, group = regimen), linewidth = 0.7) +
      geom_point(aes(x = media * 1000), size = 2) +
      scale_color_manual(values = col_reg) +
      scale_y_continuous(breaks = seq_along(niveles_y), labels = niveles_y,
                         expand = expansion(add = c(0.5, 0.5))) +
      coord_cartesian(xlim = xlim, ylim = c(0.6, length(niveles_y) + 1.75), clip = "off") +
      labs(title = titulo, x = xlab, y = NULL) +
      tema_grad
    if (nrow(u) > 0) {
      p <- p + geom_label(data = u, aes(x = x, y = length(niveles_y) + 0.35 + 0.42 * nivel, label = etiqueta),
                          color = u$color, fill = "white", label.size = 0, label.padding = unit(0.08, "lines"),
                          size = 2.6, fontface = "bold", inherit.aes = FALSE)
    }
    p
  }

  pq  <- panel_grad("grad_q",     "(B) Specific humidity",  expression(partialdiff*q/partialdiff*z~(10^{-3}~g~kg^{-1}~m^{-1})))
  # ∂θ/∂z: X axis limited to widen the separation between fog and dew; the
  # standard deviations of no AW occurrence (up to ~14 x 10^-3) are cut,
  # but all the means remain visible.
  pth <- panel_grad("grad_theta", "(A) Potential temperature", expression(partialdiff*theta/partialdiff*z~(10^{-3}~K~m^{-1})),
                    xlim = c(-0.2, 9.95)) +
    scale_x_continuous(breaks = seq(0, 8, 2), expand = expansion(add = 0)) +
    labs(y = "Station altitude (m a.s.l.)")
  pu  <- panel_grad("grad_u",     "(C) Wind speed",         expression(partialdiff*U/partialdiff*z~(10^{-3}~s^{-1})))

  # the three panels with the same width
  fig_gradientes <- (pth | pq | pu) +
    plot_layout(guides = "collect", widths = c(1, 1, 1)) &
    theme(legend.position = "bottom")

  save_fig(fig_gradientes, paper_figure_files[["6"]], 12, 5.4, cfg)

  # values used in the text of Section 3.2 and Table 2
  resumen %>% select(variable, regimen, z_m, media, sd, mediana, n) %>%
    arrange(variable, regimen, z_m) %>%
    rename(regime = regimen, mean = media, median = mediana) %>%
    write_csv(file.path(dir_val, "fig06_vertical_gradients.csv"))

  grad %>%
    filter(z_m == z_main) %>%
    pivot_longer(c(grad_theta, grad_q), names_to = "variable", values_to = "valor") %>%
    group_by(variable, clasif_evento) %>%
    summarise(n = sum(!is.na(valor)),
              media = 1000 * mean(valor, na.rm = TRUE),
              sd    = 1000 * sd(valor, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(bajo = media - sd, alto = media + sd) %>%
    arrange(variable, clasif_evento) %>%
    rename(mean_1e3 = media, sd_1e3 = sd, mean_minus_sd_1e3 = bajo, mean_plus_sd_1e3 = alto) %>%
    write_csv(file.path(dir_val, "table2_mean_sd_main_station.csv"))

  # ---- Figure 5 ----
  # Hour selection (hourly records, minute 00): for fog and dew, the hour with the
  # most contrasting θ between both regimes (the fog hour with the smallest increase
  # of θ between the reference and the main station and the dew hour with the
  # largest increase); for no AW occurrence, the full hour without water collection
  # at the main station with the largest increase of θ.
  dias_sel <- cfg$paper$profile_days %>% transmute(fecha = ymd(date), etiqueta = label)

  dat_horas <- dat %>%
    filter(minute(datetime) == 0, !estacion %in% cfg$excluded_stations) %>%
    mutate(fecha = as.Date(datetime), hora = hour(datetime))

  # Hours with no AW occurrence: first and last of the day at the main station
  horas_sin <- dat_horas %>%
    filter(fecha %in% dias_sel$fecha, estacion == cfg$main_station, clasif_evento == "SIN_EVENTO") %>%
    group_by(fecha, clasif_evento) %>%
    summarise(primera = min(hora), ultima = max(hora), .groups = "drop") %>%
    pivot_longer(c(primera, ultima), names_to = "momento", values_to = "hora")

  dtheta_hora <- dat_horas %>%
    filter(fecha %in% dias_sel$fecha) %>%
    group_by(fecha, hora) %>%
    summarise(dtheta = theta_K[z_m == z_main][1] - theta_K[z_m == z_ref][1], .groups = "drop") %>%
    left_join(dat_horas %>% filter(estacion == cfg$main_station) %>% select(fecha, hora, clasif_evento),
              by = c("fecha", "hora"))

  horas_occ <- bind_rows(
    dtheta_hora %>% filter(clasif_evento == "NIEBLA") %>% slice_min(dtheta, n = 1, with_ties = FALSE),
    dtheta_hora %>% filter(clasif_evento == "ROCIO")  %>% slice_max(dtheta, n = 1, with_ties = FALSE)
  ) %>%
    transmute(fecha, clasif_evento, momento = "ocurrencia", hora)

  horas_sel <- bind_rows(horas_occ, horas_sin)

  horas_sin_completas <- dat %>%
    filter(estacion == cfg$main_station, as.Date(datetime) %in% dias_sel$fecha) %>%
    mutate(fecha = as.Date(datetime), hora = hour(datetime)) %>%
    group_by(fecha, hora) %>%
    summarise(sin_captacion = all(clasif_evento == "SIN_EVENTO"), .groups = "drop") %>%
    filter(sin_captacion)

  horas_sin_contraste <- dtheta_hora %>%
    filter(clasif_evento == "SIN_EVENTO") %>%
    semi_join(horas_sin_completas, by = c("fecha", "hora")) %>%
    group_by(fecha) %>%
    slice_max(dtheta, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(fecha, clasif_evento, momento = "contraste", hora)

  horas_fig <- bind_rows(horas_occ, horas_sin_contraste)

  perf <- dat_horas %>%
    inner_join(horas_fig, by = c("fecha", "hora", "clasif_evento")) %>%
    inner_join(dias_sel, by = "fecha") %>%
    mutate(
      etiqueta = factor(etiqueta, levels = dias_sel$etiqueta),
      serie_leg = case_when(
        clasif_evento == "NIEBLA" ~ "Fog",
        clasif_evento == "ROCIO"  ~ "Dew",
        momento == "contraste"    ~ "No AW",
        TRUE                      ~ "No AW, last hour"
      ),
      serie_leg = factor(serie_leg, levels = c("Fog", "Dew", "No AW",
                                               "No AW, last hour")),
      serie    = paste(serie_leg, hora),
      estacion_lab = factor(paste0(z_m, " m"), levels = paste0(sort(unique(z_m)), " m")),
      y = as.numeric(estacion_lab)
    ) %>%
    select(etiqueta, serie_leg, hora, serie, z_m, estacion_lab, y,
           theta_K, q_gkg, viento_vel_m_s) %>%
    pivot_longer(c(theta_K, q_gkg, viento_vel_m_s), names_to = "variable", values_to = "valor") %>%
    mutate(variable = factor(variable, levels = c("theta_K", "q_gkg", "viento_vel_m_s"),
                             labels = c("theta~(K)",
                                        "q~(g~kg^{-1})",
                                        "U~(m~s^{-1})"))) %>%
    arrange(etiqueta, serie, variable, z_m)

  niveles_y_d <- levels(perf$estacion_lab)
  y_1211_d <- which(niveles_y_d == main_lab)

  fig_perfiles_dias <- ggplot(perf, aes(x = valor, y = y, color = serie_leg,
                                        linetype = serie_leg, shape = serie_leg, group = serie)) +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = y_1211_d - 0.45, ymax = y_1211_d + 0.45,
             fill = "#f3f1ea", color = NA) +
    geom_path(linewidth = 0.6, na.rm = TRUE) +
    geom_point(size = 1.8, na.rm = TRUE) +
    facet_grid(etiqueta ~ variable, scales = "free_x",
               labeller = labeller(variable = label_parsed, etiqueta = label_parsed)) +
    scale_color_manual(values = c("Fog" = "#4292c6", "Dew" = "#c97a4a",
                                  "No AW" = "#7f7f7f",
                                  "No AW, last hour" = "#7f7f7f"), drop = TRUE) +
    scale_linetype_manual(values = c("Fog" = "solid", "Dew" = "solid",
                                     "No AW" = "solid",
                                     "No AW, last hour" = "22"), drop = TRUE) +
    scale_shape_manual(values = c("Fog" = 16, "Dew" = 16,
                                  "No AW" = 16,
                                  "No AW, last hour" = 1), drop = TRUE) +
    scale_y_continuous(breaks = seq_along(niveles_y_d), labels = niveles_y_d,
                       expand = expansion(add = 0.5)) +
    labs(x = NULL, y = "Station altitude (m a.s.l.)") +
    theme_classic(base_size = 10) +
    theme(
      legend.title     = element_blank(),
      legend.position  = "bottom",
      axis.line        = element_line(color = "#c3c2b7"),
      axis.ticks       = element_line(color = "#c3c2b7"),
      panel.grid.major.x = element_line(color = "#ecebe6", linewidth = 0.3),
      panel.border     = element_rect(color = "#c3c2b7", fill = NA, linewidth = 0.4),
      strip.background = element_rect(fill = "#f9f9f7", color = NA),
      strip.text       = element_text(face = "bold"),
      strip.text.y     = element_text(angle = -90),
      panel.spacing.x  = unit(1.2, "lines")
    )

  save_fig(fig_perfiles_dias, paper_figure_files[["5"]], 10, 6.5, cfg)

  # profile values of the plotted hours (for the text and the caption)
  dat_horas %>%
    inner_join(horas_fig, by = c("fecha", "hora", "clasif_evento")) %>%
    select(fecha, clasif_evento, momento, hora, estacion, z_m, theta_K, q_gkg, viento_vel_m_s) %>%
    arrange(fecha, clasif_evento, hora, z_m) %>%
    write_csv(file.path(dir_val, "fig05_profiles_plotted_hours.csv"))
}


# ------------------------------------------------------------------------------
# Figure 7 (Section 3.3): diurnal cycle of q, θ and U at the main station on a
# fog night and a dew night, with the hourly frequency of the occurrence
# ------------------------------------------------------------------------------
fig07_diurnal_cycle <- function(thermo, cfg, dir_val) {

  dias <- cfg$paper$diurnal_days %>% mutate(fecha = as.Date(date)) %>%
    select(fecha, fen, dia_lab, dia_expr)
  rmax <- cfg$night_radiation_max

  d1211 <- thermo %>%
    filter(estacion == cfg$main_station) %>%
    distinct(datetime, .keep_all = TRUE) %>%
    mutate(fecha = as.Date(datetime),
           hora  = hour(datetime) + minute(datetime) / 60) %>%
    filter(fecha %in% dias$fecha) %>%
    select(datetime, fecha, hora, clasif_evento, rad = radiacion_w_m2,
           q = q_gkg, theta = theta_K, U = viento_vel_m_s)

  # hourly frequency (%) of the occurrence of the day, according to the reclassification
  freq <- d1211 %>%
    left_join(dias, by = "fecha") %>%
    mutate(h = floor(hora),
           ocurre = clasif_evento == if_else(fen == "Fog", "NIEBLA", "ROCIO")) %>%
    group_by(fecha, fen, h) %>%
    summarise(frec = 100 * sum(ocurre, na.rm = TRUE) / n(), .groups = "drop") %>%
    mutate(x = h + 0.5)

  col_linea <- c("Fog" = "#08306b", "Dew" = "#7f2704")
  etiq_frec <- c("Fog" = "Fog frequency", "Dew" = "Dew frequency")

  tema <- theme_classic(base_size = 10) +
    theme(
      legend.title    = element_blank(),
      legend.position = "bottom",
      axis.line       = element_line(color = "#c3c2b7"),
      axis.ticks      = element_line(color = "#c3c2b7"),
      axis.title.y.right = element_text(color = "grey35"),
      axis.text.y.right  = element_text(color = "grey35"),
      panel.grid.major.y = element_line(color = "#ecebe6", linewidth = 0.3),
      strip.background = element_rect(fill = "#f3f1ea", color = NA),
      strip.text      = element_text(face = "bold", size = 10),
      strip.placement = "outside",
      # the panel letter goes on the upper left corner, without adding space
      # between the variable strip and the local time axis
      plot.tag        = element_text(face = "bold", size = 10, hjust = 0, vjust = 1),
      plot.tag.position = c(0, 1)
    )

  titulos <- c(q = "Specific humidity", theta = "Potential temperature", U = "Wind speed")
  ylab    <- list(q = expression(q~(g~kg^{-1})), theta = expression(theta~(K)),
                  U = expression(U~(m~s^{-1})))
  off <- cfg$paper$fig07_local_offset

  panel_dia <- function(v, f, letra) {
    dd <- dias %>% filter(fen == f)
    dv <- d1211 %>% filter(fecha == dd$fecha) %>%
      mutate(var_lab = titulos[[v]], dia_lab = dd$dia_lab, key = "Variable")
    df <- freq %>% filter(fecha == dd$fecha) %>%
      mutate(var_lab = titulos[[v]], dia_lab = dd$dia_lab, key = etiq_frec[[f]])

    # scale: 0-100 % frequency spans the range of the variable (with margin)
    r  <- range(dv[[v]], na.rm = TRUE)
    lo <- r[1] - 0.06 * diff(r); hi <- r[2] + 0.06 * diff(r)
    a  <- (hi - lo) / 100
    df <- df %>% mutate(y = lo + frec * a)

    # night: records with global radiation <= threshold (each one covers 10 min)
    # (consecutive records are merged into intervals so that the shading is continuous)
    dn <- dv %>% arrange(hora) %>% mutate(noche = !is.na(rad) & rad <= rmax,
                                          tramo = cumsum(noche != lag(noche, default = FALSE))) %>%
      filter(noche) %>% group_by(tramo) %>%
      summarise(x0 = min(hora), x1 = max(hora) + 1/6, .groups = "drop") %>%
      mutate(fill_key = "Night")

    p <- ggplot() +
      geom_rect(data = dn, aes(xmin = x0, xmax = x1, ymin = -Inf, ymax = Inf, fill = fill_key),
                color = NA) +
      scale_fill_manual(values = c("Night" = "grey93"), name = NULL) +
      geom_line(data = df, aes(x, y, color = key), linewidth = 0.35, alpha = 0.45) +
      geom_point(data = df %>% filter(frec > 0), aes(x, y, color = key), size = 0.9, alpha = 0.45) +
      geom_line(data = dv, aes(hora, .data[[v]], color = key), linewidth = 0.35, na.rm = TRUE) +
      scale_color_manual(values = c("Variable" = "black",
                                    "Fog frequency" = col_linea[["Fog"]],
                                    "Dew frequency" = col_linea[["Dew"]]),
                         limits = c("Variable", "Fog frequency",
                                    "Dew frequency"),
                         drop = FALSE) +
      scale_y_continuous(
        name = ylab[[v]],
        sec.axis = sec_axis(transform = ~ (. - lo) / a,
                            name = "Frequency (%)",
                            breaks = seq(0, 100, 25))
      ) +
      scale_x_continuous(
        breaks = seq(0, 24, 3), labels = sprintf("%02d", seq(0, 24, 3)),
        expand = expansion(add = 0.3),
        sec.axis = sec_axis(transform = ~ ., breaks = seq(0, 24, 3),
                            labels = sprintf("%02d", (seq(0, 24, 3) + off) %% 24),
                            name = cfg$paper$fig07_local_label)
      ) +
      coord_cartesian(xlim = c(0, 24), ylim = c(lo, hi)) +
      labs(x = "Hour of day (UTC)",
           tag = paste0("(", letra, ")")) +
      guides(color = guide_legend(override.aes = list(shape = c(NA, 16, 16)))) +
      tema
    p
  }

  # strip with the day and occurrence type as a separate column, so that the title of the
  # right axis (Frequency, %) lies between the numbers and the strip, as in facet_grid
  strip_dia <- function(f) {
    ggplot() +
      annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = "#f3f1ea") +
      annotate("text", x = 0.5, y = 0.5, label = dias$dia_expr[dias$fen == f], parse = TRUE,
               angle = -90, size = 10 / .pt) +
      scale_x_continuous(limits = c(0, 1), expand = expansion(0)) +
      scale_y_continuous(limits = c(0, 1), expand = expansion(0)) +
      theme_void() +
      theme(plot.margin = margin(0, 0, 0, 0))
  }

  # variable strip as a separate row, above the local time axis
  strip_var <- function(v) {
    ggplot() +
      annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = "#f3f1ea") +
      annotate("text", x = 0.5, y = 0.5, label = titulos[[v]],
               fontface = "bold", size = 10 / .pt) +
      scale_x_continuous(limits = c(0, 1), expand = expansion(0)) +
      scale_y_continuous(limits = c(0, 1), expand = expansion(0)) +
      theme_void() +
      theme(plot.margin = margin(0, 0, 0, 0))
  }

  fig_ciclo <- wrap_plots(
    strip_var("q"), strip_var("theta"), strip_var("U"), plot_spacer(),
    panel_dia("q", "Fog", "A"), panel_dia("theta", "Fog", "B"), panel_dia("U", "Fog", "C"), strip_dia("Fog"),
    panel_dia("q", "Dew", "D"), panel_dia("theta", "Dew", "E"), panel_dia("U", "Dew", "F"), strip_dia("Dew"),
    ncol = 4, widths = c(1, 1, 1, 0.075), heights = c(0.085, 1, 1)) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

  save_fig(fig_ciclo, paper_figure_files[["7"]], 11, 6.8, cfg)

  # values: hourly frequency of the occurrence of the day and daily range of q, θ and U
  freq %>% filter(frec > 0) %>%
    write_csv(file.path(dir_val, "fig07_hourly_frequency.csv"))
  d1211 %>% group_by(fecha) %>%
    summarise(across(c(q, theta, U), list(min = ~ min(.x, na.rm = TRUE), max = ~ max(.x, na.rm = TRUE)))) %>%
    write_csv(file.path(dir_val, "fig07_daily_range.csv"))

  # nocturnal fog and dew episodes of the year and slope of q during each one
  # (used to choose the days of the figure)
  todo <- thermo %>%
    filter(estacion == cfg$main_station) %>%
    distinct(datetime, .keep_all = TRUE) %>%
    select(datetime, clasif_evento, q = q_gkg, rad = radiacion_w_m2) %>%
    arrange(datetime)
  excl <- as.POSIXct(cfg$paper$fig07_exclude_episodes, tz = "UTC")

  todo %>%
    filter(clasif_evento %in% c("NIEBLA", "ROCIO")) %>%
    group_by(clasif_evento) %>% arrange(datetime) %>%
    mutate(id = cumsum(c(TRUE, diff(as.numeric(datetime)) / 60 > 30))) %>%
    group_by(clasif_evento, id) %>%
    summarise(ini = min(datetime), fin = max(datetime), n = n(),
              frac_noche = mean(rad <= rmax, na.rm = TRUE), .groups = "drop") %>%
    filter(n >= 12, frac_noche >= 0.9,
           !(length(excl) == 2 & ini >= excl[1] & ini < excl[2])) %>%
    rowwise() %>%
    mutate(w = list(todo %>% filter(datetime >= ini, datetime <= fin, !is.na(q)) %>%
                      mutate(t_h = as.numeric(difftime(datetime, ini, units = "hours")))),
           pendiente = coef(lm(q ~ t_h, data = w))[2],
           r2 = summary(lm(q ~ t_h, data = w))$r.squared,
           dq = mean(tail(w$q, 3)) - mean(head(w$q, 3))) %>%
    select(-w) %>% ungroup() %>%
    arrange(clasif_evento, desc(pendiente)) %>%
    rename(start = ini, end = fin, night_fraction = frac_noche, slope_q_g_kg_h = pendiente) %>%
    write_csv(file.path(dir_val, "fig07_nocturnal_episodes.csv"))
}


# ------------------------------------------------------------------------------
# Accumulated change ∂φ(τ) = φ(t + τ) − φ(t), τ = 0 to 120 min, after every
# record of the main station, by occurrence type and light condition (night:
# global radiation at the main station <= threshold at t). Mean and 95% CI.
# Used by Figures 8 and 9 and by the report of temporal tendencies.
#   stations: stations whose variables are followed (the classification and
#             the light condition are always those of the main station)
# ------------------------------------------------------------------------------
accumulated_change <- function(thermo, cfg, stations = cfg$main_station,
                               vars = c(q = "q_gkg", theta = "theta_K", U = "viento_vel_m_s"),
                               max_lag = 12) {
  main <- thermo %>%
    filter(estacion == cfg$main_station) %>%
    distinct(datetime, .keep_all = TRUE) %>%
    select(datetime, clasif_evento, radiacion_w_m2)

  map_dfr(stations, function(st) {
    s <- thermo %>%
      filter(estacion == st) %>%
      distinct(datetime, .keep_all = TRUE) %>%
      select(datetime, all_of(unname(vars)))
    names(s) <- c("datetime", names(vars))

    serie <- main %>%
      left_join(s, by = "datetime") %>%
      complete(datetime = seq(min(datetime), max(datetime), by = "10 min")) %>%
      arrange(datetime) %>%
      mutate(luz = factor(case_when(radiacion_w_m2 <= cfg$night_radiation_max ~ "Night",
                                    radiacion_w_m2 >  cfg$night_radiation_max ~ "Day"),
                          levels = c("Night", "Day")))

    map_dfr(0:max_lag, function(i) {
      serie %>%
        transmute(clasif_evento, luz, lag_min = i * 10,
                  across(all_of(names(vars)), ~ lead(.x, i) - .x))
    }) %>%
      filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"), luz %in% c("Night", "Day")) %>%
      pivot_longer(all_of(names(vars)), names_to = "variable", values_to = "tasa") %>%
      group_by(variable, luz, clasif_evento, lag_min) %>%
      summarise(media = mean(tasa, na.rm = TRUE),
                se    = sd(tasa, na.rm = TRUE) / sqrt(sum(!is.na(tasa))),
                n     = sum(!is.na(tasa)), .groups = "drop") %>%
      mutate(estacion = st)
  }) %>%
    mutate(regimen = as_regime(clasif_evento),
           lo = media - 1.96 * se, hi = media + 1.96 * se) %>%
    arrange(estacion, variable, luz, regimen, lag_min)
}


# ------------------------------------------------------------------------------
# Figure 8: accumulated change of q, θ and U at the main station after each
# fog, dew and no AW record, at night and during the day
# ------------------------------------------------------------------------------
fig08_tendencies_day_night <- function(thermo, cfg, dir_val) {

  d1211 <- thermo %>%
    filter(estacion == cfg$main_station) %>%
    distinct(datetime, .keep_all = TRUE) %>%
    select(datetime, clasif_evento, q_gkg, theta_K, viento_vel_m_s, radiacion_w_m2) %>%
    arrange(datetime)

  serie <- d1211 %>%
    complete(datetime = seq(min(datetime), max(datetime), by = "10 min")) %>%
    arrange(datetime) %>%
    # light condition according to the radiation at t1 (time of the record)
    mutate(luz = factor(case_when(radiacion_w_m2 <= cfg$night_radiation_max ~ "Night",
                                  radiacion_w_m2 > cfg$night_radiation_max  ~ "Day"), levels = c("Night", "Day")))

  col_reg <- c("Fog" = "#4292c6", "Dew" = "#c97a4a", "No AW" = "#7f7f7f")
  regimen <- function(x) {
    factor(recode(x, "NIEBLA" = "Fog", "ROCIO" = "Dew", "SIN_EVENTO" = "No AW"),
           levels = c("Fog", "Dew", "No AW"))
  }
  vars <- c("q", "theta", "U")

  # accumulated change ∂φ(τ) = φ(t + τ) − φ(t), τ = 0 to 120 min
  tend <- map_dfr(0:12, function(i) {
    serie %>%
      transmute(clasif_evento, luz, lag_min = i * 10,
                q     = lead(q_gkg, i) - q_gkg,
                theta = lead(theta_K, i) - theta_K,
                U     = lead(viento_vel_m_s, i) - viento_vel_m_s)
  }) %>%
    filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"), luz %in% c("Night", "Day")) %>%
    pivot_longer(all_of(vars), names_to = "variable", values_to = "tasa") %>%
    group_by(variable, luz, clasif_evento, lag_min) %>%
    summarise(media = mean(tasa, na.rm = TRUE),
              se    = sd(tasa, na.rm = TRUE) / sqrt(sum(!is.na(tasa))),
              n     = sum(!is.na(tasa)), .groups = "drop") %>%
    mutate(regimen = regimen(clasif_evento),
           lo = media - 1.96 * se, hi = media + 1.96 * se) %>%
    arrange(variable, luz, regimen, lag_min)

  tema <- theme_classic(base_size = 10) +
    theme(
      legend.title    = element_blank(),
      legend.position = "bottom",
      axis.line       = element_line(color = "#c3c2b7"),
      axis.ticks      = element_line(color = "#c3c2b7"),
      panel.grid.major.y = element_line(color = "#ecebe6", linewidth = 0.3),
      plot.title      = element_text(face = "bold", size = 10)
    )

  # accumulated change (no time unit)
  ylab_tasa <- list(q     = expression(partialdiff*q~(g~kg^{-1})),
                    theta = expression(partialdiff*theta~(K)),
                    U     = expression(partialdiff*U~(m~s^{-1})))
  titulos <- c(q = "Specific humidity", theta = "Potential temperature", U = "Wind speed")

  # Y axis limits: symmetric for q and θ (0 at the centre); U fitted to its data
  lims <- tend %>% group_by(luz, variable) %>%
    summarise(lo = min(lo), hi = max(hi), .groups = "drop") %>%
    mutate(m   = pmax(abs(lo), abs(hi)) * 1.08,
           r   = hi - lo,
           lo2 = if_else(variable %in% c("q", "theta"), -m, lo - 0.06 * r),
           hi2 = if_else(variable %in% c("q", "theta"),  m, hi + 0.06 * r))

  panel_tend <- function(v, l, letra) {
    d  <- tend %>% filter(variable == v, luz == l)
    li <- lims %>% filter(variable == v, luz == l)
    ggplot(d, aes(lag_min, media, color = regimen, fill = regimen)) +
      geom_hline(yintercept = 0, color = "#c3c2b7", linewidth = 0.4) +
      geom_vline(xintercept = 60, color = "#c3c2b7", linetype = "22", linewidth = 0.4) +
      geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, color = NA) +
      geom_line(linewidth = 0.8) +
      geom_point(data = d %>% filter(lag_min %in% c(60, 120)), size = 1.6) +
      scale_color_manual(values = col_reg) + scale_fill_manual(values = col_reg) +
      scale_x_continuous(breaks = seq(0, 120, 30), limits = c(0, 120),
                         expand = expansion(add = c(2, 6))) +
      scale_y_continuous(limits = c(li$lo2, li$hi2), expand = expansion(0)) +
      labs(tag = paste0("(", letra, ")"),
           x = if (l == "Day") "Min after occurrence" else NULL,
           y = ylab_tasa[[v]]) +
      tema +
      theme(panel.border = element_rect(color = "#c3c2b7", fill = NA, linewidth = 0.4),
            plot.tag = element_text(face = "bold", size = 10, hjust = 0, vjust = 1),
            plot.tag.position = c(0, 1))
  }

  # strips as separate rows/columns (facet_grid style, but more marked)
  strip_box <- function(txt, fill, col, angle = 0) {
    ggplot() +
      annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = fill) +
      annotate("text", x = 0.5, y = 0.5, label = txt, angle = angle, color = col,
               fontface = "bold", size = 10.5 / .pt) +
      scale_x_continuous(limits = c(0, 1), expand = expansion(0)) +
      scale_y_continuous(limits = c(0, 1), expand = expansion(0)) +
      theme_void() + theme(plot.margin = margin(0, 0, 0, 0))
  }
  s_col <- function(v) strip_box(titulos[[v]], "#e9e5d9", "grey15")
  s_fila <- list(Night = strip_box("Night", "#34495e", "white", -90),
                 Day   = strip_box("Day",   "#f6e7b4", "grey15", -90))

  fig <- wrap_plots(
    s_col("q"), s_col("theta"), s_col("U"), plot_spacer(),
    panel_tend("q", "Night", "A"), panel_tend("theta", "Night", "B"), panel_tend("U", "Night", "C"), s_fila$Night,
    panel_tend("q", "Day", "D"),   panel_tend("theta", "Day", "E"),   panel_tend("U", "Day", "F"),   s_fila$Day,
    ncol = 4, widths = c(1, 1, 1, 0.07), heights = c(0.085, 1, 1)) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

  save_fig(fig, paper_figure_files[["8"]], 10.5, 6.8, cfg)

  # mean ∂φ (accumulated change) at τ = 10, 60 and 120 min
  tend %>% filter(lag_min %in% c(10, 60, 120)) %>%
    select(variable, luz, regimen, lag_min, media, lo, hi, n) %>%
    rename(light = luz, regime = regimen, mean = media, ci95_low = lo, ci95_high = hi) %>%
    write_csv(file.path(dir_val, "fig08_tendencies_day_night.csv"))
}


# ------------------------------------------------------------------------------
# Figure 9: nocturnal accumulated change of q at several stations after each
# record of the main station classified as fog, dew or no AW
# ------------------------------------------------------------------------------
fig09_tendencies_stations <- function(theta_q, cfg, dir_val) {

  col_reg <- c("Fog" = "#4292c6", "Dew" = "#c97a4a", "No AW" = "#7f7f7f")

  regimen <- function(x) {
    factor(recode(x, "NIEBLA" = "Fog", "ROCIO" = "Dew", "SIN_EVENTO" = "No AW"),
           levels = c("Fog", "Dew", "No AW"))
  }

  # stations ordered by altitude and their position relative to the cloud / MBL
  zona  <- cfg$paper$fig09_stations
  est_q <- names(zona)

  q_est <- theta_q %>%
    filter(estacion %in% est_q) %>%
    distinct(datetime, estacion, .keep_all = TRUE) %>%
    select(datetime, estacion, q_gkg) %>%
    pivot_wider(names_from = estacion, values_from = q_gkg)

  serie_q <- theta_q %>%
    filter(estacion == cfg$main_station) %>%
    distinct(datetime, .keep_all = TRUE) %>%
    select(datetime, clasif_evento, radiacion_w_m2) %>%
    left_join(q_est, by = "datetime") %>%
    complete(datetime = seq(min(datetime), max(datetime), by = "10 min")) %>%
    arrange(datetime) %>%
    # light condition according to the radiation at the main station at t1
    mutate(luz = factor(case_when(radiacion_w_m2 <= cfg$night_radiation_max ~ "Night",
                                  radiacion_w_m2 > cfg$night_radiation_max  ~ "Day"), levels = c("Night", "Day")))

  # accumulated change ∂q(τ) = q(t + τ) − q(t), τ = 0 to 120 min, after each main-station record
  tend_q <- map_dfr(0:12, function(i) {
    serie_q %>%
      transmute(clasif_evento, luz, lag_min = i * 10,
                across(all_of(est_q), ~ lead(.x, i) - .x))
  }) %>%
    filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"), luz == "Night") %>%
    pivot_longer(all_of(est_q), names_to = "estacion", values_to = "tasa") %>%
    group_by(estacion, clasif_evento, lag_min) %>%
    summarise(media = mean(tasa, na.rm = TRUE),
              se    = sd(tasa, na.rm = TRUE) / sqrt(sum(!is.na(tasa))),
              n     = sum(!is.na(tasa)), .groups = "drop") %>%
    mutate(regimen = regimen(clasif_evento),
           lo = media - 1.96 * se, hi = media + 1.96 * se) %>%
    arrange(estacion, regimen, lag_min)

  tema <- theme_classic(base_size = 10) +
    theme(
      legend.title    = element_blank(),
      legend.position = "bottom",
      axis.line       = element_line(color = "#c3c2b7"),
      axis.ticks      = element_line(color = "#c3c2b7"),
      panel.grid.major.y = element_line(color = "#ecebe6", linewidth = 0.3),
      plot.title      = element_text(face = "bold", size = 10)
    )

  # common Y axis for the panels (includes the 95% CI)
  lim_y <- range(c(tend_q$lo, tend_q$hi, 0))
  lim_y <- lim_y + c(-1, 1) * 0.04 * diff(lim_y)

  panel_q <- function(est, letra) {
    d  <- tend_q %>% filter(estacion == est)
    ggplot(d, aes(lag_min, media, color = regimen, fill = regimen)) +
      geom_hline(yintercept = 0, color = "#c3c2b7", linewidth = 0.4) +
      geom_vline(xintercept = 60, color = "#c3c2b7", linetype = "22", linewidth = 0.4) +
      geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, color = NA) +
      geom_line(linewidth = 0.8) +
      geom_point(data = d %>% filter(lag_min %in% c(60, 120)), size = 1.6) +
      scale_color_manual(values = col_reg) + scale_fill_manual(values = col_reg) +
      scale_x_continuous(breaks = seq(0, 120, 30), limits = c(0, 120),
                         expand = expansion(add = c(2, 6))) +
      scale_y_continuous(limits = lim_y, expand = expansion(0)) +
      labs(tag = paste0("(", letra, ")"),
           x = "Min after occurrence",
           y = expression(partialdiff*q~(g~kg^{-1}))) +
      tema +
      theme(panel.border = element_rect(color = "#c3c2b7", fill = NA, linewidth = 0.4),
            plot.tag = element_text(face = "bold", size = 10, hjust = 0, vjust = 1),
            plot.tag.position = c(0, 1))
  }

  # strips: station on top (colour by zone), "Night" on the right
  strip_box <- function(txt, fill, col, angle = 0) {
    ggplot() +
      annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = fill) +
      annotate("text", x = 0.5, y = 0.5, label = txt, angle = angle, color = col,
               fontface = "bold", size = 10 / .pt, lineheight = 0.95) +
      scale_x_continuous(limits = c(0, 1), expand = expansion(0)) +
      scale_y_continuous(limits = c(0, 1), expand = expansion(0)) +
      theme_void() + theme(plot.margin = margin(0, 0, 0, 0))
  }
  zone_fills <- c("#e9e5d9", "#d9e6cf", "#d6dde5", "#eadbe0", "#dfe8e8")
  fill_zona <- setNames(zone_fills[seq_along(unique(zona))], unique(zona))
  s_est <- function(est) strip_box(paste0(str_remove(est, "_"), "\n", zona[[est]]),
                                   fill_zona[[zona[[est]]]], "grey15")

  n_est <- length(est_q)
  fig_est <- wrap_plots(
    c(map(est_q, s_est), list(plot_spacer()),
      map2(est_q, LETTERS[seq_len(n_est)], panel_q), list(strip_box("Night", "#34495e", "white", -90))),
    ncol = n_est + 1, widths = c(rep(1, n_est), 0.055), heights = c(0.16, 1)) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

  save_fig(fig_est, paper_figure_files[["9"]], 13 * n_est / 4, 4.4, cfg)

  # mean nocturnal ∂q (accumulated change) at τ = 10, 60 and 120 min
  tend_q %>% filter(lag_min %in% c(10, 60, 120)) %>%
    select(estacion, regimen, lag_min, media, lo, hi, n) %>%
    rename(station = estacion, regime = regimen, mean = media, ci95_low = lo, ci95_high = hi) %>%
    write_csv(file.path(dir_val, "fig09_tendencies_stations.csv"))
}
