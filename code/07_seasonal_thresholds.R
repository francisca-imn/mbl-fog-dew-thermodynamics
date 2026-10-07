# ==============================================================================
# 07_seasonal_thresholds.R
#
# Step 7 of the pipeline. Extends the annual dtheta/dz values of
# 06_statistical_tests.R (section 4) to the four seasons of the year (southern
# hemisphere). The annual values (fog mean 0.0026 K/m, dew mean 0.0034 K/m,
# no occurrence ~0.0094 K/m, all at OYA1211) are recomputed for each season with
# the same criterion and the same anchor station:
#   - fog value = mean dtheta/dz of the NIEBLA records
#   - dew value = mean dtheta/dz of the ROCIO records
#   - implicit ranges: fog < fog value <= dew <= dew value < no occurrence
#
# Question: is the fixed annual value (0.0026/0.0034) representative of the
# whole year, or should seasonal values be reported? Besides deriving the
# seasonal values, their ability to reproduce the visibility + GOES
# classification is evaluated (ROC/AUC, accuracy) and compared with the
# accuracy of the fixed annual values within each season.
#
# Output: summary printed to the console and results/seasonal_dtheta_dz_values.csv
#
# Run from the project root (open mbl-fog-dew-thermodynamics.Rproj).
# ==============================================================================

library(tidyverse)
library(lubridate)
library(pROC)

set.seed(20260721)

# ------------------------------------------------------------------------------
# 0. LOAD AND DERIVE (same as 06_statistical_tests.R, section 2)
# ------------------------------------------------------------------------------
theta_q <- read_csv(
  "data/derived/stations_theta_q_2024.csv",
  show_col_types = FALSE
)

gradient_data <- theta_q %>%
  group_by(datetime) %>%
  mutate(
    theta_ref  = theta_K[estacion == "AEROPUERTO"][1],
    grad_theta = if_else(z_m == 48, 0, (theta_K - theta_ref) / (z_m - 48))
  ) %>%
  ungroup()

