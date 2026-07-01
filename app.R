# ==============================================================================
# APLICACIÓN SHINY: Disponibilidad de Datos Oyarbide (Año 2024)
# Autora: Francisca Muñoz Narbona
# Tesis: Caracterización termodinámica de la capa límite marina...
# Institución: Facultad de Agronomía y Sistemas Naturales (FASINA) - PUC
# ==============================================================================

library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(DT)
library(lubridate)
library(scales)
library(viridisLite)

# --- CONFIGURACIÓN DE RECURSOS ---
addResourcePath(prefix = "raiz", directoryPath = getwd())

# ------------------------------------------------------------------------------
# 1. CARGA Y PREPROCESAMIENTO DE DATOS
# ------------------------------------------------------------------------------
cargar_datos_sistema <- function() {
  oya518  <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_518_2024-2025.csv")
  oya780  <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_780_2024-2025.csv")
  oya862  <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_862_2024-2025.csv")
  oya1069 <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_1069_2024-2025.csv")
  oya1128 <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_1128_2024-2025.csv")
  oya1193 <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_1193_2024-2025.csv")
  oya1211 <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_1211_2024-2025.csv")
  oya1354 <- read_csv("data/oyarbide_procesado_2024-2025_v02/oya_1354_2024-2025.csv")
  
  aeropuerto <- read_csv("data/aeropuerto/datos_2024_10min_aeropuerto.csv")
  aer_viento <- read_delim("data/aeropuerto/200006_2024_Viento_.csv", delim = ";") %>% 
    select(Instante, ff) %>% 
    rename(FechaHora_10min = Instante) %>% 
    mutate(viento_vel_m_s = ff * 0.51444) %>% 
    select(-ff)
  
  aeropuerto <- aeropuerto %>% left_join(aer_viento, by = "FechaHora_10min")
  
  goes <- read_csv("data/GOES/goes_app/oya24/FLC/FLC_OYA1_2024.csv") %>%
    rename(datetime = `...1`) %>%
    transmute(datetime = as.POSIXct(datetime, tz = "UTC"),
              FLC = FLC,
              estacion = "GOES") %>%
    pivot_longer(cols = FLC, names_to = "variable", values_to = "valor") %>%
    filter(year(datetime) == 2024)
  
  oya518_sel <- oya518 %>% transmute(datetime, temperatura = luft_temperatur_c, presion = luft_druck_h_pa, niebla_ml = niederschlag_nebelwasser_ml, pp_mm = niederschlag_menge_mm, estacion = "OYA_518", radiacion_w_m2 = strahlung_global_w_m2, humedad = luft_feuchte_percent, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, temp_sup_c = oberflaeche_temperatur_1_c)
  oya780_sel <- oya780 %>% transmute(datetime, humedad = luft_feuchte_percent, temperatura = luft_temperatur_c, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, presion = luft_druck_h_pa, niebla_mm = niederschlag_nebelwasser_mm, estacion = "OYA_780")
  oya862_sel <- oya862 %>% transmute(datetime, temperatura = luft_temperatur_c, humedad = luft_feuchte_percent, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, niebla_ml = niederschlag_nebelwasser_ml, estacion = "OYA_862")
  oya1069_sel <- oya1069 %>% transmute(datetime, temperatura = luft_temperatur_c, humedad = luft_feuchte_percent, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, niebla_ml = niederschlag_nebelwasser_ml, estacion = "OYA_1069")
  oya1128_sel <- oya1128 %>% transmute(datetime, temperatura = luft_temperatur_c, humedad = luft_feuchte_percent, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, niebla_mm = niederschlag_nebelwasser_mm, niebla_ml = niederschlag_nebelwasser_ml, estacion = "OYA_1128")
  oya1193_sel <- oya1193 %>% transmute(datetime, temperatura = luft_temperatur_c, humedad = luft_feuchte_percent, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, niebla_mm = niederschlag_nebelwasser_mm, niebla_ml = niederschlag_nebelwasser_ml, estacion = "OYA_1193")
  oya1211_sel <- oya1211 %>% transmute(datetime, temperatura = luft_temperatur_c, humedad = luft_feuchte_percent, presion = luft_druck_h_pa, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, radiacion_w_m2 = strahlung_global_w_m2, temp_suelo_50cm_c = boden_temperatur_50cm_c, visibilidad = strahlung_sichtweite_m, temp_hum_10cm = boden_feuchte_10cm_percent, temp_suelo_10cm_c = boden_temperatur_10cm_c, temp_hum_20cm = boden_feuchte_20cm_percent, temp_suelo_20c_c = boden_temperatur_20cm_c, temp_sup_c = oberflaeche_temperatur_c, niebla_mm = niederschlag_nebelwasser_mm, niebla_ml = niederschlag_nebelwasser_ml, rocio_mm = niederschlag_tauwasser_mm, rocio_ml = niederschlag_tauwasser_ml, estacion = "OYA_1211")
  oya1354_sel <- oya1354 %>% transmute(datetime, temperatura = luft_temperatur_c, humedad = luft_feuchte_percent, viento_vel_m_s = wind_geschwindigkeit_m_s, viento_dir = wind_richtung, niebla_mm = niederschlag_nebelwasser_mm, niebla_ml = niederschlag_nebelwasser_ml, estacion = "OYA_1354")
  aeropuerto_sel <- aeropuerto %>% transmute(datetime = FechaHora_10min, temperatura = ts, presion = qnh, humedad = hr, viento_vel_m_s = viento_vel_m_s, visibilidad = NA_real_, estacion = "AEROPUERTO")
  
  meteo_all <- bind_rows(oya518_sel, oya780_sel, oya862_sel, oya1069_sel, oya1128_sel, oya1193_sel, oya1211_sel, oya1354_sel, aeropuerto_sel)
  
  meteo_long <- meteo_all %>%
    mutate(niebla_final = coalesce(niebla_mm, niebla_ml), rocio_final = coalesce(rocio_mm, rocio_ml)) %>%
    pivot_longer(cols = -c(datetime, estacion), names_to = "variable", values_to = "valor") %>%
    filter(year(datetime) == 2024) %>%
    mutate(valor = case_when(
      variable == "temperatura" & valor == 0 ~ NA_real_,
      variable == "presion" & valor == 0 ~ NA_real_,
      variable == "viento_vel_m_s" & valor == 0 ~ NA_real_,
      variable == "visibilidad" & valor < 0.4 ~ NA_real_,
      TRUE ~ valor
    ))
  
  return(bind_rows(meteo_long, goes))
}

meteo_data <- cargar_datos_sistema()

transecta_df <- tibble(
  estacion = c("AEROPUERTO", "OYA_518", "OYA_780", "OYA_862", "OYA_1069", "OYA_1128", "OYA_1193", "OYA_1211", "OYA_1354"),
  altitud = c(0, 518, 780, 862, 1069, 1128, 1193, 1211, 1354)
) %>% 
  mutate(color_pto = ifelse(estacion == "OYA_1211", "#1d4ed8", "#64748b"),
         tam_pto = ifelse(estacion == "OYA_1211", 5, 2.5))

