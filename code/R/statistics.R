# ==============================================================================
# statistics.R
#
# 1. event_statistics(): event-based statistics of the manuscript (version
#    Manuscript-SA_v07; originally old/paper/estadistica_eventos_v07.R).
#    - Unit of analysis: event = consecutive records of the same class at the
#      main station; gaps of up to 60 min without collection belong to the same
#      event.
#    - No AW: each day (UTC) with no collection at all.
#    - Gradients: median of each event / day. Fog vs dew: Mann-Whitney and AUC
#      with 95% bootstrap CI (2000 resamples). Optimal cut-offs (Youden index)
#      with bootstrap CI.
#    - Tendencies: change after 60 min, mean of each event split into night and
#      day (radiation at the main station at t). Stations: paired Wilcoxon per
#      event (night).
#    Output: results/event_statistics.csv
#
# 2. seasonal_thresholds(): seasonal ∂θ/∂z values at the main station (mean per
#    occurrence type with bootstrap CI, AUC and 3-class accuracy of the seasonal
#    vs the annual values). Output: results/seasonal_dtheta_dz_values.csv
# ==============================================================================

event_statistics <- function(tq, cfg) {
  set.seed(20261114); B <- 2000

  auc <- function(p, n) { p <- p[is.finite(p)]; n <- n[is.finite(n)]; r <- rank(c(p, n))
    (sum(r[seq_along(p)]) - length(p) * (length(p) + 1) / 2) / (length(p) * length(n)) }
  youden <- function(pos, neg) { pos <- pos[is.finite(pos)]; neg <- neg[is.finite(neg)]
    cand <- sort(unique(c(pos, neg))); cand <- (head(cand, -1) + tail(cand, -1)) / 2
    j <- sapply(cand, function(t) mean(pos >= t) + mean(neg < t) - 1); i <- which.max(j)
    c(cutoff = cand[i], sens = mean(pos >= cand[i]), spec = mean(neg < cand[i])) }
  row_stats <- function(name, pos, neg, roc = FALSE) {   # pos = group with the larger values
    pos <- pos[is.finite(pos)]; neg <- neg[is.finite(neg)]
    b <- replicate(B, { p <- sample(pos, replace = TRUE); n <- sample(neg, replace = TRUE)
      c(auc(p, n), if (roc) youden(p, n)["cutoff"] else NA) })
    out <- tibble(comparison = name, n_pos = length(pos), n_neg = length(neg),
                  median_pos = median(pos), median_neg = median(neg),
                  AUC = auc(pos, neg), AUC_CI_low = quantile(b[1, ], .025), AUC_CI_high = quantile(b[1, ], .975),
                  p_MannWhitney = wilcox.test(pos, neg, exact = FALSE)$p.value)
    if (roc) { y <- youden(pos, neg)
      out <- out %>% mutate(cutoff = y["cutoff"], cutoff_CI_low = quantile(b[2, ], .025), cutoff_CI_high = quantile(b[2, ], .975),
                            correct_pos = y["sens"], correct_neg = y["spec"]) }
    out
  }

  main  <- cfg$main_station
  ref   <- cfg$reference_station
  z_ref <- z_of(tq, ref)
  lab   <- function(st) station_label(st)

  grid <- tibble(datetime = seq(ymd_hms(paste0(cfg$year, "-01-01 00:00:00"), tz = "UTC"),
                                ymd_hms(paste0(cfg$year, "-12-31 23:50:00"), tz = "UTC"), by = "10 min"))
  ref_d <- tq %>% filter(estacion == ref) %>% select(datetime, th0 = theta_K, q0 = q_gkg, u0 = viento_vel_m_s)
  est <- sort_by_altitude(tq, setdiff(unique(tq$estacion), c(ref, cfg$excluded_stations)))
  grad <- tq %>% filter(estacion %in% est) %>% left_join(ref_d, by = "datetime") %>%
    transmute(datetime, estacion, gth = (theta_K - th0) / (z_m - z_ref), gq = (q_gkg - q0) / (z_m - z_ref),
              gu = (viento_vel_m_s - u0) / (z_m - z_ref), q = q_gkg, theta = theta_K, U = viento_vel_m_s)
  d <- grid %>% left_join(tq %>% filter(estacion == main) %>% select(datetime, clase = clasif_evento, rad = radiacion_w_m2), by = "datetime") %>%
    mutate(fecha = as.Date(datetime), luz = case_when(rad <= cfg$night_radiation_max ~ "Night",
                                                      rad >  cfg$night_radiation_max ~ "Day"))
  aw <- d %>% filter(clase %in% c("NIEBLA", "ROCIO")) %>% arrange(datetime) %>%
    mutate(gap = as.numeric(datetime - lag(datetime), units = "mins"),
           evento = cumsum(is.na(gap) | gap > 60 | clase != lag(clase)))
  d <- d %>% left_join(aw %>% select(datetime, evento), by = "datetime") %>%
    mutate(dia_sin_aw = !fecha %in% unique(aw$fecha) & !is.na(clase))

  # ---- vertical gradients ----
  g_ev <- grad %>% inner_join(d %>% filter(!is.na(evento)) %>% select(datetime, evento, clase), by = "datetime") %>%
    group_by(estacion, evento, clase) %>% summarise(across(c(gth, gq, gu), ~ median(.x, na.rm = TRUE)), .groups = "drop")
  g_na <- grad %>% inner_join(d %>% filter(dia_sin_aw) %>% select(datetime, fecha), by = "datetime") %>%
    group_by(estacion, fecha) %>% summarise(n = sum(!is.na(gth)), across(c(gth, gq, gu), ~ median(.x, na.rm = TRUE)), .groups = "drop") %>%
    filter(n >= 36) %>% mutate(clase = "SIN_AW")
  G <- bind_rows(g_ev, g_na) %>% mutate(across(c(gth, gq, gu), ~ if_else(is.nan(.x), NA_real_, .x)))
  s <- function(st, k, v) G[[v]][G$estacion == st & G$clase == k]
  m <- lab(main)
  res <- bind_rows(
    row_stats(paste0("dθ/dz ", m, ": dew > fog (ROC)"), s(main, "ROCIO", "gth"), s(main, "NIEBLA", "gth"), roc = TRUE),
    row_stats(paste0("dθ/dz ", m, ": no AW > dew (ROC)"), s(main, "SIN_AW", "gth"), s(main, "ROCIO", "gth"), roc = TRUE),
    row_stats(paste0("dq/dz ", m, ": dew > fog"), s(main, "ROCIO", "gq"), s(main, "NIEBLA", "gq")),
    row_stats(paste0("dq/dz ", m, ": fog+dew > no AW (ROC)"), c(s(main, "NIEBLA", "gq"), s(main, "ROCIO", "gq")), s(main, "SIN_AW", "gq"), roc = TRUE),
    row_stats(paste0("dU/dz ", m, ": dew > fog"), s(main, "ROCIO", "gu"), s(main, "NIEBLA", "gu")),
    map_dfr(setdiff(est, main), ~ row_stats(paste0("dθ/dz ", .x, ": dew > fog"), s(.x, "ROCIO", "gth"), s(.x, "NIEBLA", "gth")))
  )

  # ---- tendencies after 60 min ----
  s11 <- grid %>% left_join(grad %>% filter(estacion == main) %>% select(datetime, q, theta, U), by = "datetime") %>%
    mutate(across(c(q, theta, U), ~ lead(.x, 6) - .x))
  uni <- d %>% transmute(datetime, luz, unidad = case_when(!is.na(evento) ~ paste0("ev", evento), dia_sin_aw ~ paste0("na", fecha)),
                         tipo = case_when(!is.na(evento) ~ clase, dia_sin_aw ~ "SIN_AW")) %>% filter(!is.na(unidad), !is.na(luz))
  t60 <- s11 %>% inner_join(uni, by = "datetime") %>% group_by(tipo, luz, unidad) %>%
    summarise(n = n(), across(c(q, theta, U), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
    filter(!(tipo == "SIN_AW" & n < 6)) %>% mutate(across(c(q, theta, U), ~ if_else(is.nan(.x), NA_real_, .x)))
  tt <- function(l, k, v) t60[[v]][t60$luz == l & t60$tipo == k]
  res <- bind_rows(res,
    row_stats("night dq/dt: fog > dew", tt("Night", "NIEBLA", "q"), tt("Night", "ROCIO", "q")),
    row_stats("night dq/dt: dew > no AW", tt("Night", "ROCIO", "q"), tt("Night", "SIN_AW", "q")),
    row_stats("day dq/dt: fog > dew", tt("Day", "NIEBLA", "q"), tt("Day", "ROCIO", "q")),
    row_stats("night dθ/dt: dew > fog", tt("Night", "ROCIO", "theta"), tt("Night", "NIEBLA", "theta")),
    row_stats("day dθ/dt: dew > fog (ROC)", tt("Day", "ROCIO", "theta"), tt("Day", "NIEBLA", "theta"), roc = TRUE),
    row_stats("night dU/dt: dew > fog", tt("Night", "ROCIO", "U"), tt("Night", "NIEBLA", "U")),
    row_stats("day dU/dt: dew > fog", tt("Day", "ROCIO", "U"), tt("Day", "NIEBLA", "U")))

  # ---- stations (night, paired by event) ----
  est_q <- names(cfg$paper$fig09_stations)
  others <- setdiff(est_q, main)
  qw <- grad %>% filter(estacion %in% est_q) %>% select(datetime, estacion, q) %>% pivot_wider(names_from = estacion, values_from = q) %>%
    right_join(grid, by = "datetime") %>% arrange(datetime) %>% mutate(across(all_of(est_q), ~ lead(.x, 6) - .x))
  e60 <- qw %>% inner_join(uni %>% filter(luz == "Night", tipo != "SIN_AW"), by = "datetime") %>%
    group_by(tipo, unidad) %>% summarise(across(all_of(est_q), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
    mutate(across(all_of(est_q), ~ if_else(is.nan(.x), NA_real_, .x)))
  type_en <- c(NIEBLA = "fog", ROCIO = "dew")
  pairs <- map_dfr(c("NIEBLA", "ROCIO"), function(k) map_dfr(others, function(st) {
    e <- e60 %>% filter(tipo == k); ok <- is.finite(e[[main]]) & is.finite(e[[st]])
    tibble(comparison = paste0("night dq/dt ", type_en[[k]], ": ", m, " vs ", st, " (paired Wilcoxon)"), n_pos = sum(ok),
           median_pos = median(e[[main]][ok]), median_neg = median(e[[st]][ok]),
           p_MannWhitney = wilcox.test(e[[main]][ok], e[[st]][ok], paired = TRUE, exact = FALSE)$p.value)
  }))
  res <- bind_rows(res, pairs)

  dir.create(cfg$dir_results, recursive = TRUE, showWarnings = FALSE)
  write_csv(res, file.path(cfg$dir_results, "event_statistics.csv"))
  invisible(res)
}

sort_by_altitude <- function(tq, stations) {
  z <- tq %>% filter(estacion %in% stations) %>% distinct(estacion, z_m) %>% arrange(z_m)
  z$estacion
}


seasonal_thresholds <- function(theta_q, cfg) {
  set.seed(20260721)

  ref   <- cfg$reference_station
  z_ref <- z_of(theta_q, ref)

  gradient_data <- theta_q %>%
    group_by(datetime) %>%
    mutate(
      theta_ref  = theta_K[estacion == ref][1],
      grad_theta = if_else(z_m == z_ref, 0, (theta_K - theta_ref) / (z_m - z_ref))
    ) %>%
    ungroup()

  # Astronomical seasons (southern hemisphere), approximated to the 21st of each
  # transition month. 21-31 December is grouped with 1 January to 20 March as
  # "Summer": with a single calendar year, summer cannot be split without losing data.
  season_of_year <- function(date) {
    md <- format(date, "%m-%d")
    case_when(
      md >= "12-21" | md <= "03-20" ~ "Summer (DJF)",
      md >= "03-21" & md <= "06-20" ~ "Autumn (MAM)",
      md >= "06-21" & md <= "09-20" ~ "Winter (JJA)",
      md >= "09-21" & md <= "12-20" ~ "Spring (SON)"
    )
  }
  season_levels <- c("Summer (DJF)", "Autumn (MAM)", "Winter (JJA)", "Spring (SON)")

  d1211 <- gradient_data %>%
    filter(estacion == cfg$main_station, clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
    filter(!is.na(grad_theta)) %>%
    mutate(season = factor(season_of_year(datetime), levels = season_levels))

  # fixed annual values (reference)
  annual_fog <- mean(d1211$grad_theta[d1211$clasif_evento == "NIEBLA"])
  annual_dew <- mean(d1211$grad_theta[d1211$clasif_evento == "ROCIO"])

  classify_3 <- function(grad_theta, v_fog, v_dew) {
    case_when(
      grad_theta < v_fog ~ "NIEBLA",
      grad_theta < v_dew ~ "ROCIO",
      TRUE ~ "SIN_EVENTO"
    )
  }

  bootstrap_mean <- function(x, R = 2000) {
    means <- replicate(R, mean(sample(x, length(x), replace = TRUE)))
    c(mean    = mean(x),
      ci_low  = quantile(means, 0.025, names = FALSE),
      ci_high = quantile(means, 0.975, names = FALSE))
  }

  seasonal_results <- map_dfr(season_levels, function(s) {
    d_s <- d1211 %>% filter(season == s)

    x_fog  <- d_s$grad_theta[d_s$clasif_evento == "NIEBLA"]
    x_dew  <- d_s$grad_theta[d_s$clasif_evento == "ROCIO"]
    x_none <- d_s$grad_theta[d_s$clasif_evento == "SIN_EVENTO"]

    # seasonal values (mean per category, same criterion as the annual one)
    boot_fog <- bootstrap_mean(x_fog)
    boot_dew <- bootstrap_mean(x_dew)
    v_fog_s <- boot_fog["mean"]
    v_dew_s <- boot_dew["mean"]

    # ROC/AUC validation (independent of the mean criterion)
    d_roc_fd <- d_s %>% filter(clasif_evento %in% c("NIEBLA", "ROCIO")) %>% mutate(is_dew = clasif_evento == "ROCIO")
    auc_fd <- as.numeric(pROC::auc(pROC::roc(d_roc_fd$is_dew, d_roc_fd$grad_theta, quiet = TRUE)))
    d_roc_dn <- d_s %>% filter(clasif_evento %in% c("ROCIO", "SIN_EVENTO")) %>% mutate(is_none = clasif_evento == "SIN_EVENTO")
    auc_dn <- as.numeric(pROC::auc(pROC::roc(d_roc_dn$is_none, d_roc_dn$grad_theta, quiet = TRUE)))

    # 3-class accuracy: seasonal values vs fixed annual values
    acc_seasonal <- mean(classify_3(d_s$grad_theta, v_fog_s, v_dew_s) == d_s$clasif_evento)
    acc_annual   <- mean(classify_3(d_s$grad_theta, annual_fog, annual_dew) == d_s$clasif_evento)

    tibble(
      season = s,
      n_fog = length(x_fog), n_dew = length(x_dew), n_no_occurrence = length(x_none),
      value_fog = v_fog_s, ci_fog_low = boot_fog["ci_low"], ci_fog_high = boot_fog["ci_high"],
      value_dew = v_dew_s, ci_dew_low = boot_dew["ci_low"], ci_dew_high = boot_dew["ci_high"],
      mean_no_occurrence = mean(x_none),
      auc_fog_dew = auc_fd, auc_dew_no_occurrence = auc_dn,
      accuracy_seasonal = acc_seasonal, accuracy_annual = acc_annual
    )
  })

  dir.create(cfg$dir_results, recursive = TRUE, showWarnings = FALSE)
  write_csv(seasonal_results, file.path(cfg$dir_results, "seasonal_dtheta_dz_values.csv"))
  invisible(seasonal_results)
}
