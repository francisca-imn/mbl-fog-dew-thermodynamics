# OYA518 -------
library(tidyverse)
library(janitor)
library(readxl)

ruta <- "data/oyarbide_original_v02/OYA_518/"   # <-- CAMBIA ESTA RUTA

archivos <- list.files(
  path = ruta,
  pattern = "2024|2025.*\\.xlsx$",
  full.names = TRUE
)

print(archivos)

# 4. Leer todos los Excel
lista_df <- map(
  archivos,
  ~ read_excel(.x) %>%
    clean_names() %>%                      # normaliza nombres
    mutate(archivo_origen = basename(.x))  # guarda archivo fuente
)

columnas_por_archivo <- map(lista_df, names)

# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)

glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(datos_2024_2025)

datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    
    niederschlag_nebelwasser_ml = rowMeans(
      cbind(
        niederschlag_nebelwasser_menge_ml,
        niederschlag_nebelwasser_menge2_ml
      ),
      na.rm = TRUE
    )
  ) %>%
  
select(
  -niederschlag_nebelwasser_menge_ml,
  -niederschlag_nebelwasser_menge2_ml
)

names(datos_2024_2025)

# 9. Cobertura por variable

resumen_cobertura <- datos_2024_2025 %>%
  summarise(across(everything(), ~ sum(!is.na(.)))) %>%
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "n_datos"
  ) %>%
  arrange(n_datos)

print(resumen_cobertura)

resumen_cobertura %>%
  filter(str_detect(variable, "nebelwasser"))

# Guardar:
write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_518_2024-2025.csv"
)

# OYA780 -------
ruta <- "data/oyarbide_original_v02/OYA_780/"   # <-- CAMBIA ESTA RUTA

archivos <- list.files(
  path = ruta,
  pattern = "2024|2025.*\\.xlsx$",
  full.names = TRUE
)

print(archivos)

# 4. Leer todos los Excel
lista_df <- map(
  archivos,
  ~ read_excel(.x) %>%
    clean_names() %>%                      # normaliza nombres
    mutate(archivo_origen = basename(.x))  # guarda archivo fuente
)

columnas_por_archivo <- map(lista_df, names)

# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)


glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(datos_2024_2025)


datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    luft_temperatur_c = luft_temperatur_2b_c,
    luft_feuchte_percent = luft_feuchte_2b_percent,
    wind_geschwindigkeit_m_s = wind_geschwindigkeit_2b_m_s,
    wind_richtung = wind_richtung_2b,

    wind_geschwindigkeit_standardabweichung_m_s =
      wind_geschwindigkeit_standardabweichung_2b_m_s,
    
    wind_richtung_standardabweichung =
      wind_richtung_standardabweichung_2b,
    

    umwelt_blatt_feuchte_percent =
      umwelt_blatt_feuchte_2b_percent,
    
    luft_druck_h_pa = luft_druck_2b_h_pa,
    

    niederschlag_nebelwasser_mm =
      niederschlag_nebelwasser_menge_2b_mm
  ) %>%
  
select(
  -matches("(_2b_)"),
  -matches("(_2b$)")
)

names(datos_2024_2025)

# 9. Cobertura por variable

resumen_cobertura <- datos_2024_2025 %>%
  summarise(across(everything(), ~ sum(!is.na(.)))) %>%
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "n_datos"
  ) %>%
  arrange(n_datos)

print(resumen_cobertura)

#resumen_cobertura %>%
#  filter(str_detect(variable, "nebelwasser"))

# Guardar:
write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_780_2024-2025.csv"
)

# OYA862-------
ruta <- "data/oyarbide_original_v02/OYA_862/"

archivos <- list.files(
  path = ruta,
  pattern = "\\.xlsx$",
  full.names = TRUE
)


archivos <- archivos[str_detect(archivos, "2024|2025")]

print(archivos)

lista_df <- purrr::map(
  archivos,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(archivo_origen = basename(.x))
)

columnas_por_archivo <- map(lista_df, names)

# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)

glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)




# CONSOLIDAR VARIABLES MULTISENSOR SIN PERDER VARIABLES ÚNICAS

datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    
    # TEMPERATURA AIRE (°C)
    luft_temperatur_c = rowMeans(
      cbind(
        luft_temperatur_2c_c,
        luft_temperatur_2a_c,
        luft_temperatur_1c_c
      ),
      na.rm = TRUE
    ),
    
    # HUMEDAD RELATIVA AIRE (%)
    luft_feuchte_percent = rowMeans(
      cbind(
        luft_feuchte_2c_percent,
        luft_feuchte_2a_percent,
        luft_feuchte_1c_percent
      ),
      na.rm = TRUE
    ),
    
    # VELOCIDAD DEL VIENTO (m/s)
    wind_geschwindigkeit_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_2c_m_s,
        wind_geschwindigkeit_2a_m_s,
        wind_geschwindigkeit_1c_m_s
      ),
      na.rm = TRUE
    ),
    
    # DIRECCIÓN DEL VIENTO (°)
    wind_richtung = rowMeans(
      cbind(
        wind_richtung_2c,
        wind_richtung_2a,
        wind_richtung_1c
      ),
      na.rm = TRUE
    ),
    
    # DESVIACIONES ESTÁNDAR
    wind_geschwindigkeit_standardabweichung_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_standardabweichung_2c_m_s,
        wind_geschwindigkeit_standardabweichung_2a_m_s,
        wind_geschwindigkeit_standardabweichung_1c_m_s
      ),
      na.rm = TRUE
    ),
    
    wind_richtung_standardabweichung = rowMeans(
      cbind(
        wind_richtung_standardabweichung_2c,
        wind_richtung_standardabweichung_2a,
        wind_richtung_standardabweichung_1c
      ),
      na.rm = TRUE
    ),
    
    # HUMEDAD DE HOJA (%)
    umwelt_blatt_feuchte_percent = rowMeans(
      cbind(
        umwelt_blatt_feuchte_2c_percent,
        umwelt_blatt_feuchte_2a_percent,
        umwelt_blatt_feuchte_1c_percent
      ),
      na.rm = TRUE
    ),
    
    # NIEBLA (UNIDADES DISTINTAS → SEPARADAS)
    niederschlag_nebelwasser_ml = rowMeans(
      cbind(
        niederschlag_nebelwasser_menge_2c_ml,
        niederschlag_nebelwasser_menge_2a_ml,
        niederschlag_nebelwasser_menge_1c_ml
      ),
      na.rm = TRUE
    ),
    
    niederschlag_nebelwasser_ml = niederschlag_nebelwasser_menge_1c_ml
  ) %>%
  
# ELIMINAR SOLO COLUMNAS DE SENSORES (_2a, _2c, _1c)
select(
  -matches("(_2a_|_2c_|_1c_)"),
  -matches("(_2a$|_2c$|_1c$)")
)



names(datos_2024_2025)

write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_862_2024-2025.csv"
)


# OYA1069 -------
library(tidyverse)
library(janitor)
library(readxl)

ruta <- "data/oyarbide_original_v02/OYA_1069/"   # <-- CAMBIA ESTA RUTA

archivos <- list.files(
  path = ruta,
  pattern = "2024|2025.*\\.xlsx$",
  full.names = TRUE
)

print(archivos)

# 4. Leer todos los Excel
lista_df <- map(
  archivos,
  ~ read_excel(.x) %>%
    clean_names() %>%                      # normaliza nombres
    mutate(archivo_origen = basename(.x))  # guarda archivo fuente
)

columnas_por_archivo <- map(lista_df, names)

# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)

glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)



datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    
    # TEMPERATURA AIRE (°C)
    luft_temperatur_c = luft_temperatur_2a_c,
    
    # HUMEDAD RELATIVA AIRE (%)
    luft_feuchte_percent = luft_feuchte_2a_percent,
    
    # VELOCIDAD DEL VIENTO (m/s)
    wind_geschwindigkeit_m_s = wind_geschwindigkeit_2a_m_s,
    
    # DIRECCIÓN DEL VIENTO (°)
    wind_richtung = wind_richtung_2a,
    
    # DESVIACIÓN ESTÁNDAR VELOCIDAD VIENTO (m/s)
    wind_geschwindigkeit_standardabweichung_m_s =
      wind_geschwindigkeit_standardabweichung_2a_m_s,
    
    # DESVIACIÓN ESTÁNDAR DIRECCIÓN VIENTO (°)
    wind_richtung_standardabweichung =
      wind_richtung_standardabweichung_2a,
    
    # HUMEDAD DE HOJA (%)
    umwelt_blatt_feuchte_percent =
      umwelt_blatt_feuchte_2a_percent,
    
    niederschlag_nebelwasser_ml =
      niederschlag_nebelwasser_menge_2a_ml
  ) %>%
  
select(
  -matches("(_2a_)"),
  -matches("(_2a$)")
)

names(datos_2024_2025)

# Guardar:
write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_1069_2024-2025.csv"
)


# OYA1128 -------
library(tidyverse)
library(janitor)
library(readxl)

ruta <- "data/oyarbide_original_v02/OYA_1128/"   # <-- CAMBIA ESTA RUTA

archivos <- list.files(
  path = ruta,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

archivos <- archivos[str_detect(archivos, "2024|2025")]

print(archivos)

lista_df <- purrr::map(
  archivos,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(archivo_origen = basename(.x))
)

columnas_por_archivo <- map(lista_df, names)

# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)

glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(datos_2024_2025)


datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    
  
    luft_temperatur_c = rowMeans(
      cbind(
        luft_temperatur_1a_c,
        luft_temperatur_1b_c
      ),
      na.rm = TRUE
    ),
    
    
    luft_feuchte_percent = rowMeans(
      cbind(
        luft_feuchte_1a_percent,
        luft_feuchte_1b_percent
      ),
      na.rm = TRUE
    ),
    
 
    wind_geschwindigkeit_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_1a_m_s,
        wind_geschwindigkeit_1b_m_s
      ),
      na.rm = TRUE
    ),
    
    
    wind_richtung = rowMeans(
      cbind(
        wind_richtung_1a,
        wind_richtung_1b
      ),
      na.rm = TRUE
    ),
    
   
    wind_geschwindigkeit_standardabweichung_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_standardabweichung_1a_m_s,
        wind_geschwindigkeit_standardabweichung_1b_m_s
      ),
      na.rm = TRUE
    ),
    
    wind_richtung_standardabweichung = rowMeans(
      cbind(
        wind_richtung_standardabweichung_1a,
        wind_richtung_standardabweichung_1b
      ),
      na.rm = TRUE
    ),
    
    
    umwelt_blatt_feuchte_percent = rowMeans(
      cbind(
        umwelt_blatt_feuchte_1a_percent,
        umwelt_blatt_feuchte_1b_percent
      ),
      na.rm = TRUE
    ),
    
    # NIEBLA (UNIDADES DISTINTAS → SEPARADAS)
    niederschlag_nebelwasser_mm = niederschlag_nebelwasser_menge_1a_mm,
    
    niederschlag_nebelwasser_ml = rowMeans(
      cbind(
        niederschlag_nebelwasser_menge_1a_ml,
        niederschlag_nebelwasser_menge_1b_ml
      ),
      na.rm = TRUE
    )
  ) %>%
  
  
select(
  -matches("(_1a_|_1b_)"),
  -matches("(_1a$|_1b$)")
)


names(datos_2024_2025)

# Guardar:
write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_1128_2024-2025.csv"
)


# OYA1193 -------
library(tidyverse)
library(janitor)
library(readxl)

ruta <- "data/oyarbide_original_v02/OYA_1193/"   # <-- CAMBIA ESTA RUTA

