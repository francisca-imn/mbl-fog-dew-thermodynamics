# ==============================================================================
# calculos_finales.R
#
# Cálculos estadísticos adicionales solicitados por el comité de tesis
# (observaciones_comite.docx) para borrador_escrito_claude_v05.qmd. Reutiliza
# la misma lógica de carga/derivación de variables que app/global.R (grad_theta,
# grad_q, grad_u, tasas de cambio dq_dt/dth_dt/dws_dt), para que los números
# aquí reportados sean consistentes con los ya usados en el resto de la tesis
# y con la app Shiny.
#
# Puntos del comité que este script responde:
#   1. Validación independiente del rocío vía T_sup <= T_rocío (OYA_1211).
#   2. Pruebas estadísticas formales (Mann-Whitney / Kruskal-Wallis) para las
#      comparaciones descritas cualitativamente en el texto (HR, Δθ/Δz,
#      Δq/Δz, ΔU/Δz, Δθ/Δt, Δq/Δt, ΔU/Δt).
#   3. Capacidad predictiva (accuracy/AUC/Youden) del umbral propio de
#      Δθ/Δz frente a la etiqueta Visibilidad+GOES.
#   6. Intervalo de confianza bootstrap de la mediana de Δq/Δt en rocío.
#   Detalles menores: N por categoría (Fig. 9 y Fig. 12).
# ==============================================================================

library(tidyverse)
library(lubridate)
library(pROC)

set.seed(20260712)

# NOTA: no se usa temp_sup_c para validar independientemente el criterio
# T_superficie <= T_rocío (pedido inicial del comité en su punto 1), porque
# temp_sup_c es la temperatura superficial del SUELO (sensor infrarrojo de
# suelo en OYA_1211), no la temperatura de la placa del colector de rocío
# (SDC). Usarla como proxy del SDC introduciría un sesgo sistemático (masa
# térmica y emisividad distintas), por lo que este punto se responde en el
# texto como limitación metodológica en vez de como test estadístico.

clasif_1211 <- read_csv(
  "data/data_oyarbide_1211_clasificacion_fog-dew_20260308.csv",
  show_col_types = FALSE
)

# ------------------------------------------------------------------------------
# 1. HUMEDAD RELATIVA (HR): TEST FORMAL NIEBLA vs ROCÍO EN OYA_1211
# ------------------------------------------------------------------------------
cat("\n================ 1. Test formal HR (humedad) niebla vs rocío ================\n")

hr_niebla <- clasif_1211$humedad[clasif_1211$clasif_evento == "NIEBLA"]
hr_rocio  <- clasif_1211$humedad[clasif_1211$clasif_evento == "ROCIO"]

cat(sprintf("n(niebla) = %d, mediana = %.1f%%; n(rocio) = %d, mediana = %.1f%%\n",
            sum(!is.na(hr_niebla)), median(hr_niebla, na.rm = TRUE),
            sum(!is.na(hr_rocio)), median(hr_rocio, na.rm = TRUE)))

wilcox_hr <- wilcox.test(hr_niebla, hr_rocio, conf.int = TRUE)
print(wilcox_hr)

# Tamaño de efecto (r = Z / sqrt(N)) a partir del estadístico W. Con N en los
# miles, un test de Wilcoxon detecta como "significativas" diferencias de
# mediana mínimas; el efecto r es el que informa si esa diferencia es grande
# o trivial en términos prácticos (Cohen: ~0.1 pequeño, ~0.3 medio, ~0.5 grande).
efecto_r_wilcox <- function(w_test, n1, n2) {
  mu_w <- n1 * n2 / 2
  sigma_w <- sqrt(n1 * n2 * (n1 + n2 + 1) / 12)
  z <- (w_test$statistic - mu_w) / sigma_w
  abs(as.numeric(z)) / sqrt(n1 + n2)
}
n1 <- sum(!is.na(hr_niebla)); n2 <- sum(!is.na(hr_rocio))
cat(sprintf("Efecto r de Wilcoxon (HR) = %.3f\n", efecto_r_wilcox(wilcox_hr, n1, n2)))

