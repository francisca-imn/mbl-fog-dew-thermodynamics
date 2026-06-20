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

# ------------------------------------------------------------------------------
# 2. INTERFAZ DE USUARIO (UI)
# ------------------------------------------------------------------------------
ui <- dashboardPage(
  skin = "blue", 
  dashboardHeader(title = "Tesis: Datos"),
  
  dashboardSidebar(
    # CONTENEDOR INTEGRADO: Ahora se fusiona perfectamente con el fondo claro
    div(style = "background-color: #ffffff; padding: 16px 12px; text-align: center; border-bottom: 1px solid #e2e8f0;",
        img(src = "raiz/logo_fasina.png", style = "width: 95%; max-height: 50px; object-fit: contain;")
    ),
    
    sidebarMenu(
      menuItem("Resumen y Transecta", tabName = "resumen", icon = icon("layer-group")),
      menuItem("Captación Crítica (Agua)", tabName = "agua", icon = icon("tint")),
      menuItem("Visibilidad y GOES", tabName = "satelital", icon = icon("eye")),
      menuItem("Variables Dinámicas", tabName = "dinamicas", icon = icon("chart-line"))
    ),
    
    # CUADRO DE LOG: Adaptado al look minimalista y elegante
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
      
      /* --- PERSONALIZACIÓN AD HOC DE COLORES BARRA SUPERIOR Y LATERAL --- */
      .skin-blue .main-header .navbar { background-color: #0f172a !important; }
      .skin-blue .main-header .logo { background-color: #020617 !important; font-weight: 600; }
      
      /* Fusión Completa de la Barra Lateral Estilo Claro */
      .skin-blue .main-sidebar { 
        background-color: #ffffff !important; 
        border-right: 1px solid #e2e8f0 !important;
      }
      
      /* Links del menú estables */
      .skin-blue .sidebar-menu > li > a { 
        color: #475569 !important; 
        font-weight: 500;
      }
      
      /* Estado Hover y Activo combinando Azul PUC */
      .skin-blue .sidebar-menu > li.active > a, 
      .skin-blue .sidebar-menu > li:hover > a {
        background-color: #f0f9ff !important; 
        color: #0284c7 !important; 
        border-left-color: #0284c7 !important;
      }
      
      /* Íconos adaptados al contraste */
      .skin-blue .sidebar-menu > li > a > .fa { color: #64748b !important; }
      .skin-blue .sidebar-menu > li.active > a > .fa,
      .skin-blue .sidebar-menu > li:hover > a > .fa { 
        color: #0284c7 !important; 
      }
      
      /* Estilos generales del contenedor body */
      .box { 
        border-top: 3px solid #0284c7 !important; 
        border-radius: 8px !important; 
        box-shadow: 0 4px 12px rgba(15, 23, 42, 0.04) !important; 
      }
      .box-header .box-title { font-weight: 600 !important; font-size: 15px !important; }
      .content-wrapper { background-color: #f8fafc !important; }
      .dataTables_wrapper .dataTables_length { display: none !important; }
    "))),
    
    tabItems(
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
                            tags$li(strong("Capítulos 2 y 3:"), " Evolución y perfiles de la capa límite utilizando variables dinámicas estructurales (", strong("Presión, Temperatura y Viento"), ").")
                    ),
                    div(style = "background-color: #f0f9ff; border-left: 4px solid #0284c7; padding: 8px 12px; margin-top: 10px; border-radius: 0 4px 4px 0; font-size: 11.5px;",
                        p(style = "margin: 0; color: #0369a1;", strong("Nota Técnica:"), " La estación ", strong("OYA_1211"), " representa el nodo máster de la red al concentrar los sensores críticos de visibilidad y rocío.")
                    )
                ),
                
                box(title = "Matriz de Disponibilidad de Datos (%) - Ciclo Completo 2024", status = "primary", width = 12,
                    DTOutput("tabla_disponibilidad"))
              )
      ),
      
      tabItem(tabName = "agua",
              fluidRow(
                box(title = "Filtro de Serie Temporal", status = "primary", width = 12,
                    column(4, dateRangeInput("dates_agua", "Rango de Análisis:", start = "2024-01-01", end = "2024-12-31", min = "2024-01-01", max = "2024-12-31"))
                ),
                box(title = "Captación de Niebla Unificada (Final - mm/mL)", status = "primary", width = 12,
                    plotlyOutput("plot_niebla", height = "400px")),
                box(title = "Captación de Rocío Unificada (Final - mm/mL)", status = "primary", width = 12,
                    plotlyOutput("plot_rocio", height = "400px"))
              )
      ),
      
      tabItem(tabName = "satelital",
              fluidRow(
                box(title = "Visibilidad Corregida (Filtro < 0.4m eliminado)", status = "primary", width = 12,
                    plotlyOutput("plot_visibilidad", height = "380px")),
                box(title = "GOES - Presencia de Nubes Bajas (FLC)", status = "primary", width = 12,
                    p(style = "color: #64748b;", "Representación discreta (0: Ausencia / 1: Presencia de Low Clouds) sobre el píxel de Oyarbide."),
                    plotlyOutput("plot_goes", height = "250px"))
              )
      ),
      
      tabItem(tabName = "dinamicas",
              fluidRow(
                box(title = "Filtros Avanzados Estructurales (Capítulos 2 y 3)", status = "primary", width = 12,
                    column(6, selectInput("var_selector", "Seleccione Variable Física:",
                                          choices = c("Temperatura" = "temperatura", 
                                                      "Presión Atmosférica" = "presion", 
                                                      "Humedad Relativa" = "humedad", 
                                                      "Precipitación" = "pp_mm", 
                                                      "Radiación Global" = "radiacion_w_m2", 
                                                      "Velocidad Viento" = "viento_vel_m_s",
                                                      "Temperatura Superficial" = "temp_sup_c"))),
                    column(6, dateRangeInput("dates_dinamicas", "Ventana Temporal de Study:", start = "2024-01-01", end = "2024-06-30"))
                ),
                box(title = "Análisis Temporal Interactivo de la Capa Límite", status = "primary", width = 12,
                    plotlyOutput("plot_dinamico", height = "500px"))
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
  
  output$plot_transecta <- renderPlotly({
    p <- ggplot(transecta_df, aes(x = reorder(estacion, altitud), y = altitud, group = 1, 
                                  text = paste("Estación:", estacion, "<br>Altura:", altitud, "m s.n.m."))) +
      geom_line(color = "#cbd5e1", size = 0.8) +
      geom_point(color = transecta_df$color_pto, size = transecta_df$tam_pto) +
      labs(x = "Perfil de Estaciones", y = "Elevación (m s.n.m.)") +
      theme_minimal() +
      theme(
        panel.grid.major = element_line(color = "#f1f5f9"),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 8, color = "#475569")
      )
    
    ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
  })
  
  output$tabla_disponibilidad <- renderDT({
    esperado_2024 <- 366 * 24 * 6 
    
    disp_df <- meteo_data %>%
      group_by(variable, estacion) %>%
      summarise(registros = sum(!is.na(valor)), .groups = "drop") %>%
      mutate(disponibilidad_pct = round(100 * registros / esperado_2024, 1)) %>%
      select(variable, estacion, disponibilidad_pct) %>%
      pivot_wider(names_from = estacion, values_from = disponibilidad_pct) %>%
      arrange(variable)
    
    orden_cols <- c("variable", "GOES", "AEROPUERTO", "OYA_518", "OYA_780", "OYA_862", "OYA_1069", "OYA_1128", "OYA_1193", "OYA_1211", "OYA_1354")
    disp_df <- disp_df %>% select(any_of(orden_cols))
    
    datatable(disp_df, options = list(pageLength = -1, lengthChange = FALSE, scrollX = TRUE, dom = 'tpi'), 
              class = 'cell-border stripe hover')
  })
  
  output$plot_niebla <- renderPlotly({
    df <- meteo_data %>% filter(variable == "niebla_final", datetime >= as.POSIXct(input$dates_agua[1]), datetime <= as.POSIXct(input$dates_agua[2]))
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines") %>%
      layout(xaxis = list(title = "Fecha"), yaxis = list(title = "Niebla Equivalente (mm/mL)"), legend = list(orientation = "h", y = -0.2))
  })
  
  output$plot_rocio <- renderPlotly({
    df <- meteo_data %>% filter(variable == "rocio_final", datetime >= as.POSIXct(input$dates_agua[1]), datetime <= as.POSIXct(input$dates_agua[2]))
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines") %>%
      layout(xaxis = list(title = "Fecha"), yaxis = list(title = "Rocío Equivalente (mm/mL)"), legend = list(orientation = "h", y = -0.2))
  })
  
  output$plot_visibilidad <- renderPlotly({
    df <- meteo_data %>% filter(variable == "visibilidad")
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines") %>%
      layout(xaxis = list(title = "Fecha"), yaxis = list(title = "Visibilidad Corregida (m)"))
  })
  
  output$plot_goes <- renderPlotly({
    df <- meteo_data %>% filter(variable == "FLC")
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, type = "scatter", mode = "markers", marker = list(size = 4, opacity = 0.6, color = "#d97706")) %>%
      layout(xaxis = list(title = "Fecha"), yaxis = list(title = "FLC (0 = No, 1 = Sí)"))
  })
  
  output$plot_dinamico <- renderPlotly({
    df <- meteo_data %>% filter(variable == input$var_selector, datetime >= as.POSIXct(input$dates_dinamicas[1]), datetime <= as.POSIXct(input$dates_dinamicas[2]))
    plot_ly(df, x = ~datetime, y = ~valor, color = ~estacion, colors = colores_academic, type = "scatter", mode = "lines") %>%
      layout(xaxis = list(title = "Fecha"), yaxis = list(title = paste("Magnitud:", input$var_selector)), legend = list(orientation = "h", y = -0.15))
  })
}

# ------------------------------------------------------------------------------
# 4. LANZAMIENTO DE LA APLICACIÓN
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)