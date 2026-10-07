# ==============================================================================
# 01_merge_station_files.R
#
# Step 1 of the pipeline. Reads the original monthly Excel files of each
# Cerro Oyarbide station (data/raw/stations_xlsx/OYA_<elevation>/), merges them
# into a single 10-min series per station (2024-2025) and saves one CSV per
# station in data/stations/. Column names are kept as delivered by the station
# loggers (German, normalised with janitor::clean_names()).
#
# Run from the project root (open mbl-fog-dew-thermodynamics.Rproj).
# ==============================================================================

# OYA518 -------
library(tidyverse)
library(janitor)
library(readxl)

dir_station <- "data/raw/stations_xlsx/OYA_518/"

files <- list.files(
  path = dir_station,
  pattern = "2024|2025.*\\.xlsx$",
  full.names = TRUE
)

print(files)

# Read all monthly Excel files of the station
df_list <- map(
  files,
  ~ read_excel(.x) %>%
    clean_names() %>%                      # normalise column names
    mutate(source_file = basename(.x))  # keep the source file name
)

cols_per_file <- map(df_list, names)

# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)

glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(data_2024_2025)

data_2024_2025 <- data_2024_2025 %>%
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

names(data_2024_2025)

# Coverage per variable

coverage_summary <- data_2024_2025 %>%
  summarise(across(everything(), ~ sum(!is.na(.)))) %>%
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "n_values"
  ) %>%
  arrange(n_values)

print(coverage_summary)

coverage_summary %>%
  filter(str_detect(variable, "nebelwasser"))

# Save the processed station file:
write_csv(
  data_2024_2025,
  "data/stations/oya_518_2024-2025.csv"
)

# OYA780 -------
dir_station <- "data/raw/stations_xlsx/OYA_780/"

files <- list.files(
  path = dir_station,
  pattern = "2024|2025.*\\.xlsx$",
  full.names = TRUE
)

print(files)

# Read all monthly Excel files of the station
df_list <- map(
  files,
  ~ read_excel(.x) %>%
    clean_names() %>%                      # normalise column names
    mutate(source_file = basename(.x))  # keep the source file name
)

cols_per_file <- map(df_list, names)

# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)


glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(data_2024_2025)


data_2024_2025 <- data_2024_2025 %>%
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

names(data_2024_2025)

# Coverage per variable

coverage_summary <- data_2024_2025 %>%
  summarise(across(everything(), ~ sum(!is.na(.)))) %>%
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "n_values"
  ) %>%
  arrange(n_values)

print(coverage_summary)

#coverage_summary %>%
#  filter(str_detect(variable, "nebelwasser"))

# Save the processed station file:
write_csv(
  data_2024_2025,
  "data/stations/oya_780_2024-2025.csv"
)

# OYA862-------
dir_station <- "data/raw/stations_xlsx/OYA_862/"

files <- list.files(
  path = dir_station,
  pattern = "\\.xlsx$",
  full.names = TRUE
)


files <- files[str_detect(files, "2024|2025")]

print(files)

df_list <- purrr::map(
  files,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(source_file = basename(.x))
)

cols_per_file <- map(df_list, names)

# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)

glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)




# MERGE MULTI-SENSOR VARIABLES WITHOUT LOSING UNIQUE VARIABLES

