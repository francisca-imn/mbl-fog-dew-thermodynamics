# ==============================================================================
# 06_statistical_tests.R
#
# Step 6 of the pipeline. Formal statistical tests reported in the manuscript.
# Uses data/derived/oya1211_classification_2024.csv (step 3) and
# data/derived/stations_theta_q_2024.csv (step 4).
#
#   1. Relative humidity: fog vs dew at OYA1211 (Mann-Whitney).
#   2. Vertical gradients (dtheta/dz, dq/dz, dU/dz): Kruskal-Wallis (fog, dew,
#      no occurrence) and Mann-Whitney fog vs dew with Wilcoxon effect size r,
#      along the whole transect and at OYA1211.
#   3. dtheta/dz at OYA1211: mean per occurrence type and its ability to
#      separate fog from dew (ROC/AUC, Youden cut-off, accuracy of 0.0026 K/m).
#      Also the mean dq/dz of fog and dew at OYA1211.
#   4. Temporal tendencies (dphi/dt, 1 to 3 h, OYA1211): Kruskal-Wallis and
#      Mann-Whitney fog vs dew after removing outliers (1.5 x IQR).
#   5. Bootstrap confidence interval of the median dq/dt during dew.
#
# Note on dew validation: the surface temperature recorded at OYA1211
# (temp_sup_c) is the bare-soil surface temperature, not the temperature of the
# standard dew collector (SDC) plate. Using it as a proxy of the SDC would bias
# the T_surface <= T_dew criterion (different thermal mass and emissivity), so it
# is not used as an independent dew validation.
#
# Run from the project root (open mbl-fog-dew-thermodynamics.Rproj).
# ==============================================================================

library(tidyverse)
library(lubridate)
library(pROC)

set.seed(20260712)

classification_1211 <- read_csv(
  "data/derived/oya1211_classification_2024.csv",
  show_col_types = FALSE
)

# Wilcoxon effect size r = |Z| / sqrt(N), from the W statistic. With thousands
# of records, a Wilcoxon test flags tiny median differences as "significant";
# r tells whether the difference is large or trivial in practice
# (Cohen: ~0.1 small, ~0.3 medium, ~0.5 large).
effect_r_wilcox <- function(w_test, n1, n2) {
  mu_w <- n1 * n2 / 2
  sigma_w <- sqrt(n1 * n2 * (n1 + n2 + 1) / 12)
  z <- (w_test$statistic - mu_w) / sigma_w
  abs(as.numeric(z)) / sqrt(n1 + n2)
}

# ------------------------------------------------------------------------------
# 1. RELATIVE HUMIDITY: FOG vs DEW AT OYA1211
# ------------------------------------------------------------------------------
cat("\n================ 1. Relative humidity, fog vs dew (OYA1211) ================\n")

rh_fog <- classification_1211$humedad[classification_1211$clasif_evento == "NIEBLA"]
rh_dew <- classification_1211$humedad[classification_1211$clasif_evento == "ROCIO"]

cat(sprintf("n(fog) = %d, median = %.1f%%; n(dew) = %d, median = %.1f%%\n",
            sum(!is.na(rh_fog)), median(rh_fog, na.rm = TRUE),
            sum(!is.na(rh_dew)), median(rh_dew, na.rm = TRUE)))

wilcox_rh <- wilcox.test(rh_fog, rh_dew, conf.int = TRUE)
print(wilcox_rh)

n1 <- sum(!is.na(rh_fog)); n2 <- sum(!is.na(rh_dew))
cat(sprintf("Wilcoxon effect size r (RH) = %.3f\n", effect_r_wilcox(wilcox_rh, n1, n2)))

# ------------------------------------------------------------------------------
# 2. VERTICAL GRADIENTS (dtheta/dz, dq/dz, dU/dz)
# ------------------------------------------------------------------------------
cat("\n================ 2. Vertical gradients: load and derive ================\n")

theta_q <- read_csv(
  "data/derived/stations_theta_q_2024.csv",
  show_col_types = FALSE
)

# Gradients between each station and the coastal reference station (48 m)
gradient_data <- theta_q %>%
  group_by(datetime) %>%
  mutate(
    theta_ref  = theta_K[estacion == "AEROPUERTO"][1],
    q_ref      = q_gkg[estacion == "AEROPUERTO"][1],
    u_ref      = viento_vel_m_s[estacion == "AEROPUERTO"][1],
    grad_theta = if_else(z_m == 48, 0, (theta_K - theta_ref) / (z_m - 48)),
    grad_q     = if_else(z_m == 48, 0, (q_gkg - q_ref) / (z_m - 48)),
    grad_u     = if_else(z_m == 48, 0, (viento_vel_m_s - u_ref) / (z_m - 48))
  ) %>%
  ungroup()