# Astronomical seasons (southern hemisphere), approximated to the 21st of each
# transition month (21 Dec to 20 Mar summer; 21 Mar to 20 Jun autumn; 21 Jun to
# 20 Sep winter; 21 Sep to 20 Dec spring). 21-31 December 2024 is grouped with
# 1 January to 20 March 2024 as "Summer", although strictly they belong to two
# different summers: with a single calendar year, summer cannot be split
# without losing data.
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
  filter(estacion == "OYA_1211", clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
  filter(!is.na(grad_theta)) %>%
  mutate(season = factor(season_of_year(datetime), levels = season_levels))

cat(sprintf("Total N at OYA1211 (valid dtheta/dz, 3 categories) = %d\n", nrow(d1211)))
cat("\nN per season and category:\n")
print(d1211 %>% count(season, clasif_evento) %>% pivot_wider(names_from = clasif_evento, values_from = n))

# ------------------------------------------------------------------------------
# 1. FIXED ANNUAL VALUES (reference; same as 06_statistical_tests.R section 4)
# ------------------------------------------------------------------------------
cat("\n================ 1. Fixed annual values (reference, whole 2024) ================\n")

annual_fog <- mean(d1211$grad_theta[d1211$clasif_evento == "NIEBLA"])
annual_dew <- mean(d1211$grad_theta[d1211$clasif_evento == "ROCIO"])
annual_none <- mean(d1211$grad_theta[d1211$clasif_evento == "SIN_EVENTO"])

cat(sprintf("Annual fog value (mean, OYA1211)            = %.6f K/m\n", annual_fog))
cat(sprintf("Annual dew value (mean, OYA1211)            = %.6f K/m\n", annual_dew))
cat(sprintf("Annual no-occurrence mean (reference)       = %.6f K/m\n", annual_none))

classify_3 <- function(grad_theta, v_fog, v_dew) {
  case_when(
    grad_theta < v_fog ~ "NIEBLA",
    grad_theta < v_dew ~ "ROCIO",
    TRUE ~ "SIN_EVENTO"
  )
}

# ------------------------------------------------------------------------------
# 2. SEASONAL VALUES: DESCRIPTIVES, TESTS, ROC AND ACCURACY
# ------------------------------------------------------------------------------
cat("\n================ 2. Seasonal dtheta/dz values ================\n")

effect_r_wilcox <- function(w_test, n1, n2) {
  mu_w <- n1 * n2 / 2
  sigma_w <- sqrt(n1 * n2 * (n1 + n2 + 1) / 12)
  z <- (w_test$statistic - mu_w) / sigma_w
  abs(as.numeric(z)) / sqrt(n1 + n2)
}

bootstrap_mean <- function(x, R = 2000) {
  means <- replicate(R, mean(sample(x, length(x), replace = TRUE)))
  c(mean    = mean(x),
    ci_low  = quantile(means, 0.025, names = FALSE),
    ci_high = quantile(means, 0.975, names = FALSE))
}

seasonal_results <- map_dfr(season_levels, function(s) {

  cat(sprintf("\n---------------------------------------------------------------\n%s\n---------------------------------------------------------------\n", s))
  d_s <- d1211 %>% filter(season == s)

  x_fog  <- d_s$grad_theta[d_s$clasif_evento == "NIEBLA"]
  x_dew  <- d_s$grad_theta[d_s$clasif_evento == "ROCIO"]
  x_none <- d_s$grad_theta[d_s$clasif_evento == "SIN_EVENTO"]

  # --- Descriptives ---
  desc <- d_s %>%
    group_by(clasif_evento) %>%
    summarise(n = n(), mean = mean(grad_theta), median = median(grad_theta),
              sd = sd(grad_theta), .groups = "drop")
  cat("dtheta/dz descriptives:\n"); print(desc)

  # --- Kruskal-Wallis (3 groups) + pairwise Mann-Whitney ---
  kw <- kruskal.test(d_s$grad_theta, d_s$clasif_evento)
  wt_fd <- wilcox.test(x_fog, x_dew)
  wt_dn <- wilcox.test(x_dew, x_none)
  r_fd <- effect_r_wilcox(wt_fd, length(x_fog), length(x_dew))
  r_dn <- effect_r_wilcox(wt_dn, length(x_dew), length(x_none))
  cat(sprintf("Kruskal-Wallis (3 groups): chi2 = %.1f, df = %d, p = %.2e\n", kw$statistic, kw$parameter, kw$p.value))
  cat(sprintf("Mann-Whitney fog vs dew: p = %.2e, effect size r = %.3f\n", wt_fd$p.value, r_fd))
  cat(sprintf("Mann-Whitney dew vs no occurrence: p = %.2e, effect size r = %.3f\n", wt_dn$p.value, r_dn))

  # --- Seasonal values (mean per category, same criterion as the annual one) ---
  boot_fog <- bootstrap_mean(x_fog)
  boot_dew <- bootstrap_mean(x_dew)
  v_fog_s <- boot_fog["mean"]
  v_dew_s <- boot_dew["mean"]
  cat(sprintf("Fog value (mean, 95%% bootstrap CI) = %.6f [%.6f, %.6f] K/m, n = %d\n",
              v_fog_s, boot_fog["ci_low"], boot_fog["ci_high"], length(x_fog)))
  cat(sprintf("Dew value (mean, 95%% bootstrap CI) = %.6f [%.6f, %.6f] K/m, n = %d\n",
              v_dew_s, boot_dew["ci_low"], boot_dew["ci_high"], length(x_dew)))
  cat(sprintf("No-occurrence mean (reference)    = %.6f K/m, n = %d\n", mean(x_none), length(x_none)))

  # --- ROC/AUC validation (independent of the mean criterion) ---
  d_roc_fd <- d_s %>% filter(clasif_evento %in% c("NIEBLA", "ROCIO")) %>% mutate(is_dew = clasif_evento == "ROCIO")
  auc_fd <- as.numeric(auc(roc(d_roc_fd$is_dew, d_roc_fd$grad_theta, quiet = TRUE)))

  d_roc_dn <- d_s %>% filter(clasif_evento %in% c("ROCIO", "SIN_EVENTO")) %>% mutate(is_none = clasif_evento == "SIN_EVENTO")
  auc_dn <- as.numeric(auc(roc(d_roc_dn$is_none, d_roc_dn$grad_theta, quiet = TRUE)))
  cat(sprintf("AUC fog vs dew = %.3f | AUC dew vs no occurrence = %.3f\n", auc_fd, auc_dn))

  # --- 3-class accuracy: seasonal values vs fixed annual values ---
  pred_seasonal <- classify_3(d_s$grad_theta, v_fog_s, v_dew_s)
  pred_annual   <- classify_3(d_s$grad_theta, annual_fog, annual_dew)
  acc_seasonal <- mean(pred_seasonal == d_s$clasif_evento)
  acc_annual   <- mean(pred_annual == d_s$clasif_evento)
  cat(sprintf("3-class accuracy with the SEASONAL values             = %.1f%%\n", 100 * acc_seasonal))
  cat(sprintf("3-class accuracy with the fixed ANNUAL values (0.0026/0.0034) = %.1f%%\n", 100 * acc_annual))

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

# ------------------------------------------------------------------------------
# 3. SUMMARY TABLE
# ------------------------------------------------------------------------------
cat("\n================ 3. Summary: seasonal dtheta/dz values (OYA1211) ================\n")
print(seasonal_results, width = Inf)

dir.create("results", showWarnings = FALSE)
output_file <- "results/seasonal_dtheta_dz_values.csv"
write_csv(seasonal_results, output_file)
cat(sprintf("\nTable saved to: %s\n", output_file))