data_2024_2025 <- data_2024_2025 %>%
  mutate(
    
    # AIR TEMPERATURE (°C)
    luft_temperatur_c = rowMeans(
      cbind(
        luft_temperatur_2c_c,
        luft_temperatur_2a_c,
        luft_temperatur_1c_c
      ),
      na.rm = TRUE
    ),
    
    # AIR RELATIVE HUMIDITY (%)
    luft_feuchte_percent = rowMeans(
      cbind(
        luft_feuchte_2c_percent,
        luft_feuchte_2a_percent,
        luft_feuchte_1c_percent
      ),
      na.rm = TRUE
    ),
    
    # WIND SPEED (m/s)
    wind_geschwindigkeit_m_s = rowMeans(
      cbind(
        wind_geschwindigkeit_2c_m_s,
        wind_geschwindigkeit_2a_m_s,
        wind_geschwindigkeit_1c_m_s
      ),
      na.rm = TRUE
    ),
    
    # WIND DIRECTION (°)
    wind_richtung = rowMeans(
      cbind(
        wind_richtung_2c,
        wind_richtung_2a,
        wind_richtung_1c
      ),
      na.rm = TRUE
    ),
    
    # STANDARD DEVIATIONS
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
    
    # LEAF WETNESS (%)
    umwelt_blatt_feuchte_percent = rowMeans(
      cbind(
        umwelt_blatt_feuchte_2c_percent,
        umwelt_blatt_feuchte_2a_percent,
        umwelt_blatt_feuchte_1c_percent
      ),
      na.rm = TRUE
    ),
    
    # FOG WATER (DIFFERENT UNITS, KEPT SEPARATE)
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
  
# DROP ONLY THE INDIVIDUAL SENSOR COLUMNS (_2a, _2c, _1c)
select(
  -matches("(_2a_|_2c_|_1c_)"),
  -matches("(_2a$|_2c$|_1c$)")
)



names(data_2024_2025)

write_csv(
  data_2024_2025,
  "data/stations/oya_862_2024-2025.csv"
)


# OYA1069 -------
library(tidyverse)
library(janitor)
library(readxl)

dir_station <- "data/raw/stations_xlsx/OYA_1069/"

files <- list.files(
  path = dir_station,
  pattern = "2024|2025.*\\.xlsx$",
  full.names = TRUE
)

print(files)

# Read all monthly Excel files of the station
df_list <- map(
  files,
  ~ read_excel(.x) %>%
    clean_names() %>%                      # normalise column names
    mutate(source_file = basename(.x))  # keep the source file name
)

cols_per_file <- map(df_list, names)

# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)

glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)



data_2024_2025 <- data_2024_2025 %>%
  mutate(
    
    # AIR TEMPERATURE (°C)
    luft_temperatur_c = luft_temperatur_2a_c,
    
    # AIR RELATIVE HUMIDITY (%)
    luft_feuchte_percent = luft_feuchte_2a_percent,
    
    # WIND SPEED (m/s)
    wind_geschwindigkeit_m_s = wind_geschwindigkeit_2a_m_s,
    
    # WIND DIRECTION (°)
    wind_richtung = wind_richtung_2a,
    
    # WIND SPEED STANDARD DEVIATION (m/s)
    wind_geschwindigkeit_standardabweichung_m_s =
      wind_geschwindigkeit_standardabweichung_2a_m_s,
    
    # WIND DIRECTION STANDARD DEVIATION (°)
    wind_richtung_standardabweichung =
      wind_richtung_standardabweichung_2a,
    
    # LEAF WETNESS (%)
    umwelt_blatt_feuchte_percent =
      umwelt_blatt_feuchte_2a_percent,
    
    niederschlag_nebelwasser_ml =
      niederschlag_nebelwasser_menge_2a_ml
  ) %>%
  
select(
  -matches("(_2a_)"),
  -matches("(_2a$)")
)

names(data_2024_2025)

# Save the processed station file:
write_csv(
  data_2024_2025,
  "data/stations/oya_1069_2024-2025.csv"
)


# OYA1128 -------
library(tidyverse)
library(janitor)
library(readxl)

dir_station <- "data/raw/stations_xlsx/OYA_1128/"