# --- N per category (whole transect, excluding the trivial 48 m row) ---
cat("\nN per category (dtheta/dz, whole transect):\n")
print(gradient_data %>%
        filter(z_m != 48, clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
        filter(!is.na(grad_theta)) %>%
        count(clasif_evento, name = "n_theta"))

# --- N per category at OYA1211 ---
cat("\nN per category (OYA1211 only):\n")
print(gradient_data %>%
        filter(estacion == "OYA_1211", clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
        filter(!is.na(grad_theta)) %>%
        count(clasif_evento, name = "n_theta_1211"))

# --- Gradient availability at OYA1069 (no valid temperature or wind in 2024) ---
cat("\nGradient availability at OYA1069:\n")
print(gradient_data %>%
        filter(estacion == "OYA_1069", clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
        summarise(n_total = n(),
                  n_grad_theta_valid = sum(!is.na(grad_theta)),
                  n_grad_q_valid = sum(!is.na(grad_q)),
                  n_grad_u_valid = sum(!is.na(grad_u))))

cat("\n================ 3. Formal tests of the vertical gradients ================\n")

test_gradient <- function(data, var, label, station = NULL) {
  d <- data %>% filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"), z_m != 48)
  if (!is.null(station)) d <- d %>% filter(estacion == station)
  d <- d %>% filter(!is.na(.data[[var]]))

  kw <- kruskal.test(d[[var]], d$clasif_evento)
  x1 <- d[[var]][d$clasif_evento == "NIEBLA"]
  x2 <- d[[var]][d$clasif_evento == "ROCIO"]
  wt_fd <- wilcox.test(x1, x2)
  r_fd <- effect_r_wilcox(wt_fd, length(x1), length(x2))

  cat(sprintf("\n--- %s%s ---\n", label,
              ifelse(is.null(station), " (whole transect)", paste0(" (", station, ")"))))
  cat(sprintf("Kruskal-Wallis (3 groups): chi2 = %.2f, df = %d, p = %.2e\n",
              kw$statistic, kw$parameter, kw$p.value))
  cat(sprintf("Mann-Whitney fog vs dew: W = %.0f, p = %.2e, effect size r = %.3f\n",
              wt_fd$statistic, wt_fd$p.value, r_fd))
  medians <- d %>% group_by(clasif_evento) %>%
    summarise(median = median(.data[[var]]), n = n(), .groups = "drop")
  print(medians)
  invisible(list(kw = kw, wt = wt_fd, medians = medians, r = r_fd))
}

res_theta_transect <- test_gradient(gradient_data, "grad_theta", "dtheta/dz")
res_theta_1211     <- test_gradient(gradient_data, "grad_theta", "dtheta/dz", "OYA_1211")
res_q_transect     <- test_gradient(gradient_data, "grad_q", "dq/dz")
res_u_transect     <- test_gradient(gradient_data, "grad_u", "dU/dz")

# ------------------------------------------------------------------------------
# 4. dtheta/dz AT OYA1211: MEANS AND ABILITY TO SEPARATE FOG FROM DEW (ROC)
# ------------------------------------------------------------------------------
cat("\n================ 4. dtheta/dz at OYA1211: means and ROC ================\n")

d_roc <- gradient_data %>%
  filter(estacion == "OYA_1211", clasif_evento %in% c("NIEBLA", "ROCIO")) %>%
  filter(!is.na(grad_theta)) %>%
  mutate(is_dew = clasif_evento == "ROCIO")

# Same criterion for both categories: the mean dtheta/dz of each category at the
# anchor station
mean_fog_1211 <- mean(d_roc$grad_theta[!d_roc$is_dew])
mean_dew_1211 <- mean(d_roc$grad_theta[d_roc$is_dew])
cat(sprintf("Mean dtheta/dz, fog (OYA1211) = %.6f K/m\n", mean_fog_1211))
cat(sprintf("Mean dtheta/dz, dew (OYA1211) = %.6f K/m\n", mean_dew_1211))

roc_obj <- roc(response = d_roc$is_dew, predictor = d_roc$grad_theta, quiet = TRUE)
auc_val <- as.numeric(auc(roc_obj))
youden <- coords(roc_obj, "best", best.method = "youden",
                 ret = c("threshold", "sensitivity", "specificity", "accuracy"))
cat(sprintf("AUC = %.3f\n", auc_val))
cat("Optimal cut-off (Youden):\n")
print(youden)

# Accuracy of the 0.0026 K/m value used in the text and figures
cut_text <- 0.0026
pred_text <- ifelse(d_roc$grad_theta < cut_text, "NIEBLA", "ROCIO")
acc_text <- mean(pred_text == d_roc$clasif_evento)
cat(sprintf("\nAccuracy of 0.0026 K/m (fog if dtheta/dz < 0.0026) against the visibility + GOES classification = %.1f%%\n",
            100 * acc_text))
print(table(Predicted = pred_text, Observed = d_roc$clasif_evento))

# --- Mean dq/dz at OYA1211 (same criterion: mean per category) ---
d_q_1211 <- gradient_data %>%
  filter(estacion == "OYA_1211", clasif_evento %in% c("NIEBLA", "ROCIO")) %>%
  filter(!is.na(grad_q))
mean_q_fog_1211   <- mean(d_q_1211$grad_q[d_q_1211$clasif_evento == "NIEBLA"])
median_q_fog_1211 <- median(d_q_1211$grad_q[d_q_1211$clasif_evento == "NIEBLA"])
mean_q_dew_1211   <- mean(d_q_1211$grad_q[d_q_1211$clasif_evento == "ROCIO"])
median_q_dew_1211 <- median(d_q_1211$grad_q[d_q_1211$clasif_evento == "ROCIO"])
cat(sprintf("\ndq/dz fog (OYA1211): mean = %.6f, median = %.6f g/kg/m\n", mean_q_fog_1211, median_q_fog_1211))
cat(sprintf("dq/dz dew (OYA1211): mean = %.6f, median = %.6f g/kg/m\n", mean_q_dew_1211, median_q_dew_1211))
cat(sprintf("Mean of both categories (OYA1211) = %.6f g/kg/m (vs. -0.0016 of Lobos-Roco et al., 2018)\n",
            mean(c(mean_q_fog_1211, mean_q_dew_1211))))

# ------------------------------------------------------------------------------
# 5. TEMPORAL TENDENCIES (dphi/dt) AT OYA1211, 1 TO 3 h
# ------------------------------------------------------------------------------
cat("\n================ 5. Temporal tendencies (1 to 3 h) ================\n")

data_1211_time <- gradient_data %>%
  filter(estacion == "OYA_1211") %>%
  arrange(datetime)

# Forward finite difference: first valid value between lag_min and lag_max
# 10-min steps ahead (6 = 1 h, 18 = 3 h), divided by the elapsed time in hours
forward_rate <- function(i, var_vec, time_vec, lag_min = 6, lag_max) {
  for (lag in lag_min:lag_max) {
    j <- i + lag
    if (j <= length(var_vec) && !is.na(var_vec[j])) {
      dt_hours <- as.numeric(difftime(time_vec[j], time_vec[i], units = "hours"))
      return((var_vec[j] - var_vec[i]) / dt_hours)
    }
  }
  NA_real_
}

time_vec <- data_1211_time$datetime

temporal_rates <- function(lag_max) {
  tibble(
    dq_dt  = sapply(seq_along(data_1211_time$q_gkg), forward_rate,
                    var_vec = data_1211_time$q_gkg, time_vec = time_vec, lag_max = lag_max),
    dth_dt = sapply(seq_along(data_1211_time$theta_K), forward_rate,
                    var_vec = data_1211_time$theta_K, time_vec = time_vec, lag_max = lag_max),
    dws_dt = sapply(seq_along(data_1211_time$viento_vel_m_s), forward_rate,
                    var_vec = data_1211_time$viento_vel_m_s, time_vec = time_vec, lag_max = lag_max)
  )
}

rates <- data_1211_time %>%
  select(clasif_evento) %>%
  bind_cols(temporal_rates(lag_max = 18)) %>%
  filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"))

# Outlier removal (1.5 x IQR) per variable and category
trim_iqr <- function(df, var) {
  df %>%
    group_by(clasif_evento) %>%
    mutate(Q1 = quantile(.data[[var]], 0.25, na.rm = TRUE),
           Q3 = quantile(.data[[var]], 0.75, na.rm = TRUE),
           IQR = Q3 - Q1) %>%
    filter(.data[[var]] >= Q1 - 1.5 * IQR, .data[[var]] <= Q3 + 1.5 * IQR) %>%
    ungroup()
}

cat("\nN per category (temporal tendencies, before outlier removal):\n")
print(rates %>% filter(!is.na(dq_dt)) %>% count(clasif_evento, name = "n_dqdt"))

test_rate <- function(var, label) {
  d <- trim_iqr(rates %>% filter(!is.na(.data[[var]])), var)
  kw <- kruskal.test(d[[var]], d$clasif_evento)
  x1 <- d[[var]][d$clasif_evento == "NIEBLA"]
  x2 <- d[[var]][d$clasif_evento == "ROCIO"]
  wt_fd <- wilcox.test(x1, x2, conf.int = TRUE)
  r_fd <- effect_r_wilcox(wt_fd, length(x1), length(x2))
  cat(sprintf("\n--- %s ---\n", label))
  cat(sprintf("Kruskal-Wallis (3 groups): chi2 = %.2f, df = %d, p = %.2e\n",
              kw$statistic, kw$parameter, kw$p.value))
  cat(sprintf("Mann-Whitney fog vs dew: W = %.0f, p = %.2e, effect size r = %.3f, median difference 95%% CI = [%.3f, %.3f]\n",
              wt_fd$statistic, wt_fd$p.value, r_fd, wt_fd$conf.int[1], wt_fd$conf.int[2]))
  medians <- d %>% group_by(clasif_evento) %>%
    summarise(median = round(median(.data[[var]]), 3), n = n(), .groups = "drop")
  print(medians)
  invisible(list(kw = kw, wt = wt_fd, data = d))
}

res_dq_dt  <- test_rate("dq_dt",  "dq/dt (g/kg per hour)")
res_dth_dt <- test_rate("dth_dt", "dtheta/dt (K per hour)")
res_dws_dt <- test_rate("dws_dt", "dU/dt (m/s per hour)")

# ------------------------------------------------------------------------------
# 6. BOOTSTRAP CI OF THE MEDIAN dq/dt DURING DEW
# ------------------------------------------------------------------------------
cat("\n================ 6. Bootstrap CI of the median dq/dt ================\n")

dq_dt_dew <- res_dq_dt$data$dq_dt[res_dq_dt$data$clasif_evento == "ROCIO"]
dq_dt_fog <- res_dq_dt$data$dq_dt[res_dq_dt$data$clasif_evento == "NIEBLA"]

bootstrap_median <- function(x, R = 10000) {
  meds <- replicate(R, median(sample(x, length(x), replace = TRUE)))
  c(median  = median(x),
    ci_low  = quantile(meds, 0.025, names = FALSE),
    ci_high = quantile(meds, 0.975, names = FALSE))
}

boot_dew <- bootstrap_median(dq_dt_dew)
boot_fog <- bootstrap_median(dq_dt_fog)

cat(sprintf("Dew: median dq/dt = %.3f g/kg/h, 95%% bootstrap CI = [%.3f, %.3f], n = %d\n",
            boot_dew["median"], boot_dew["ci_low"], boot_dew["ci_high"], length(dq_dt_dew)))
cat(sprintf("Fog: median dq/dt = %.3f g/kg/h, 95%% bootstrap CI = [%.3f, %.3f], n = %d\n",
            boot_fog["median"], boot_fog["ci_low"], boot_fog["ci_high"], length(dq_dt_fog)))
cat(sprintf("Value reported for dew by Lobos-Roco et al. (2024): -0.25 g/kg/h -> %s the 95%% bootstrap CI of this study\n",
            ifelse(-0.25 < boot_dew["ci_low"] | -0.25 > boot_dew["ci_high"], "OUTSIDE", "INSIDE")))

# ------------------------------------------------------------------------------
# 7. KEY NUMBERS
# ------------------------------------------------------------------------------
cat("\n================ KEY NUMBERS ================\n")
cat(sprintf("1) RH fog vs dew: Mann-Whitney p = %.2e, median fog = %.1f%%, median dew = %.1f%%, effect size r = %.3f\n",
            wilcox_rh$p.value, median(rh_fog, na.rm = TRUE), median(rh_dew, na.rm = TRUE),
            effect_r_wilcox(wilcox_rh, n1, n2)))
cat(sprintf("3) Mean dtheta/dz at OYA1211: fog = %.4f, dew = %.4f K/m\n", mean_fog_1211, mean_dew_1211))
cat(sprintf("4) AUC of dtheta/dz (fog vs dew) = %.3f; accuracy of 0.0026 K/m = %.1f%%\n", auc_val, 100 * acc_text))
cat(sprintf("6) Dew dq/dt median = %.3f [%.3f, %.3f] g/kg/h (95%% bootstrap)\n",
            boot_dew["median"], boot_dew["ci_low"], boot_dew["ci_high"]))