archivos <- list.files(
  path = ruta,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

archivos <- archivos[str_detect(archivos, "2024|2025")]

print(archivos)

lista_df <- purrr::map(
  archivos,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(archivo_origen = basename(.x))
)

columnas_por_archivo <- map(lista_df, names)

# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)

glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(datos_2024_2025)

datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    

    luft_temperatur_c = rowMeans(
      cbind(
        luft_temperatur_1c_c,
        luft_temperatur_1b_c
      ),
      na.rm = TRUE
    ),
    

    luft_feuchte_percent = rowMeans(
      cbind(
        luft_feuchte_1c_percent,
        luft_feuchte_1b_percent
      ),
      na.rm = TRUE
    ),
    

    wind_geschwindigkeit_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_1c_m_s,
        wind_geschwindigkeit_1b_m_s
      ),
      na.rm = TRUE
    ),
    

    wind_richtung = rowMeans(
      cbind(
        wind_richtung_1c,
        wind_richtung_1b
      ),
      na.rm = TRUE
    ),
    
   
    wind_geschwindigkeit_standardabweichung_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_standardabweichung_1c_m_s,
        wind_geschwindigkeit_standardabweichung_1b_m_s
      ),
      na.rm = TRUE
    ),
    
   
    wind_richtung_standardabweichung = rowMeans(
      cbind(
        wind_richtung_standardabweichung_1c,
        wind_richtung_standardabweichung_1b
      ),
      na.rm = TRUE
    ),
    
   
    umwelt_blatt_feuchte_percent = rowMeans(
      cbind(
        umwelt_blatt_feuchte_1c_percent,
        umwelt_blatt_feuchte_1b_percent
      ),
      na.rm = TRUE
    ),
    
   
    niederschlag_nebelwasser_ml = niederschlag_nebelwasser_menge_1c_ml,
    niederschlag_nebelwasser_mm = niederschlag_nebelwasser_menge_1b_mm
  ) %>%
  
select(
  -matches("(_1b_|_1c_)"),
  -matches("(_1b$|_1c$)")
)

names(datos_2024_2025)

# Guardar:
write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_1193_2024-2025.csv"
)


# OYA1211 -------
library(tidyverse)
library(janitor)
library(readxl)

ruta <- "data/oyarbide_original_v02/OYA_1211/"   # <-- CAMBIA ESTA RUTA

archivos <- list.files(
  path = ruta,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

archivos <- archivos[str_detect(archivos, "2024|2025")]

print(archivos)

lista_df <- purrr::map(
  archivos,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(archivo_origen = basename(.x))
)

columnas_por_archivo <- map(lista_df, names)

# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)

glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(datos_2024_2025)


datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    
  
    wind_geschwindigkeit_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_m_s,
        wind_geschwindigkeit_compact_m_s,
        wind_geschwindigkeit2_m_s
      ),
      na.rm = TRUE
    ),
    
    wind_richtung = rowMeans(
      cbind(
        wind_richtung,
        wind_richtung_compact,
        wind_richtung2
      ),
      na.rm = TRUE
    ),
    
    wind_geschwindigkeit_standardabweichung_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_standardabweichung_m_s,
        wind_geschwindigkeit_standardabweichung_compact_m_s,
        wind_geschwindigkeit_standardabweichung2_m_s
      ),
      na.rm = TRUE
    ),
    
    wind_richtung_standardabweichung = rowMeans(
      cbind(
        wind_richtung_standardabweichung,
        wind_richtung_standardabweichung_compact,
        wind_richtung_standardabweichung2
      ),
      na.rm = TRUE
    ),
    

    oberflaeche_temperatur_c = rowMeans(
      cbind(
        oberflaeche_temperatur_1_c,
        oberflaeche_temperatur_2_c
      ),
      na.rm = TRUE
    ),
    
    niederschlag_nebelwasser_ml = rowMeans(
      cbind(
        niederschlag_nebelwasser_menge_ml,
        niederschlag_nebelwasser_menge2_ml,
        niederschlag_nebelwasser_menge_1c_ml
      ),
      na.rm = TRUE
    ),
    
     niederschlag_tauwasser_ml = niederschlag_tauwasser_menge_ml
  ) %>%
  