files <- list.files(
  path = dir_station,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

files <- files[str_detect(files, "2024|2025")]

print(files)

df_list <- purrr::map(
  files,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(source_file = basename(.x))
)

cols_per_file <- map(df_list, names)

# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)

glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(data_2024_2025)


data_2024_2025 <- data_2024_2025 %>%
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
    
    # FOG WATER (DIFFERENT UNITS, KEPT SEPARATE)
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


names(data_2024_2025)

# Save the processed station file:
write_csv(
  data_2024_2025,
  "data/stations/oya_1128_2024-2025.csv"
)


# OYA1193 -------
library(tidyverse)
library(janitor)
library(readxl)

dir_station <- "data/raw/stations_xlsx/OYA_1193/"

files <- list.files(
  path = dir_station,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

files <- files[str_detect(files, "2024|2025")]

print(files)

df_list <- purrr::map(
  files,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(source_file = basename(.x))
)

cols_per_file <- map(df_list, names)

# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)

glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(data_2024_2025)

data_2024_2025 <- data_2024_2025 %>%
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

names(data_2024_2025)

# Save the processed station file:
write_csv(
  data_2024_2025,
  "data/stations/oya_1193_2024-2025.csv"
)


# OYA1211 -------
library(tidyverse)
library(janitor)
library(readxl)

dir_station <- "data/raw/stations_xlsx/OYA_1211/"

files <- list.files(
  path = dir_station,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

files <- files[str_detect(files, "2024|2025")]

print(files)

df_list <- purrr::map(
  files,
  ~ readxl::read_excel(.x) %>%
    janitor::clean_names() %>%
    dplyr::mutate(source_file = basename(.x))
)

cols_per_file <- map(df_list, names)

# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)

glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )

# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(data_2024_2025)


data_2024_2025 <- data_2024_2025 %>%
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

names(data_2024_2025)

# data_2024_2025 <- data_2024_2025 %>%
#   mutate(
#     
#     # Collapse ALL fog sensors in mm
#     niederschlag_nebelwasser_mm = rowMeans(
#       cbind(
#         niederschlag_nebelwasser_menge_mm,
#         niederschlag_nebelwasser_menge_1c_mm
#       ),
#       na.rm = TRUE
#     )
#   ) %>%
#   
#   # Drop raw fog columns in mm
#   select(
#     -niederschlag_nebelwasser_menge_mm,
#     -niederschlag_nebelwasser_menge_1c_mm
#   )

data_2024_2025 <- data_2024_2025 %>% 
  rename(niederschlag_tauwasser_mm = niederschlag_tauwasser_menge_mm,
         niederschlag_nebelwasser_mm = niederschlag_nebelwasser_menge_mm
         )

names(data_2024_2025)

# Save the processed station file:
write_csv(
  data_2024_2025,
  "data/stations/oya_1211_2024-2025.csv"
)


# OYA1354 -------
library(tidyverse)
library(janitor)
library(readxl)

dir_station <- "data/raw/stations_xlsx/OYA_1354/"

files <- list.files(
  path = dir_station,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

files <- files |>
  (\(x) x[!grepl("^~\\$", basename(x))])() |>
  (\(x) x[str_detect(x, "2024|2025")])()

print(files)

df_list <- purrr::map(
  files,
  ~ readxl::read_excel(.x, col_types = "text") %>% 
    janitor::clean_names() %>%
    dplyr::mutate(source_file = basename(.x))
)


cols_per_file <- map(df_list, names)


# Summary table of columns per file
cols_table <- tibble(
  file = basename(files),
  columns_found = map_chr(cols_per_file, ~ paste(.x, collapse = ", "))
)

print(cols_table)

# List ALL existing columns
all_columns <- cols_per_file %>%
  unlist() %>%
  unique()

print(all_columns)

# Bind all files
data_2024_2025 <- bind_rows(df_list)

glimpse(data_2024_2025)

# Build datetime:
data_2024_2025 <- data_2024_2025 %>%
  mutate(
    datetime = as.POSIXct(
      paste(date, time),
      format = "%d.%m.%y %H:%M:%S",
      tz = "UTC"
    )
  )


# Reorder columns (optional, for readability)
data_2024_2025 <- data_2024_2025 %>%
  relocate(datetime, date, time, .before = everything()) %>% 
  arrange(datetime)

names(data_2024_2025)



data_2024_2025 <- data_2024_2025 %>%
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

names(data_2024_2025)

# Save the processed station file:
write_csv(
  data_2024_2025,
  "data/stations/oya_1354_2024-2025.csv"
)