# ------------------------------------------------------------------------------
# 2. GRADIENTES VERTICALES (Δθ/Δz, Δq/Δz, ΔU/Δz) — REPLICA app/global.R
# ------------------------------------------------------------------------------
cat("\n================ 2. Gradientes verticales: carga y derivación ================\n")

theta_q <- read_csv(
  "data/data_oyarbide_aeropuerto_clasificada_theta_q_20260308.csv",
  show_col_types = FALSE
)

theta_data <- theta_q %>%
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

# --- N por categoría para pie de Fig. 9 (transecta completa, todas las
#     estaciones, excluyendo la fila trivial de AEROPUERTO z=48) ---
n_fig9_transecta <- theta_data %>%
  filter(z_m != 48, clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
  filter(!is.na(grad_theta)) %>%
  count(clasif_evento, name = "n_theta")
cat("\nN por categoría (Fig. 9, gradientes, toda la transecta, panel theta):\n")
print(n_fig9_transecta)

# --- N por categoría específicamente en la estación de anclaje OYA_1211 ---
n_fig9_1211 <- theta_data %>%
  filter(estacion == "OYA_1211", clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
  filter(!is.na(grad_theta)) %>%
  count(clasif_evento, name = "n_theta_1211")
cat("\nN por categoría (OYA_1211 solamente):\n")
print(n_fig9_1211)

# --- N específico para OYA_1069 (disponibilidad reducida, nota del comité) ---
n_oya1069 <- theta_data %>%
  filter(estacion == "OYA_1069", clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO")) %>%
  summarise(
    n_total = n(),
    n_grad_theta_valido = sum(!is.na(grad_theta)),
    n_grad_q_valido = sum(!is.na(grad_q)),
    n_grad_u_valido = sum(!is.na(grad_u))
  )
cat("\nDisponibilidad de gradientes en OYA_1069 (nota del comité sobre incertidumbre):\n")
print(n_oya1069)

# ------------------------------------------------------------------------------
# 3. TESTS FORMALES: Δθ/Δz, Δq/Δz, ΔU/Δz (niebla vs rocío vs sin-evento)
# ------------------------------------------------------------------------------
cat("\n================ 3. Tests formales de gradientes verticales ================\n")

test_gradiente <- function(data, var, label, filtro_estacion = NULL) {
  d <- data %>% filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"), z_m != 48)
  if (!is.null(filtro_estacion)) d <- d %>% filter(estacion == filtro_estacion)
  d <- d %>% filter(!is.na(.data[[var]]))

  kw <- kruskal.test(d[[var]], d$clasif_evento)
  x1 <- d[[var]][d$clasif_evento == "NIEBLA"]
  x2 <- d[[var]][d$clasif_evento == "ROCIO"]
  wt_nr <- wilcox.test(x1, x2)
  r_ef <- efecto_r_wilcox(wt_nr, length(x1), length(x2))

  cat(sprintf("\n--- %s%s ---\n", label,
              ifelse(is.null(filtro_estacion), " (transecta completa)", paste0(" (", filtro_estacion, ")"))))
  cat(sprintf("Kruskal-Wallis (3 grupos): chi2 = %.2f, df = %d, p = %.2e\n",
              kw$statistic, kw$parameter, kw$p.value))
  cat(sprintf("Mann-Whitney niebla vs rocío: W = %.0f, p = %.2e, efecto r = %.3f\n",
              wt_nr$statistic, wt_nr$p.value, r_ef))
  medianas <- d %>% group_by(clasif_evento) %>%
    summarise(mediana = median(.data[[var]]), n = n(), .groups = "drop")
  print(medianas)
  invisible(list(kw = kw, wt = wt_nr, medianas = medianas, r = r_ef))
}

res_theta_transecta <- test_gradiente(theta_data, "grad_theta", "Δθ/Δz")
res_theta_1211       <- test_gradiente(theta_data, "grad_theta", "Δθ/Δz", "OYA_1211")
res_q_transecta      <- test_gradiente(theta_data, "grad_q", "Δq/Δz")
res_u_transecta       <- test_gradiente(theta_data, "grad_u", "ΔU/Δz")

# ------------------------------------------------------------------------------
# 4. UMBRAL PROPIO DE Δθ/Δz: DERIVACIÓN Y CAPACIDAD PREDICTIVA (ROC/YOUDEN)
# ------------------------------------------------------------------------------
cat("\n================ 4. Derivación y capacidad predictiva del umbral Δθ/Δz (OYA_1211) ================\n")

d_roc <- theta_data %>%
  filter(estacion == "OYA_1211", clasif_evento %in% c("NIEBLA", "ROCIO")) %>%
  filter(!is.na(grad_theta)) %>%
  mutate(es_rocio = clasif_evento == "ROCIO")

# Definición simétrica y reproducible de ambos umbrales: la media de Δθ/Δz de
# cada categoría en la estación de anclaje (mismo criterio para niebla y para
# rocío, no solo para niebla).
media_fog_1211   <- mean(d_roc$grad_theta[!d_roc$es_rocio])
media_rocio_1211 <- mean(d_roc$grad_theta[d_roc$es_rocio])
cat(sprintf("Umbral niebla (media Δθ/Δz en niebla, OYA_1211)  = %.6f K/m\n", media_fog_1211))
cat(sprintf("Umbral rocío  (media Δθ/Δz en rocío,  OYA_1211)  = %.6f K/m\n", media_rocio_1211))

roc_obj <- roc(response = d_roc$es_rocio, predictor = d_roc$grad_theta, quiet = TRUE)
auc_val <- as.numeric(auc(roc_obj))
youden <- coords(roc_obj, "best", best.method = "youden",
                  ret = c("threshold", "sensitivity", "specificity", "accuracy"))
cat(sprintf("AUC = %.3f\n", auc_val))
cat("Punto de corte óptimo (Youden):\n")
print(youden)

# Accuracy del umbral efectivamente usado en el texto/figuras (0.0026 K/m)
umbral_texto <- 0.0026
pred_texto <- ifelse(d_roc$grad_theta < umbral_texto, "NIEBLA", "ROCIO")
acc_texto <- mean(pred_texto == d_roc$clasif_evento)
tab_texto <- table(Predicho = pred_texto, Real = d_roc$clasif_evento)
cat(sprintf("\nAccuracy del umbral 0.0026 K/m (niebla si Δθ/Δz < 0.0026) frente a Visibilidad+GOES = %.1f%%\n", 100 * acc_texto))
print(tab_texto)

# --- Umbral propio de Δq/Δz (mismo criterio: media por categoría en OYA_1211) ---
d_q_1211 <- theta_data %>%
  filter(estacion == "OYA_1211", clasif_evento %in% c("NIEBLA", "ROCIO")) %>%
  filter(!is.na(grad_q))
media_q_fog_1211   <- mean(d_q_1211$grad_q[d_q_1211$clasif_evento == "NIEBLA"])
mediana_q_fog_1211 <- median(d_q_1211$grad_q[d_q_1211$clasif_evento == "NIEBLA"])
media_q_rocio_1211   <- mean(d_q_1211$grad_q[d_q_1211$clasif_evento == "ROCIO"])
mediana_q_rocio_1211 <- median(d_q_1211$grad_q[d_q_1211$clasif_evento == "ROCIO"])
cat(sprintf("\nUmbral Δq/Δz niebla (OYA_1211): media = %.6f, mediana = %.6f g/kg/m\n",
            media_q_fog_1211, mediana_q_fog_1211))
cat(sprintf("Umbral Δq/Δz rocío  (OYA_1211): media = %.6f, mediana = %.6f g/kg/m\n",
            media_q_rocio_1211, mediana_q_rocio_1211))
cat(sprintf("Umbral general propuesto (media de ambas categorías, OYA_1211) = %.6f g/kg/m (vs. -0.0016 de LobosRoco2018)\n",
            mean(c(media_q_fog_1211, media_q_rocio_1211))))

# ------------------------------------------------------------------------------
# 5. TASAS DE CAMBIO TEMPORAL (Δφ/Δt) — REPLICA EXACTA DE app/global.R
#    (tolerancia 1-3h, lag_max = 18, usada en Fig. 12 / fig-rates-distribution)
# ------------------------------------------------------------------------------
cat("\n================ 5. Tasas de cambio temporal (tolerancia 1-3h) ================\n")

dat_1211_temporal <- theta_data %>%
  filter(estacion == "OYA_1211") %>%
  arrange(datetime)

buscar_gradiente <- function(i, var_vec, time_vec, lag_min = 6, lag_max) {
  for (lag in lag_min:lag_max) {
    j <- i + lag
    if (j <= length(var_vec) && !is.na(var_vec[j])) {
      dt_hours <- as.numeric(difftime(time_vec[j], time_vec[i], units = "hours"))
      return((var_vec[j] - var_vec[i]) / dt_hours)
    }
  }
  NA_real_
}

time_vec <- dat_1211_temporal$datetime

tasa_cambio <- function(lag_max) {
  tibble(
    dq_dt  = sapply(seq_along(dat_1211_temporal$q_gkg), buscar_gradiente,
                     var_vec = dat_1211_temporal$q_gkg, time_vec = time_vec, lag_max = lag_max),
    dth_dt = sapply(seq_along(dat_1211_temporal$theta_K), buscar_gradiente,
                     var_vec = dat_1211_temporal$theta_K, time_vec = time_vec, lag_max = lag_max),
    dws_dt = sapply(seq_along(dat_1211_temporal$viento_vel_m_s), buscar_gradiente,
                     var_vec = dat_1211_temporal$viento_vel_m_s, time_vec = time_vec, lag_max = lag_max)
  )
}

dat_box <- dat_1211_temporal %>%
  select(clasif_evento) %>%
  bind_cols(tasa_cambio(lag_max = 18)) %>%
  filter(clasif_evento %in% c("NIEBLA", "ROCIO", "SIN_EVENTO"))

# Recorte de outliers 1.5*IQR por variable/categoría, igual que dat_box de global.R
recortar_iqr <- function(df, var) {
  df %>%
    group_by(clasif_evento) %>%
    mutate(Q1 = quantile(.data[[var]], 0.25, na.rm = TRUE),
           Q3 = quantile(.data[[var]], 0.75, na.rm = TRUE),
           IQR = Q3 - Q1) %>%
    filter(.data[[var]] >= Q1 - 1.5 * IQR, .data[[var]] <= Q3 + 1.5 * IQR) %>%
    ungroup()
}

# --- N por categoría para pie de Fig. 12 ---
n_fig12 <- dat_box %>%
  filter(!is.na(dq_dt)) %>%
  count(clasif_evento, name = "n_dqdt")
cat("\nN por categoría (Fig. 12, tasas de cambio, tras recorte de outliers 1.5xIQR):\n")
print(n_fig12)

test_tasa <- function(var, label) {
  d <- recortar_iqr(dat_box %>% filter(!is.na(.data[[var]])), var)
  kw <- kruskal.test(d[[var]], d$clasif_evento)
  x1 <- d[[var]][d$clasif_evento == "NIEBLA"]
  x2 <- d[[var]][d$clasif_evento == "ROCIO"]
  wt_nr <- wilcox.test(x1, x2, conf.int = TRUE)
  r_ef <- efecto_r_wilcox(wt_nr, length(x1), length(x2))
  cat(sprintf("\n--- %s ---\n", label))
  cat(sprintf("Kruskal-Wallis (3 grupos): chi2 = %.2f, df = %d, p = %.2e\n",
              kw$statistic, kw$parameter, kw$p.value))
  cat(sprintf("Mann-Whitney niebla vs rocío: W = %.0f, p = %.2e, efecto r = %.3f, diff. mediana IC95%% = [%.3f, %.3f]\n",
              wt_nr$statistic, wt_nr$p.value, r_ef, wt_nr$conf.int[1], wt_nr$conf.int[2]))
  medianas <- d %>% group_by(clasif_evento) %>%
    summarise(mediana = round(median(.data[[var]]), 3), n = n(), .groups = "drop")
  print(medianas)
  invisible(list(kw = kw, wt = wt_nr, data = d))
}

res_dq_dt  <- test_tasa("dq_dt", "Δq/Δt (g/kg por hora)")
res_dth_dt <- test_tasa("dth_dt", "Δθ/Δt (K por hora)")
res_dws_dt <- test_tasa("dws_dt", "ΔU/Δt (m/s por hora)")

# ------------------------------------------------------------------------------
# 6. BOOTSTRAP CI: MEDIANA DE Δq/Δt EN ROCÍO
# ------------------------------------------------------------------------------
cat("\n================ 6. Bootstrap CI mediana Δq/Δt (rocío) ================\n")

dq_dt_rocio_clean <- res_dq_dt$data$dq_dt[res_dq_dt$data$clasif_evento == "ROCIO"]
dq_dt_niebla_clean <- res_dq_dt$data$dq_dt[res_dq_dt$data$clasif_evento == "NIEBLA"]

bootstrap_mediana <- function(x, R = 10000) {
  meds <- replicate(R, median(sample(x, length(x), replace = TRUE)))
  c(mediana = median(x),
    ci_low  = quantile(meds, 0.025, names = FALSE),
    ci_high = quantile(meds, 0.975, names = FALSE))
}

boot_rocio  <- bootstrap_mediana(dq_dt_rocio_clean)
boot_niebla <- bootstrap_mediana(dq_dt_niebla_clean)

cat(sprintf("Rocío:  mediana Δq/Δt = %.3f g/kg/h, IC95%% bootstrap = [%.3f, %.3f], n = %d\n",
            boot_rocio["mediana"], boot_rocio["ci_low"], boot_rocio["ci_high"], length(dq_dt_rocio_clean)))
cat(sprintf("Niebla: mediana Δq/Δt = %.3f g/kg/h, IC95%% bootstrap = [%.3f, %.3f], n = %d\n",
            boot_niebla["mediana"], boot_niebla["ci_low"], boot_niebla["ci_high"], length(dq_dt_niebla_clean)))
cat(sprintf("Valor previamente reportado por Lobos-Roco et al. (2024) para rocío: -0.25 g/kg/h -> %s del IC95%% bootstrap de este estudio\n",
            ifelse(-0.25 < boot_rocio["ci_low"] | -0.25 > boot_rocio["ci_high"], "FUERA", "DENTRO")))

# ------------------------------------------------------------------------------
# 7. RESUMEN FINAL (para copiar cifras clave al texto)
# ------------------------------------------------------------------------------
cat("\n================ RESUMEN DE CIFRAS CLAVE ================\n")
cat(sprintf("1) HR niebla vs rocio: Mann-Whitney p = %.2e, mediana niebla = %.1f%%, mediana rocio = %.1f%%, efecto r = %.3f\n",
            wilcox_hr$p.value, median(hr_niebla, na.rm = TRUE), median(hr_rocio, na.rm = TRUE),
            efecto_r_wilcox(wilcox_hr, n1, n2)))
cat(sprintf("3) Umbrales Delta-theta/Delta-z (media por categoria, OYA_1211): niebla = %.4f, rocio = %.4f K/m\n",
            media_fog_1211, media_rocio_1211))
cat(sprintf("4) AUC umbral Delta-theta/Delta-z = %.3f; accuracy umbral 0.0026 = %.1f%%\n", auc_val, 100 * acc_texto))
cat(sprintf("6) Rocio dq/dt mediana = %.3f [%.3f, %.3f] g/kg/h (bootstrap 95%%)\n",
            boot_rocio["mediana"], boot_rocio["ci_low"], boot_rocio["ci_high"]))

