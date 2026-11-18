# ==============================================================================
# 03_standard_table.R
#
# Step 3 of the Cerro Oyarbide data preparation. Converts the 10-min dataset of
# step 2 (data/derived/stations_10min_2024.csv: one row per station and time
# step, with the GOES-16 FLC signal stored as a separate pseudo-station "GOES")
# into the standard input table of run_pipeline.R:
#
#   data/derived/transect_10min_2024.csv
#
# One row per station and 10-min time step, with the station altitude (z_m)
# and every variable used in the analysis (English column names):
#
#   datetime     time stamp (UTC)
#   station      station name
#   z_m          station altitude (m a.s.l.)
#   temperature  air temperature (°C)
#   rh           relative humidity (%)
#   pressure     measured air pressure (hPa); NA where not measured
#   wind_speed   wind speed (m s-1)
#   radiation    global radiation (W m-2)                    [main station]
#   visibility   horizontal visibility (m)                   [main station]
#   fog_water    water of the standard fog collector (mL m-2) [main station]
#   dew_water    water of the standard dew collector (mL m-2) [main station]
#   flc          GOES-16 fog and low cloud detection (0/1)   [main station]
#
# The FLC signal is attached to the rows of the main station (OYA_1211) by the
# 10-min time step (floor of the time stamp), as in the original classification.
# The cleaning rules of step 2 (zero temperature, pressure and wind speed and
# visibility below 0.4 m treated as missing) are already applied.
#
# Run from the repository root:  Rscript code/prep_oyarbide/03_standard_table.R
# ==============================================================================

library(tidyverse)
library(lubridate)

input_file  <- "data/derived/stations_10min_2024.csv"
output_file <- "data/derived/transect_10min_2024.csv"
main_station <- "OYA_1211"

elevations <- tribble(
  ~station,     ~z_m,
  "AEROPUERTO",   48,   # coastal reference (Diego Aracena airport)
  "OYA_518",     518,
  "OYA_780",     780,
  "OYA_862",     862,
  "OYA_1069",   1069,
  "OYA_1128",   1128,
  "OYA_1193",   1193,
  "OYA_1211",   1211,
  "OYA_1354",   1354
)

dat <- read_csv(input_file, show_col_types = FALSE) %>%
  mutate(datetime = as.POSIXct(datetime, tz = "UTC"))

goes <- dat %>%
  filter(estacion == "GOES") %>%
  transmute(ts_10 = datetime, flc = FLC)

standard <- dat %>%
  filter(estacion != "GOES") %>%
  transmute(
    datetime,
    station     = estacion,
    temperature = temperatura,
    rh          = humedad,
    pressure    = presion,
    wind_speed  = viento_vel_m_s,
    radiation   = radiacion_w_m2,
    visibility  = visibilidad,
    fog_water   = niebla_final,
    dew_water   = rocio_final
  ) %>%
  left_join(elevations, by = "station") %>%
  mutate(ts_10 = floor_date(datetime, "10 minutes")) %>%
  left_join(goes, by = "ts_10") %>%
  mutate(flc = if_else(station == main_station, flc, NA_real_)) %>%
  select(datetime, station, z_m, temperature, rh, pressure, wind_speed,
         radiation, visibility, fog_water, dew_water, flc)
# (the row order of step 2 is kept: the bootstrap resamples of the statistics
#  depend on it, so changing it changes the confidence intervals slightly)

stopifnot(!anyNA(standard$z_m))

write_csv(standard, output_file)
cat("Saved", output_file, "with", nrow(standard), "rows and",
    n_distinct(standard$station), "stations\n")