# TABLA DE CORRECCIONES MANUALES ORIGINALES
correcciones_manual <- tribble(
  ~inicio, ~fin, ~evento,
  ymd_hms("2024-01-02 02:00:00", tz = "UTC"), ymd_hms("2024-01-02 03:30:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-01-02 10:00:00", tz = "UTC"), ymd_hms("2024-01-02 12:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-01-08 10:00:00", tz = "UTC"), ymd_hms("2024-01-08 12:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-01-11 03:00:00", tz = "UTC"), ymd_hms("2024-01-11 06:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-01-15 09:00:00", tz = "UTC"), ymd_hms("2024-01-15 12:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-02-03 02:00:00", tz = "UTC"), ymd_hms("2024-02-03 05:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-01-28 12:00:00", tz = "UTC"), ymd_hms("2024-01-28 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-01-31 09:00:00", tz = "UTC"), ymd_hms("2024-01-31 22:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-02-03 07:00:00", tz = "UTC"), ymd_hms("2024-02-03 11:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-02-04 02:00:00", tz = "UTC"), ymd_hms("2024-02-04 12:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-02-12 06:00:00", tz = "UTC"), ymd_hms("2024-02-12 10:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-02-17 05:00:00", tz = "UTC"), ymd_hms("2024-02-17 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-02-18 11:00:00", tz = "UTC"), ymd_hms("2024-02-18 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-02-19 04:00:00", tz = "UTC"), ymd_hms("2024-02-19 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-02-28 10:00:00", tz = "UTC"), ymd_hms("2024-02-28 13:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-03-07 08:00:00", tz = "UTC"), ymd_hms("2024-03-07 14:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-03-09 01:00:00", tz = "UTC"), ymd_hms("2024-03-09 13:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-03-09 08:00:00", tz = "UTC"), ymd_hms("2024-03-09 15:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-03-13 04:00:00", tz = "UTC"), ymd_hms("2024-03-13 16:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-03-16 06:00:00", tz = "UTC"), ymd_hms("2024-03-16 08:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-03-24 14:00:00", tz = "UTC"), ymd_hms("2024-03-24 16:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-03-25 02:00:00", tz = "UTC"), ymd_hms("2024-03-25 15:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-03-26 07:00:00", tz = "UTC"), ymd_hms("2024-03-26 09:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-03-26 11:00:00", tz = "UTC"), ymd_hms("2024-03-26 14:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-02 08:00:00", tz = "UTC"), ymd_hms("2024-04-02 14:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-07 00:00:00", tz = "UTC"), ymd_hms("2024-04-07 04:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-04-07 06:00:00", tz = "UTC"), ymd_hms("2024-04-07 15:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-08 00:00:00", tz = "UTC"), ymd_hms("2024-04-08 04:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-04-09 09:00:00", tz = "UTC"), ymd_hms("2024-04-09 11:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-04-11 00:00:00", tz = "UTC"), ymd_hms("2024-04-13 03:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-13 08:00:00", tz = "UTC"), ymd_hms("2024-04-13 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-15 06:00:00", tz = "UTC"), ymd_hms("2024-04-15 07:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-22 14:00:00", tz = "UTC"), ymd_hms("2024-04-22 23:50:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-23 04:00:00", tz = "UTC"), ymd_hms("2024-04-23 06:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-04-27 00:00:00", tz = "UTC"), ymd_hms("2024-04-27 14:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-04-28 04:00:00", tz = "UTC"), ymd_hms("2024-04-28 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-05-04 00:00:00", tz = "UTC"), ymd_hms("2024-05-04 05:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-05-05 00:00:00", tz = "UTC"), ymd_hms("2024-05-05 03:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-05-07 03:00:00", tz = "UTC"), ymd_hms("2024-05-07 12:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-05-08 00:00:00", tz = "UTC"), ymd_hms("2024-05-08 01:30:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-05-11 00:00:00", tz = "UTC"), ymd_hms("2024-05-11 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-05-13 00:00:00", tz = "UTC"), ymd_hms("2024-05-13 16:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-05-16 00:00:00", tz = "UTC"), ymd_hms("2024-05-16 12:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-05-18 00:00:00", tz = "UTC"), ymd_hms("2024-05-19 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-06-09 00:00:00", tz = "UTC"), ymd_hms("2024-06-09 23:50:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-07-08 00:00:00", tz = "UTC"), ymd_hms("2024-07-08 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-07-11 00:00:00", tz = "UTC"), ymd_hms("2024-07-11 05:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-07-18 00:00:00", tz = "UTC"), ymd_hms("2024-07-18 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-08-22 06:00:00", tz = "UTC"), ymd_hms("2024-08-22 07:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-08-30 00:00:00", tz = "UTC"), ymd_hms("2024-08-30 08:30:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-08-31 00:00:00", tz = "UTC"), ymd_hms("2024-08-31 12:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-09-13 00:00:00", tz = "UTC"), ymd_hms("2024-09-13 08:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-10-08 00:00:00", tz = "UTC"), ymd_hms("2024-10-08 14:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-10-08 16:00:00", tz = "UTC"), ymd_hms("2024-10-08 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-10-10 00:00:00", tz = "UTC"), ymd_hms("2024-10-10 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-10-19 00:00:00", tz = "UTC"), ymd_hms("2024-10-19 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-10-21 00:00:00", tz = "UTC"), ymd_hms("2024-10-21 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-10-31 00:00:00", tz = "UTC"), ymd_hms("2024-10-31 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-11-01 00:00:00", tz = "UTC"), ymd_hms("2024-11-01 08:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-11-01 12:00:00", tz = "UTC"), ymd_hms("2024-11-01 23:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-11-02 00:00:00", tz = "UTC"), ymd_hms("2024-11-02 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-11-07 00:00:00", tz = "UTC"), ymd_hms("2024-11-07 23:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-11-08 00:00:00", tz = "UTC"), ymd_hms("2024-11-08 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-11-09 00:00:00", tz = "UTC"), ymd_hms("2024-11-09 05:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-11-09 12:00:00", tz = "UTC"), ymd_hms("2024-11-09 23:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-11-13 00:00:00", tz = "UTC"), ymd_hms("2024-11-13 23:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-11-15 00:00:00", tz = "UTC"), ymd_hms("2024-11-15 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-11-25 00:00:00", tz = "UTC"), ymd_hms("2024-11-25 05:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-11-27 10:00:00", tz = "UTC"), ymd_hms("2024-11-27 23:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-11-29 00:00:00", tz = "UTC"), ymd_hms("2024-11-29 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-12-03 09:00:00", tz = "UTC"), ymd_hms("2024-12-03 23:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-12-19 00:00:00", tz = "UTC"), ymd_hms("2024-12-19 13:00:00", tz = "UTC"), "NIEBLA",
  ymd_hms("2024-12-23 00:00:00", tz = "UTC"), ymd_hms("2024-12-23 23:00:00", tz = "UTC"), "ROCIO",
  ymd_hms("2024-12-28 02:00:00", tz = "UTC"), ymd_hms("2024-12-28 06:00:00", tz = "UTC"), "ROCIO"
)