select(
  -wind_geschwindigkeit_compact_m_s,
  -wind_richtung_compact,
  -wind_geschwindigkeit_standardabweichung_compact_m_s,
  -wind_richtung_standardabweichung_compact,
  -wind_geschwindigkeit2_m_s,
  -wind_richtung2,
  -wind_geschwindigkeit_standardabweichung2_m_s,
  -wind_richtung_standardabweichung2,
  -oberflaeche_temperatur_1_c,
  -oberflaeche_temperatur_2_c,
  -niederschlag_nebelwasser_menge_ml,
  -niederschlag_nebelwasser_menge2_ml,
  -niederschlag_nebelwasser_menge_1c_ml,
  -niederschlag_tauwasser_menge_ml,
  -unnamed_3_nan
)

names(datos_2024_2025)

# datos_2024_2025 <- datos_2024_2025 %>%
#   mutate(
#     
#     # Colapsar TODOS los sensores de niebla en mm
#     niederschlag_nebelwasser_mm = rowMeans(
#       cbind(
#         niederschlag_nebelwasser_menge_mm,
#         niederschlag_nebelwasser_menge_1c_mm
#       ),
#       na.rm = TRUE
#     )
#   ) %>%
#   
#   # Eliminar columnas crudas de niebla en mm
#   select(
#     -niederschlag_nebelwasser_menge_mm,
#     -niederschlag_nebelwasser_menge_1c_mm
#   )

datos_2024_2025 <- datos_2024_2025 %>% 
  rename(niederschlag_tauwasser_mm = niederschlag_tauwasser_menge_mm,
         niederschlag_nebelwasser_mm = niederschlag_nebelwasser_menge_mm
         )

names(datos_2024_2025)

# Guardar:
write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_1211_2024-2025.csv"
)


# OYA1354 -------
library(tidyverse)
library(janitor)
library(readxl)

ruta <- "data/oyarbide_original_v02/OYA_1354/"   # <-- CAMBIA ESTA RUTA

archivos <- list.files(
  path = ruta,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

archivos <- archivos |>
  (\(x) x[!grepl("^~\\$", basename(x))])() |>
  (\(x) x[str_detect(x, "2024|2025")])()

print(archivos)

lista_df <- purrr::map(
  archivos,
  ~ readxl::read_excel(.x, col_types = "text") %>% 
    janitor::clean_names() %>%
    dplyr::mutate(archivo_origen = basename(.x))
)


columnas_por_archivo <- map(lista_df, names)


# Tabla resumen
tabla_columnas <- tibble(
  archivo = basename(archivos),
  columnas = map_chr(columnas_por_archivo, ~ paste(.x, collapse = ", "))
)

print(tabla_columnas)

# 6. Ver TODAS las columnas existentes
todas_las_columnas <- columnas_por_archivo %>%
  unlist() %>%
  unique()

print(todas_las_columnas)

# unir
datos_2024_2025 <- bind_rows(lista_df)

glimpse(datos_2024_2025)

# crear datetime:
datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )


# Reordenar columnas (opcional pero ordenado)
datos_2024_2025 <- datos_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(datos_2024_2025)



datos_2024_2025 <- datos_2024_2025 %>%
  mutate(
    

    luft_temperatur_c = luft_temperatur_1b_c,
    

    luft_feuchte_percent = luft_feuchte_1b_percent,
    

    wind_geschwindigkeit_m_s = wind_geschwindigkeit_1b_m_s,
    

    wind_richtung = wind_richtung_1b,
    

    wind_geschwindigkeit_standardabweichung_m_s =
      wind_geschwindigkeit_standardabweichung_1b_m_s,
    

    wind_richtung_standardabweichung =
      wind_richtung_standardabweichung_1b,
    
  
    umwelt_blatt_feuchte_percent =
      umwelt_blatt_feuchte_1b_percent,
    
   
    niederschlag_nebelwasser_ml =
      niederschlag_nebelwasser_menge_1b_ml,
    
    niederschlag_nebelwasser_mm =
    niederschlag_nebelwasser_menge_1a_mm
  ) %>%
  
select(
  -matches("(_1b_)"),
  -matches("(_1b$)")
)

names(datos_2024_2025)

# Guardar:
write_csv(
  datos_2024_2025,
  "data/oyarbide_procesado_2024-2025_v02/oya_1354_2024-2025.csv"
)