# ------------------------------------------------------------------------------
# 2. INTERFAZ DE USUARIO (UI)
# ------------------------------------------------------------------------------
ui <- dashboardPage(
  skin = "blue", 
  dashboardHeader(title = "Tesis: Datos"),
  
  dashboardSidebar(
    div(style = "background-color: #ffffff; padding: 16px 12px; text-align: center; border-bottom: 1px solid #e2e8f0;",
        img(src = "raiz/logo_fasina.png", style = "width: 95%; max-height: 50px; object-fit: contain;")
    ),
    
    sidebarMenu(
      menuItem("Resumen y Transecta", tabName = "resumen", icon = icon("layer-group")),
      menuItem("Datos Disponibles", tabName = "datos_dispo", icon = icon("chart-bar")),
      menuItem("Reclasificación Manual", tabName = "reclasif", icon = icon("edit")),
      menuItem("Cap. 2: Perfiles Verticales", tabName = "cap2_perfiles", icon = icon("layer-group"))
    ),
    
    div(style = "padding: 15px; font-size: 11px; color: #475569; background-color: #f8fafc; position: relative; width: 100%; border-top: 1px solid #e2e8f0; margin-top: 30px;",
        p(style = "margin-bottom: 2px; font-size: 9px; text-transform: uppercase; letter-spacing: 0.5px; color: #0284c7; font-weight: 600;", "Investigadora:"),
        strong(style = "color: #0f172a; font-size: 12px;", "Francisca Muñoz Narbona"),
        p(style = "margin-top: 8px; margin-bottom: 2px; font-size: 9px; text-transform: uppercase; color: #0284c7; font-weight: 600;", "Programa:"),
        p(style = "color: #334155; margin-bottom: 0; font-size: 10px; line-height: 1.2;", "Magíster en Recursos Naturales"),
        p(style = "color: #64748b; font-size: 9px; margin-top: 3px;", "Facultad de Agronomía y Sistemas Naturales (PUC)")
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap');
      body, .main-sidebar, .main-header .logo, h1, h2, h3, h4, h5, .box-title {
        font-family: 'Inter', sans-serif !important;
      }
      .skin-blue .main-header .navbar { background-color: #0f172a !important; }
      .skin-blue .main-header .logo { background-color: #020617 !important; font-weight: 600; }
      .skin-blue .main-sidebar { background-color: #ffffff !important; border-right: 1px solid #e2e8f0 !important; }
      .skin-blue .sidebar-menu > li > a { color: #475569 !important; font-weight: 500; }
      .skin-blue .sidebar-menu > li.active > a, .skin-blue .sidebar-menu > li:hover > a { background-color: #f0f9ff !important; color: #0284c7 !important; border-left-color: #0284c7 !important; }
      .skin-blue .sidebar-menu > li > a > .fa { color: #64748b !important; }
      .skin-blue .sidebar-menu > li.active > a > .fa, .skin-blue .sidebar-menu > li:hover > a > .fa { color: #0284c7 !important; }
      .box { border-top: 3px solid #0284c7 !important; border-radius: 8px !important; box-shadow: 0 4px 12px rgba(15, 23, 42, 0.04) !important; }
      .box-header .box-title { font-weight: 600 !important; font-size: 15px !important; }
      .content-wrapper { background-color: #f8fafc !important; }
    "))),
    tags$script(HTML("
      // Los widgets de Plotly se dibujan usando el ancho del contenedor en el
      // momento del render. Si ese contenedor está dentro de una pestaña oculta
      // (tabPanel / tabItem / sidebar menuItem), Plotly calcula un ancho muy
      // angosto por defecto y luego no se reajusta solo. Forzamos un evento
      // 'resize' de la ventana cada vez que se muestra una pestaña de Bootstrap
      // o del menú lateral, para que los gráficos (autosize + responsive) se
      // expandan correctamente al ancho real disponible.
      $(document).on('shown.bs.tab', 'a[data-toggle=\"tab\"]', function (e) {
        setTimeout(function() { window.dispatchEvent(new Event('resize')); }, 50);
      });
      $(document).on('click', '.sidebar-menu a', function (e) {
        setTimeout(function() { window.dispatchEvent(new Event('resize')); }, 150);
      });
    ")),
    
    tabItems(
      # --- TAB 1: RESUMEN Y TRANSECTA ---
      tabItem(tabName = "resumen",
              fluidRow(
                box(title = "Transecta Altitudinal de Estaciones", status = "primary", width = 6,
                    plotlyOutput("plot_transecta", height = "350px")),
                box(title = "Marco de la Investigación", status = "primary", width = 6,
                    h5(style = "color: #0f172a; font-weight: 600; margin-top: 0; line-height: 1.4; font-size: 13px;", 
                       "\"Caracterización termodinámica de la capa límite marina bajo eventos de niebla y rocío en el clima hiperárido del desierto costero de Atacama, Chile\""),
                    hr(style = "margin-top: 8px; margin-bottom: 8px; border-top: 1px solid #e2e8f0;"),
                    p(style = "font-size: 12px; color: #475569;", "Estructura de variables metodológicas por capítulos del documento de tesis:"),
                    tags$ul(style = "color: #334155; line-height: 1.5; font-size: 12px; padding-left: 20px;",
                            tags$li(strong("Capítulo 1:"), " Dinámica espacial e ingresos de agua atmosférica mediante análisis de ", strong("Visibilidad, GOES (FLC) y Captadores de Niebla/Rocío.")),
                            tags$li(strong("Capítulos 2 y 3:"), " Perfiles utilizando variables dinámicas estructurales (", strong("Presión, Temperatura y Viento"), ").")
                    ),
                    div(style = "background-color: #f0f9ff; border-left: 4px solid #0284c7; padding: 8px 12px; margin-top: 10px; border-radius: 0 4px 4px 0; font-size: 11.5px;",
                        p(style = "margin: 0; color: #0369a1;", strong("Nota Técnica:"), " La estación ", strong("OYA_1211"), " concentra visibilidad y rocío.")
                    )
                ),
                box(title = "Matriz de Disponibilidad de Datos (%) - Ciclo Completo 2024", status = "primary", width = 12,
                    DTOutput("tabla_disponibilidad"))
              )
      ),
      
      # --- TAB 2: DATOS DISPONIBLES ---
      tabItem(tabName = "datos_dispo",
              fluidRow(
                box(title = "Captación de Niebla Unificada (Final - mm/mL)", status = "primary", width = 6,
                    plotlyOutput("plot_niebla", height = "300px")),
                box(title = "Captación de Rocío Unificada (Final - mm/mL)", status = "primary", width = 6,
                    plotlyOutput("plot_rocio", height = "300px")),
                
                box(title = "Visibilidad Corregida (Filtro < 0.4m eliminado)", status = "primary", width = 6,
                    plotlyOutput("plot_visibilidad", height = "300px")),
                box(title = "GOES - Presencia de Nubes Bajas (FLC)", status = "primary", width = 6,
                    plotlyOutput("plot_goes", height = "300px")),
                
                box(title = "Análisis Temporal Interactivo de la Capa Límite Marina", status = "primary", width = 12,
                    plotlyOutput("plot_dinamico", height = "350px"),
                    hr(style = "margin-top: 15px; margin-bottom: 15px; border-top: 1px solid #cbd5e1;"),
                    fluidRow(
                      column(6, selectInput("var_selector", "Seleccione Variable Física Dinámica:",
                                            choices = c("Temperatura" = "temperatura", "Presión Atmosférica" = "presion", "Humedad Relativa" = "humedad", "Precipitación" = "pp_mm", "Radiación Global" = "radiacion_w_m2", "Velocidad Viento" = "viento_vel_m_s", "Temperatura Superficial" = "temp_sup_c"))),
                      column(6, dateRangeInput("dates_global", "Ventana Temporal de Análisis:", start = "2024-01-01", end = "2024-06-30", min = "2024-01-01", max = "2024-12-31"))
                    )
                )
              )
      ),
      
      # --- TAB 3: RECLASIFICACIÓN MANUAL Y RESÚMENES ANUALES ---
      tabItem(tabName = "reclasif",
              fluidRow(
                box(title = "Selector de Fecha de Validación Pasada (Año 2024)", status = "primary", width = 12,
                    fluidRow(
                      column(4, 
                             dateInput("fecha_inspeccion", "Seleccionar Día:", 
                                       value = "2024-01-28", 
                                       min = "2024-01-01", 
                                       max = "2024-12-31")
                      ),
                      column(4, 
                             div(style = "margin-top: 25px;",
                                 actionButton("prev_day", "", icon = icon("chevron-left"), class = "btn-primary"),
                                 actionButton("next_day", "", icon = icon("chevron-right"), class = "btn-primary")
                             )
                      )
                    )
                ),
                box(title = "Clasificación Inicial (Solo Algorítmica)", status = "warning", width = 6,
                    plotlyOutput("plot_clasif_inicial", height = "300px")),
                box(title = "Clasificación Final (Algorítmica + Manual)", status = "success", width = 6,
                    plotlyOutput("plot_clasif_final", height = "300px"))
              ),
              
              fluidRow(
                box(title = "Estadísticas Anuales y Distribución de Agua (Filtrado: Excluye 01-24 Ene)", status = "primary", width = 12,
                    tabBox(title = "Análisis Resumen", id = "tab_estat", width = 12,
                           tabPanel("Redistribución Anual", 
                                    plotlyOutput("plot_prop_facetas", height = "380px")),
                           tabPanel("Distribución Mensual (Fog vs Dew)", 
                                    plotlyOutput("plot_dist_mensual", height = "380px")),
                           tabPanel("Distribución Diaria (Fog vs Dew)", 
                                    plotlyOutput("plot_dist_diaria", height = "380px"))
                    )
                )
              )
      ),
      
      # --- TAB 4: CAPÍTULO 2 - PERFILES VERTICALES ---
      tabItem(tabName = "cap2_perfiles",
              fluidRow(
                box(title = "Selector de Día - Perfiles Verticales (Año 2024)", status = "primary", width = 12,
                    fluidRow(
                      column(4,
                             dateInput("fecha_cap2", "Seleccionar Día:",
                                       value = "2024-01-28",
                                       min = "2024-01-01",
                                       max = "2024-12-31")
                      ),
                      column(4,
                             div(style = "margin-top: 25px;",
                                 actionButton("prev_day_cap2", "", icon = icon("chevron-left"), class = "btn-primary"),
                                 actionButton("next_day_cap2", "", icon = icon("chevron-right"), class = "btn-primary")
                             )
                      )
                    )
                )
              ),
              
              fluidRow(
                box(title = NULL, width = 12,
                    tabBox(title = "Perfiles Verticales", id = "tab_cap2", width = 12,
                           
                           # --- SUB-TAB: TEMPERATURA POTENCIAL (θ) ---
                           tabPanel("θ — Temperatura Potencial",
                                    fluidRow(
                                      column(12, plotlyOutput("plot_theta_dia", height = "620px"))
                                    ),
                                    fluidRow(
                                      column(12, plotlyOutput("plot_thetagrad_dia", height = "620px"))
                                    ),
                                    hr(),
                                    fluidRow(
                                      column(12, plotlyOutput("plot_thetagrad_promedio", height = "650px"))
                                    )
                           ),
                           
                           # --- SUB-TAB: HUMEDAD ESPECÍFICA (q) ---
                           tabPanel("q — Humedad Específica",
                                    fluidRow(
                                      column(12, plotlyOutput("plot_q_dia", height = "620px"))
                                    ),
                                    fluidRow(
                                      column(12, plotlyOutput("plot_qgrad_dia", height = "620px"))
                                    ),
                                    hr(),
                                    fluidRow(
                                      column(12, plotlyOutput("plot_qgrad_promedio", height = "650px"))
                                    )
                           ),
                           
                           # --- SUB-TAB: VIENTO ---
                           tabPanel("Viento",
                                    fluidRow(
                                      column(12, plotlyOutput("plot_ugrad_promedio", height = "650px"))
                                    )
                           )
                    )
                )
              )
      )
    )
  )
)

# ------------------------------------------------------------------------------
# 3. LÓGICA DEL SERVIDOR (SERVER)
# ------------------------------------------------------------------------------
server <- function(input, output, session) {
  
  colores_academic <- c(
    "AEROPUERTO" = "#0f172a", "GOES" = "#d97706", "OYA_518" = "#2563eb", 
    "OYA_780" = "#0ea5e9", "OYA_862" = "#0d9488", "OYA_1069" = "#65a30d", 
    "OYA_1128" = "#84cc16", "OYA_1193" = "#b45309", "OYA_1211" = "#dc2626", 
    "OYA_1354" = "#701a75"  
  )
  
  meta_unidades <- list(
    "temperatura" = list(label = "Temperatura", unit = "°C"),
    "presion"     = list(label = "Presión Atmosférica", unit = "hPa"),
    "humedad"     = list(label = "Humedad Relativa", unit = "%"),
    "pp_mm"       = list(label = "Precipitación", unit = "mm"),
    "radiacion_w_m2" = list(label = "Radiación Global", unit = "W/m²"),
    "viento_vel_m_s" = list(label = "Velocidad Viento", unit = "m/s"),
    "temp_sup_c"  = list(label = "Temperatura Superficial", unit = "°C")
  )
  
  oya1211_completo_clasif <- reactive({
    vis_data <- meteo_data %>% filter(estacion == "OYA_1211", variable == "visibilidad") %>% select(datetime, valor) %>% rename(visibilidad = valor)
    cap_data <- meteo_data %>% filter(estacion == "OYA_1211", variable %in% c("niebla_final", "rocio_final")) %>% pivot_wider(names_from = variable, values_from = valor)
    goes_data <- meteo_data %>% filter(estacion == "GOES", variable == "FLC") %>% select(datetime, valor) %>% rename(FLC = valor)
    
    base_all <- vis_data %>%
      left_join(cap_data, by = "datetime") %>%
      left_join(goes_data, by = "datetime") %>%
      mutate(
        datetime = as.POSIXct(datetime, tz = "UTC"),
        ts_10    = floor_date(datetime, "10 minutes"),
        fecha    = as.Date(ts_10),
        fog_cap = if_else(!is.na(niebla_final) & niebla_final > 0, 1L, 0L),
        dew_cap = if_else(!is.na(rocio_final)  & rocio_final  > 0, 1L, 0L),
        any_cap = if_else(fog_cap == 1L | dew_cap == 1L, 1L, 0L),
        fog_sat = if_else(!is.na(FLC) & FLC == 1, 1L, 0L),
        
        clasif_evento = case_when(
          any_cap == 0L ~ "SIN_EVENTO",
          !is.na(visibilidad) & visibilidad < 1000  ~ "NIEBLA",
          !is.na(visibilidad) & visibilidad >= 1000 ~ "ROCIO",
          is.na(visibilidad) & fog_sat == 1L ~ "NIEBLA",
          is.na(visibilidad) & fog_sat == 0L ~ "ROCIO",
          TRUE ~ "SIN_EVENTO"
        )
      )
    
    base_all$clasif_manual <- base_all$clasif_evento
    for(i in 1:nrow(correcciones_manual)) {
      base_all <- base_all %>%
        mutate(
          clasif_manual = if_else(
            datetime >= correcciones_manual$inicio[i] &
              datetime <= correcciones_manual$fin[i] &
              any_cap == 1,
            correcciones_manual$evento[i],
            clasif_manual
          )
        )
    }
    return(base_all)
  })
  
  df_dia_cap1 <- reactive({
    fecha_sel <- input$fecha_inspeccion
    oya1211_completo_clasif() %>% filter(fecha == fecha_sel)
  })
  
  construir_plot_cap1 <- function(df, tipo_clasif) {
    if(nrow(df) == 0) return(plotly_empty() %>% layout(title = "Sin registros para este día"))
    
    df$col_clasif <- if(tipo_clasif == "inicial") df$clasif_evento else df$clasif_manual
    df <- df %>% mutate(col_clasif = factor(col_clasif, levels = c("NIEBLA", "ROCIO", "SIN_EVENTO")))
    
    p <- plot_ly(df) %>%
      add_segments(x = ~datetime, xend = ~datetime, y = -1200, yend = -700,
                   color = I("#475569"), opacity = ~if_else(fog_sat == 1, 0.8, 0.1),
                   name = "GOES (Presencia)", showlegend = FALSE,
                   hoverinfo = "text", text = ~paste("GOES FLC:", fog_sat)) %>%
      add_segments(x = ~datetime, xend = ~datetime, y = -600, yend = -100,
                   color = ~col_clasif, 
                   colors = c("NIEBLA" = "#6baed6", "ROCIO" = "#c97a4a", "SIN_EVENTO" = "#bdbdbd"),
                   name = ~col_clasif, showlegend = TRUE,
                   hoverinfo = "text", text = ~paste("Clasif:", col_clasif)) %>%
      add_lines(x = ~datetime, y = ~visibilidad, name = "Visibilidad (m)",
                line = list(color = "#08519c", width = 1.5), connectgaps = TRUE) %>%
      add_segments(x = min(df$datetime), xend = max(df$datetime), y = 1000, yend = 1000,
                   name = "Umbral 1000m", line = list(color = "red", dash = "dash", width = 1)) %>%
      layout(
        xaxis = list(title = "Hora (UTC)", type = "date", tickformat = "%H:%M"),
        yaxis = list(title = "Visibilidad (m)", range = c(-1500, 5000),
                     tickvals = c(-1200, -500, 0, 1000, 3000, 5000),
                     ticktext = c("GOES", "Clasif.", "0", "1000", "3000", "5000")),
        legend = list(orientation = "h", y = -0.3, x = 0.5, xanchor = "center"),
        margin = list(b = 70) 
      )
    return(p)
  }
  
  output$plot_clasif_inicial <- renderPlotly({ construir_plot_cap1(df_dia_cap1(), "inicial") })
  output$plot_clasif_final   <- renderPlotly({ construir_plot_cap1(df_dia_cap1(), "final") })
  
  observeEvent(input$prev_day, { updateDateInput(session, "fecha_inspeccion", value = as.Date(input$fecha_inspeccion) - 1) })
  observeEvent(input$next_day, { updateDateInput(session, "fecha_inspeccion", value = as.Date(input$fecha_inspeccion) + 1) })
  
  # ==============================================================================
  # --- CAPÍTULO 2: PERFILES VERTICALES (θ, q y Viento) ---
  # Reutiliza meteo_data (ya cargado) y oya1211_completo_clasif() (ya definido)
  # ==============================================================================
  
  alturas_cap2 <- tibble::tribble(
    ~estacion,     ~z_m,
    "AEROPUERTO",   48,
    "OYA_518",     518,
    "OYA_780",     780,
    "OYA_862",     862,
    "OYA_1069",   1069,
    "OYA_1128",   1128,
    "OYA_1193",   1193,
    "OYA_1211",   1211,
    "OYA_1354",   1354
  )
  
  # Oculta la etiqueta "1193" en el eje Y (se superpone visualmente con "1211"),
  # pero conserva el punto/quiebre en esa altura.
  etiquetas_alturas <- function(alturas_ticks) {
    ifelse(alturas_ticks == 1193, "", as.character(alturas_ticks))
  }
  
  # --- Paleta y símbolos compartidos por los gráficos de perfiles (Cap. 2) ---
  # Paleta continua "turbo" (0-23h) usada tanto para colorear cada traza por hora
  # como para construir la barra de color (colorbar) nativa de plotly.
  paleta_hora_24 <- viridisLite::viridis(24, option = "turbo")
  names(paleta_hora_24) <- as.character(0:23)
  
  turbo_colorscale <- lapply(seq(0, 23), function(i) {
    list(i / 23, viridisLite::viridis(24, option = "turbo")[i + 1])
  })
  
  simbolos_evento <- c("NIEBLA" = "triangle-up", "ROCIO" = "square", "SIN_EVENTO" = "circle")
  colores_evento_prom <- c("NIEBLA" = "#2563eb", "ROCIO" = "#c2410c", "SIN_EVENTO" = "#6b7280")
  
  # Traza "fantasma" que dibuja la colorbar de Hora (UTC) una sola vez, sin
  # generar entradas de leyenda duplicadas (bug típico de ggplotly al combinar
  # una escala de color continua con una escala de forma discreta).
  trace_colorbar_hora <- function(p) {
    p %>% add_trace(
      x = rep(NA_real_, 24), y = rep(NA_real_, 24), type = "scatter", mode = "markers",
      marker = list(color = 0:23, colorscale = turbo_colorscale, cmin = 0, cmax = 23,
                    showscale = TRUE,
                    colorbar = list(title = list(text = "Hora (UTC)"), len = 0.6,
                                    y = 0.75, thickness = 14)),
      showlegend = FALSE, hoverinfo = "none", inherit = FALSE
    )
  }
  
  # Traza(s) "fantasma" para la leyenda de forma por Evento (triángulo/cuadrado/círculo)
  trace_leyenda_evento <- function(p, eventos_presentes) {
    for (ev in eventos_presentes) {
      p <- p %>% add_trace(
        x = NA_real_, y = NA_real_, type = "scatter", mode = "markers",
        marker = list(symbol = simbolos_evento[[ev]], color = "#334155", size = 10,
                      line = list(color = "white", width = 1)),
        name = ev, showlegend = TRUE, hoverinfo = "none", legendgroup = "evento", inherit = FALSE
      )
    }
    p
  }
  
  # --- Gráfico de perfil diario (valor de la variable, ej. θ o q) ---
  # Implementado con plotly nativo (no ggplotly) para tener control total sobre
  # ejes, ticks y leyendas, evitando el desborde/solape de etiquetas.
  build_perfil_diario <- function(df_day, xvar, xlab_txt, titulo, fecha_lbl, etiqueta_hover) {
    if (nrow(df_day) == 0) return(plotly_empty() %>% layout(title = "Sin registros para este día"))
    
    df_day <- df_day %>%
      mutate(xval = .data[[xvar]],
             color_hora = unname(paleta_hora_24[as.character(hora)]),
             simbolo = unname(simbolos_evento[clasif_evento]),
             txt = paste0("Hora: ", hora, "h<br>", etiqueta_hover, ": ", round(xval, 4), "<br>",
                          "Altura: ", z_m, " m<br>Evento: ", clasif_evento))
    
    alturas_ticks <- sort(unique(df_day$z_m))
    
    p <- plot_ly()
    for (h in sort(unique(df_day$hora))) {
      dh <- df_day %>% filter(hora == h) %>% arrange(z_m)
      p <- p %>% add_trace(
        data = dh, x = ~xval, y = ~z_m, type = "scatter", mode = "lines+markers",
        line = list(color = unique(dh$color_hora), width = 1.6),
        marker = list(color = unique(dh$color_hora), size = 9, symbol = ~simbolo,
                      line = list(color = "white", width = 1)),
        text = ~txt, hoverinfo = "text", showlegend = FALSE, inherit = FALSE
      )
    }
    
    p <- p %>% trace_colorbar_hora()
    p <- p %>% trace_leyenda_evento(intersect(names(simbolos_evento), unique(df_day$clasif_evento)))
    
    p %>% layout(
      title = list(text = paste(titulo, "—", fecha_lbl), font = list(size = 14, family = "Inter")),
      xaxis = list(title = xlab_txt, automargin = TRUE, tickfont = list(size = 10)),
      yaxis = list(title = "Altura (m)", tickvals = alturas_ticks,
                   ticktext = etiquetas_alturas(alturas_ticks), automargin = TRUE),
      legend = list(orientation = "h", y = -0.22, x = 0.5, xanchor = "center",
                    title = list(text = "Evento")),
      margin = list(t = 60, b = 90, r = 90),
      hovermode = "closest",
      autosize = TRUE
    ) %>%
      config(responsive = TRUE, displaylogo = FALSE)
  }
  
  # --- Gráfico de perfil diario del gradiente vertical ---
  build_perfil_diario_grad <- function(df_day, xvar, xlab_txt, titulo, fecha_lbl, etiqueta_hover, vline_crit = NULL) {
    if (nrow(df_day) == 0) return(plotly_empty() %>% layout(title = "Sin registros para este día"))
    
    df_day <- df_day %>%
      mutate(xval = .data[[xvar]],
             color_hora = unname(paleta_hora_24[as.character(hora)]),
             simbolo = unname(simbolos_evento[clasif_evento]),
             txt = paste0("Hora: ", hora, "h<br>", etiqueta_hover, ": ", round(xval, 5), "<br>",
                          "Altura: ", z_m, " m<br>Evento: ", clasif_evento))
    
    alturas_ticks <- sort(unique(df_day$z_m))
    
    p <- plot_ly()
    for (h in sort(unique(df_day$hora))) {
      dh <- df_day %>% filter(hora == h) %>% arrange(z_m)
      p <- p %>% add_trace(
        data = dh, x = ~xval, y = ~z_m, type = "scatter", mode = "lines+markers",
        line = list(color = unique(dh$color_hora), width = 1.6),
        marker = list(color = unique(dh$color_hora), size = 9, symbol = ~simbolo,
                      line = list(color = "white", width = 1)),
        text = ~txt, hoverinfo = "text", showlegend = FALSE, inherit = FALSE
      )
    }
    
    p <- p %>% trace_colorbar_hora()
    p <- p %>% trace_leyenda_evento(intersect(names(simbolos_evento), unique(df_day$clasif_evento)))
    
    rango_y <- range(alturas_ticks)
    shapes_list <- list(list(type = "line", x0 = 0, x1 = 0,
                             y0 = rango_y[1] - 30, y1 = rango_y[2] + 30,
                             line = list(color = "black", dash = "dash", width = 1)))
    if (!is.null(vline_crit)) {
      shapes_list <- append(shapes_list, list(list(
        type = "line", x0 = vline_crit, x1 = vline_crit,
        y0 = rango_y[1] - 30, y1 = rango_y[2] + 30,
        line = list(color = "red", dash = "dot", width = 1.5)
      )))
    }
    
    p %>% layout(
      title = list(text = paste(titulo, "—", fecha_lbl), font = list(size = 14, family = "Inter")),
      xaxis = list(title = xlab_txt, automargin = TRUE, tickfont = list(size = 10)),
      yaxis = list(title = "Altura (m)", tickvals = alturas_ticks,
                   ticktext = etiquetas_alturas(alturas_ticks), automargin = TRUE),
      legend = list(orientation = "h", y = -0.22, x = 0.5, xanchor = "center",
                    title = list(text = "Evento")),
      shapes = shapes_list,
      margin = list(t = 60, b = 90, r = 90),
      hovermode = "closest",
      autosize = TRUE
    ) %>%
      config(responsive = TRUE, displaylogo = FALSE)
  }
  
  # --- Gráfico de perfil promedio anual ---
  # Cada evento (NIEBLA / ROCIO / SIN_EVENTO) se dibuja como UNA sola traza
  # "lines+markers" ordenada por altura, de modo que sus puntos queden unidos
  # y se aprecie el perfil vertical. Las barras de error (SD) se adjuntan al
  # mismo trazo como error_x, sin ocultar la línea de tendencia.
  build_perfil_promedio <- function(dat_grad, gradvar, titulo, xlab_txt, etiqueta_hover,
                                    vline_crit = NULL, offset_m = 10) {
    
    perfil_stats <- dat_grad %>%
      filter(!is.na(clasif_evento)) %>%
      group_by(clasif_evento, z_m) %>%
      summarise(
        mean_grad = mean(.data[[gradvar]], na.rm = TRUE),
        sd_grad   = sd(.data[[gradvar]], na.rm = TRUE),
        n         = sum(!is.na(.data[[gradvar]])),
        .groups = "drop"
      )
    
    perfil_interp_1069 <- perfil_stats %>%
      filter(z_m %in% c(862, 1128)) %>%
      group_by(clasif_evento) %>%
      summarise(
        z_m       = 1069,
        mean_grad = mean(mean_grad, na.rm = TRUE),
        sd_grad   = mean(sd_grad, na.rm = TRUE),
        n         = mean(n, na.rm = TRUE),
        .groups = "drop"
      )
    
    perfil_promedio <- perfil_stats %>%
      filter(z_m != 1069, z_m != 48) %>%
      bind_rows(perfil_interp_1069) %>%
      mutate(clasif_evento = factor(clasif_evento, levels = c("NIEBLA", "ROCIO", "SIN_EVENTO"))) %>%
      arrange(clasif_evento, z_m)
    
    # Punto base en 48 m (estación AEROPUERTO): gradiente exactamente 0 para los 3 eventos
    punto_base <- tibble(
      clasif_evento = factor(c("NIEBLA", "ROCIO", "SIN_EVENTO"), levels = c("NIEBLA", "ROCIO", "SIN_EVENTO")),
      z_m = 48, mean_grad = 0, sd_grad = 0, n = NA_real_
    )
    
    perfil_promedio <- perfil_promedio %>%
      bind_rows(punto_base) %>%
      arrange(clasif_evento, z_m)
    
    alturas_finales <- sort(unique(perfil_promedio$z_m))
    
    offsets <- c("NIEBLA" = -offset_m, "ROCIO" = 0, "SIN_EVENTO" = offset_m)
    
    perfil_plot <- perfil_promedio %>%
      mutate(
        z_plot = z_m + offsets[as.character(clasif_evento)],
        txt = paste0("Evento: ", clasif_evento, "<br>Altura: ", z_m, " m<br>",
                     "Media ", etiqueta_hover, ": ", round(mean_grad, 5), "<br>SD: ", round(sd_grad, 5))
      )
    
    p <- plot_ly()
    for (ev in c("NIEBLA", "ROCIO", "SIN_EVENTO")) {
      de <- perfil_plot %>% filter(clasif_evento == ev) %>% arrange(z_m)
      if (nrow(de) == 0) next
      p <- p %>% add_trace(
        data = de, x = ~mean_grad, y = ~z_plot, type = "scatter", mode = "lines+markers",
        line = list(color = colores_evento_prom[[ev]], width = 2.5),
        marker = list(color = colores_evento_prom[[ev]], size = 8,
                      line = list(color = "white", width = 1)),
        error_x = list(array = ~sd_grad, color = colores_evento_prom[[ev]],
                       thickness = 1, width = 5, opacity = 0.22),
        name = ev, text = ~txt, hoverinfo = "text", connectgaps = TRUE, inherit = FALSE
      )
    }
    
    rango_y <- range(alturas_finales)
    shapes_list <- list(list(type = "line", x0 = 0, x1 = 0,
                             y0 = rango_y[1] - offset_m - 30, y1 = rango_y[2] + offset_m + 30,
                             line = list(color = "black", dash = "dash", width = 1)))
    if (!is.null(vline_crit)) {
      shapes_list <- append(shapes_list, list(list(
        type = "line", x0 = vline_crit, x1 = vline_crit,
        y0 = rango_y[1] - offset_m - 30, y1 = rango_y[2] + offset_m + 30,
        line = list(color = "red", dash = "dot", width = 1.5)
      )))
    }
    
    p %>% layout(
      title = list(text = titulo, font = list(size = 15, family = "Inter")),
      xaxis = list(title = xlab_txt, automargin = TRUE),
      yaxis = list(title = "Altura (m)", tickvals = alturas_finales,
                   ticktext = etiquetas_alturas(alturas_finales), automargin = TRUE),
      shapes = shapes_list,
      legend = list(orientation = "h", y = -0.18, x = 0.5, xanchor = "center",
                    title = list(text = "Evento")),
      margin = list(t = 60, b = 80),
      hovermode = "closest",
      autosize = TRUE
    ) %>%
      config(responsive = TRUE, displaylogo = FALSE)
  }
  
  theta_data <- reactive({
    R  <- 287        # J kg-1 K-1
    Cp <- 1004.67    # J kg-1 K-1
    g  <- 9.80665    # m s-2
    epsilon <- 0.622
    
    dat_wide <- meteo_data %>%
      filter(variable %in% c("presion", "temperatura", "humedad", "viento_vel_m_s")) %>%
      select(datetime, estacion, variable, valor) %>%
      pivot_wider(names_from = variable, values_from = valor)
    
    dat <- dat_wide %>%
      left_join(alturas_cap2, by = "estacion") %>%
      filter(estacion != "GOES", !is.na(z_m))
    
    clasif_df <- oya1211_completo_clasif() %>%
      select(datetime, clasif_evento = clasif_manual)
    
    dat <- dat %>% left_join(clasif_df, by = "datetime")
    
    aeropuerto_ref <- dat %>%
      filter(estacion == "AEROPUERTO") %>%
      select(datetime, P1 = presion, T1_C = temperatura)
    
    dat <- dat %>% left_join(aeropuerto_ref, by = "datetime")
    
    dat <- dat %>%
      mutate(
        T_K  = temperatura + 273.15,
        T1_K = T1_C + 273.15,
        Tmedia_K = (T_K + T1_K) / 2,
        z1 = 48,
        delta_z = z_m - z1,
        presion_calc = P1 * exp(-(g * delta_z) / (R * Tmedia_K)),
        presion_final = if_else(is.na(presion) & !is.na(P1), presion_calc, presion),
        theta_K = T_K * (P1 / presion_final)^(R / Cp),
        
        # --- Humedad específica ---
        es_hPa = 6.112 * exp((17.67 * temperatura) / (temperatura + 243.5)),
        e_hPa  = (humedad / 100) * es_hPa,
        q_kgkg = (epsilon * e_hPa) / (presion_final - (1 - epsilon) * e_hPa),
        q_gkg  = q_kgkg * 1000
      )
    
    dat <- dat %>%
      group_by(datetime) %>%
      mutate(
        theta_ref  = theta_K[estacion == "AEROPUERTO"][1],
        q_ref      = q_gkg[estacion == "AEROPUERTO"][1],
        u_ref      = viento_vel_m_s[estacion == "AEROPUERTO"][1],
        z_ref      = 48,
        delta_z_g  = z_m - z_ref,
        grad_theta = if_else(z_m == z_ref, 0, (theta_K - theta_ref) / delta_z_g),
        grad_q     = if_else(z_m == z_ref, 0, (q_gkg - q_ref) / delta_z_g),
        grad_u     = if_else(z_m == z_ref, 0, (viento_vel_m_s - u_ref) / delta_z_g)
      ) %>%
      ungroup() %>%
      mutate(fecha = as.Date(datetime), hora = hour(datetime))
    
    return(dat)
  })
  
  df_dia_cap2 <- reactive({
    fecha_sel <- input$fecha_cap2
    theta_data() %>%
      filter(minute(datetime) == 0, second(datetime) == 0, fecha == fecha_sel) %>%
      arrange(hora, z_m)
  })
  
  observeEvent(input$prev_day_cap2, { updateDateInput(session, "fecha_cap2", value = as.Date(input$fecha_cap2) - 1) })
  observeEvent(input$next_day_cap2, { updateDateInput(session, "fecha_cap2", value = as.Date(input$fecha_cap2) + 1) })
  
  # --- θ: Temperatura potencial ---
  output$plot_theta_dia <- renderPlotly({
    build_perfil_diario(df_dia_cap2(), "theta_K", "θ (K)", "Perfil vertical θ",
                        format(as.Date(input$fecha_cap2), "%Y-%m-%d"), "θ")
  })
  
  output$plot_thetagrad_dia <- renderPlotly({
    build_perfil_diario_grad(df_dia_cap2(), "grad_theta", "Δθ/Δz (K/m)", "Perfil vertical Δθ/Δz",
                             format(as.Date(input$fecha_cap2), "%Y-%m-%d"), "Δθ/Δz", vline_crit = 0.0031)
  })
  
  output$plot_thetagrad_promedio <- renderPlotly({
    build_perfil_promedio(theta_data(), "grad_theta",
                          "Perfil vertical promedio anual Δθ/Δz (2024)", "Δθ/Δz (K/m)", "Δθ/Δz",
                          vline_crit = 0.0031, offset_m = 10)
  })
  
  # --- q: Humedad específica ---
  output$plot_q_dia <- renderPlotly({
    build_perfil_diario(df_dia_cap2(), "q_gkg", "Humedad específica (g/kg)", "Perfil vertical q",
                        format(as.Date(input$fecha_cap2), "%Y-%m-%d"), "q")
  })
  
  output$plot_qgrad_dia <- renderPlotly({
    build_perfil_diario_grad(df_dia_cap2(), "grad_q", "Δq/Δz (g kg⁻¹ m⁻¹)", "Perfil vertical Δq/Δz",
                             format(as.Date(input$fecha_cap2), "%Y-%m-%d"), "Δq/Δz", vline_crit = -0.0016)
  })
  
  output$plot_qgrad_promedio <- renderPlotly({
    build_perfil_promedio(theta_data(), "grad_q",
                          "Perfil vertical promedio anual Δq/Δz (2024)", "Δq/Δz (g kg⁻¹ m⁻¹)", "Δq/Δz",
                          vline_crit = -0.0016, offset_m = 10)
  })
  
  # --- Viento (solo promedio anual, sin perfil diario por ahora) ---
  output$plot_ugrad_promedio <- renderPlotly({
    build_perfil_promedio(theta_data(), "grad_u",
                          "Perfil vertical promedio anual ΔU/Δz (2024)", "ΔU/Δz (s⁻¹)", "ΔU/Δz",
                          vline_crit = NULL, offset_m = 15)
  })
  
  # --- PESTAÑA A: REDISTRIBUCIÓN DE PROPORCIONES ---
  output$plot_prop_facetas <- renderPlotly({
    df_filtrado <- oya1211_completo_clasif() %>% filter(!(fecha >= "2024-01-01" & fecha <= "2024-01-24"))
    
    prop_captacion <- df_filtrado %>%
      mutate(tipo = case_when(fog_cap == 1 & dew_cap == 1 ~ "Niebla + Rocío", fog_cap == 1 & dew_cap == 0 ~ "Niebla", fog_cap == 0 & dew_cap == 1 ~ "Rocío", TRUE ~ "Sin evento")) %>%
      count(tipo) %>% mutate(prop = n / sum(n), grupo = "Captación instrumental")
    
    prop_clasificacion <- df_filtrado %>%
      mutate(tipo = case_when(clasif_manual == "NIEBLA" ~ "Niebla", clasif_manual == "ROCIO" ~ "Rocío", clasif_manual == "SIN_EVENTO" ~ "Sin evento", TRUE ~ NA_character_)) %>%
      filter(!is.na(tipo)) %>% count(tipo) %>% mutate(prop = n / sum(n), grupo = "Clasificación final")
    
    df_plot <- bind_rows(prop_captacion, prop_clasificacion)
    
    p1 <- df_plot %>% filter(grupo == "Captación instrumental") %>%
      plot_ly(x = ~prop, y = ~tipo, type = "bar", orientation = 'h', showlegend = FALSE,
              marker = list(color = c("Niebla" = "#6baed6", "Rocío" = "#c97a4a", "Niebla + Rocío" = "#756bb1", "Sin evento" = "#bdbdbd")[.$tipo]),
              text = ~paste0(round(prop*100, 2), "%"), textposition = 'auto')
    
    p2 <- df_plot %>% filter(grupo == "Clasificación final") %>%
      plot_ly(x = ~prop, y = ~tipo, type = "bar", orientation = 'h', showlegend = FALSE,
              marker = list(color = c("Niebla" = "#6baed6", "Rocío" = "#c97a4a", "Niebla + Rocío" = "#756bb1", "Sin evento" = "#bdbdbd")[.$tipo]),
              text = ~paste0(round(prop*100, 2), "%"), textposition = 'auto')
    
    subplot(p1, p2, nrows = 1, shareY = TRUE, titleX = TRUE) %>%
      layout(title = "Proporción de eventos antes y después de la clasificación",
             xaxis = list(title = "Proporción del tiempo", tickformat = ".0%"),
             xaxis2 = list(title = "Proporción del tiempo", tickformat = ".0%"),
             margin = list(t = 50))
  })
  
  # --- PESTAÑA B: DISTRIBUCIÓN MENSUAL (CORREGIDA) ---
  output$plot_dist_mensual <- renderPlotly({
    df_base <- oya1211_completo_clasif() %>%
      filter(!(fecha >= "2024-01-01" & fecha <= "2024-01-24")) %>%
      mutate(
        month_num = month(fecha),
        collected_water = pmax(coalesce(niebla_final, 0), coalesce(rocio_final, 0)),
        event_type = recode(clasif_manual, "NIEBLA" = "Fog", "ROCIO" = "Dew")
      ) %>%
      filter(event_type %in% c("Fog", "Dew"))
    
    res_mean <- df_base %>% filter(collected_water > 0) %>%
      group_by(month_num, event_type) %>% summarise(mean_water = mean(collected_water, na.rm = TRUE), .groups = "drop")
    
    res_freq <- df_base %>% count(month_num, event_type) %>%
      group_by(month_num) %>% mutate(rel_freq = n / sum(n)) %>% ungroup()
    
    df_plot <- left_join(res_mean, res_freq, by = c("month_num", "event_type"))
    
    df_fog <- df_plot %>% filter(event_type == "Fog")
    df_dew <- df_plot %>% filter(event_type == "Dew")
    
    plot_ly() %>%
      add_bars(data = df_fog, x = ~month_num, y = ~mean_water, name = "Mean water: Fog", marker = list(color = "#93C5FD")) %>%
      add_bars(data = df_dew, x = ~month_num, y = ~mean_water, name = "Mean water: Dew", marker = list(color = "#FCA5A5")) %>%
      add_lines(data = df_fog, x = ~month_num, y = ~rel_freq, name = "Freq: Fog", yaxis = "y2", line = list(color = "#3b82f6", width = 2.5)) %>%
      add_markers(data = df_fog, x = ~month_num, y = ~rel_freq, yaxis = "y2", marker = list(color = "#3b82f6", size = 6), showlegend = FALSE) %>%
      add_lines(data = df_dew, x = ~month_num, y = ~rel_freq, name = "Freq: Dew", yaxis = "y2", line = list(color = "#ef4444", width = 2.5)) %>%
      add_markers(data = df_dew, x = ~month_num, y = ~rel_freq, yaxis = "y2", marker = list(color = "#ef4444", size = 6), showlegend = FALSE) %>%
      layout(
        title = "Monthly collected water and relative frequency",
        barmode = 'group',
        xaxis = list(title = "Month (2024)", tickvals = 1:12, ticktext = month.abb),
        yaxis = list(title = "Mean collected water when > 0 mL"),
        yaxis2 = list(title = "Monthly relative frequency", overlaying = "y", side = "right", tickformat = ".0%", range = c(0, 1), automargin = TRUE),
        legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.2),
        margin = list(b = 80, r = 80) # Margen derecho amplio para el eje Y secundario
      )
  })
  
  # --- PESTAÑA C: DISTRIBUCIÓN DIARIA (CORREGIDA) ---
  output$plot_dist_diaria <- renderPlotly({
    df_base_diaria <- oya1211_completo_clasif() %>%
      filter(!(fecha >= "2024-01-01" & fecha <= "2024-01-24")) %>%
      mutate(
        hour_utc = hour(datetime),
        collected_water = pmax(coalesce(niebla_final, 0), coalesce(rocio_final, 0)),
        event_type = recode(clasif_manual, "NIEBLA" = "Fog", "ROCIO" = "Dew")
      ) %>%
      filter(event_type %in% c("Fog", "Dew"))
    
    res_mean_h <- df_base_diaria %>% filter(collected_water > 0) %>%
      group_by(hour_utc, event_type) %>% summarise(mean_water = mean(collected_water, na.rm = TRUE), .groups = "drop")
    
    res_freq_h <- df_base_diaria %>% count(hour_utc, event_type) %>%
      group_by(hour_utc) %>% mutate(rel_freq = n / sum(n)) %>% ungroup()
    
    df_plot_h <- left_join(res_mean_h, res_freq_h, by = c("hour_utc", "event_type"))
    
    df_fog_h <- df_plot_h %>% filter(event_type == "Fog")
    df_dew_h <- df_plot_h %>% filter(event_type == "Dew")
    
    horas_chile_labels <- sapply(0:23, function(h) paste0((h - 3) %% 24, "h"))
    
    plot_ly() %>%
      add_bars(data = df_fog_h, x = ~hour_utc, y = ~mean_water, name = "Mean water: Fog", marker = list(color = "#93C5FD")) %>%
      add_bars(data = df_dew_h, x = ~hour_utc, y = ~mean_water, name = "Mean water: Dew", marker = list(color = "#FCA5A5")) %>%
      add_lines(data = df_fog_h, x = ~hour_utc, y = ~rel_freq, name = "Freq: Fog", yaxis = "y2", line = list(color = "#3b82f6", width = 2)) %>%
      add_markers(data = df_fog_h, x = ~hour_utc, y = ~rel_freq, yaxis = "y2", marker = list(color = "#3b82f6", size = 5), showlegend = FALSE) %>%
      add_lines(data = df_dew_h, x = ~hour_utc, y = ~rel_freq, name = "Freq: Dew", yaxis = "y2", line = list(color = "#ef4444", width = 2)) %>%
      add_markers(data = df_dew_h, x = ~hour_utc, y = ~rel_freq, yaxis = "y2", marker = list(color = "#ef4444", size = 5), showlegend = FALSE) %>%
      layout(
        title = "Hourly collected water and relative frequency",
        barmode = 'group',
        xaxis = list(title = "Hour (UTC)", tickvals = 0:23, ticktext = paste0(0:23, "h")),
        xaxis2 = list(title = "Local time (Chile)", overlaying = "x", side = "top", tickvals = 0:23, ticktext = horas_chile_labels, showgrid = FALSE),
        yaxis = list(title = "Mean collected water when > 0 mL"),
        yaxis2 = list(title = "Hourly relative frequency", overlaying = "y", side = "right", tickformat = ".0%", range = c(0, 1), automargin = TRUE),
        legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.25),
        margin = list(b = 80, t = 80, r = 80) # Margen derecho amplio para que el eje Y derecho respire
      )
  })
  
  # --- PANELES COMPLEMENTARIOS ---
  output$plot_transecta <- renderPlotly({
    p <- ggplot(transecta_df, aes(x = reorder(estacion, altitud), y = altitud, group = 1, text = paste("Estación:", estacion))) +
      geom_line(color = "#cbd5e1", size = 0.8) + geom_point(color = transecta_df$color_pto, size = transecta_df$tam_pto) +
      theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplotly(p, tooltip = "text")
  })
  
  output$tabla_disponibilidad <- renderDT({
    esperado_2024 <- 366 * 24 * 6
    disp_df <- meteo_data %>% group_by(variable, estacion) %>%
      summarise(registros = sum(!is.na(valor)), .groups = "drop") %>%
      mutate(disponibilidad_pct = round(100 * registros / esperado_2024, 1)) %>%
      select(variable, estacion, disponibilidad_pct) %>% pivot_wider(names_from = estacion, values_from = disponibilidad_pct)
    datatable(disp_df, options = list(pageLength = -1, scrollX = TRUE))
  })
  
  output$plot_niebla <- renderPlotly({
    df <- meteo_data %>% filter(variable == "niebla_final", datetime >= as.POSIXct(input$dates_global[1]), datetime <= as.POSIXct(input$dates_global[2]))
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines")
  })
  output$plot_rocio <- renderPlotly({
    df <- meteo_data %>% filter(variable == "rocio_final", datetime >= as.POSIXct(input$dates_global[1]), datetime <= as.POSIXct(input$dates_global[2]))
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines")
  })
  output$plot_visibilidad <- renderPlotly({
    df <- meteo_data %>% filter(variable == "visibilidad", datetime >= as.POSIXct(input$dates_global[1]), datetime <= as.POSIXct(input$dates_global[2]))
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines")
  })
  output$plot_goes <- renderPlotly({
    df <- meteo_data %>% filter(variable == "FLC", datetime >= as.POSIXct(input$dates_global[1]), datetime <= as.POSIXct(input$dates_global[2]))
    plot_ly(df, x = ~datetime, y = ~valor, type = "scatter", mode = "markers", marker = list(color = "#d97706"))
  })
  output$plot_dinamico <- renderPlotly({
    req(input$var_selector)
    df <- meteo_data %>% filter(variable == input$var_selector, datetime >= as.POSIXct(input$dates_global[1]), datetime <= as.POSIXct(input$dates_global[2]))
    
    meta <- meta_unidades[[input$var_selector]]
    titulo_eje_y <- paste0(meta$label, " (", meta$unit, ")")
    
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines") %>%
      layout(xaxis = list(title = "Fecha"), yaxis = list(title = titulo_eje_y), legend = list(orientation = "h", y = -0.15))
  })
}

# ------------------------------------------------------------------------------
# 4. LANZAMIENTO DE LA APLICACIÓN
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)