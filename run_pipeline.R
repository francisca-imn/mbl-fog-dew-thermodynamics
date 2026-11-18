# run_pipeline.R ----
#
# Reproducible pipeline of the manuscript "Thermodynamic characterization of the
# marine boundary layer during fog and dew occurrences in the hyperarid coastal
# climate of the Atacama Desert".
#
# Starting from ONE table with the 10-min records of every station of a
# topographic transect (station altitude + meteorological variables + fog and
# dew water of the main station), it:
#   1. classifies every record of the main station as fog, dew or no
#      atmospheric water (AW) occurrence (collectors + visibility + satellite FLC,
#      plus optional manual corrections);
#   2. computes pressure, potential temperature (θ), specific humidity (q) and
#      the vertical gradients relative to the coastal reference station;
#   3. writes the derived tables, the statistics, the figures of the paper and
#      the Word (.docx) reports selected in section 1.
#
# Usage, from the repository root:
#   Rscript run_pipeline.R
# (or open it in RStudio/Positron and press "Source").
#
# Requirements: R >= 4.3 with tidyverse, lubridate, patchwork, cowplot, scales,
# knitr and rmarkdown (ggplot2 >= 3.5), and Quarto >= 1.4 for the .docx reports.


suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(scales)
  library(patchwork)
  library(cowplot)
})

# 1. WHAT TO GENERATE (TRUE / FALSE) ----
# The derived tables (step 2 above) are always computed in memory; set
# `derived_tables = TRUE` to also save them as CSV in data/derived/.

outputs <- list(
  derived_tables           = TRUE,  # classification and θ/q tables (CSV, data/derived/)
  statistics_events        = TRUE,  # event-based statistics of the manuscript (results/)
  seasonal_thresholds      = TRUE,  # seasonal ∂θ/∂z values at the main station (results/)
  paper_figures_png        = TRUE,  # figures of the paper (PNG, figures/) + values (results/paper_values/)
  docx_classification      = TRUE,  # half-month panels of the daily classification
  docx_daily_profiles      = TRUE,  # one page per day: θ, q, U profiles and their ∂/∂z
  docx_temporal_tendencies = TRUE,  # mean temporal tendencies after each occurrence type
  docx_paper_figures       = TRUE   # figures of the paper with their captions
)


# 2. INPUT DATA -----
# One CSV with one row per station and 10-min time step (see the README,
# "Input table"). For Cerro Oyarbide it is built by code/prep_oyarbide/.

input_file <- "data/derived/transect_10min_2024.csv"

# Column names in the input file (right) for each variable used (left).
# Set an optional column to NA if it does not exist (e.g. flc = NA).
columns <- c(
  datetime    = "datetime",     # time stamp, UTC
  station     = "station",      # station name
  z_m         = "z_m",          # station altitude (m a.s.l.)
  temperature = "temperature",  # air temperature (°C)
  rh          = "rh",           # relative humidity (%)
  pressure    = "pressure",     # measured pressure (hPa); NA where not measured
  wind_speed  = "wind_speed",   # wind speed (m s-1)
  radiation   = "radiation",    # global radiation (W m-2), main station (day/night split)
  visibility  = "visibility",   # horizontal visibility (m), main station
  fog_water   = "fog_water",    # standard fog collector water (mL m-2), main station
  dew_water   = "dew_water",    # standard dew collector water (mL m-2), main station
  flc         = "flc"           # satellite fog and low clouds detection (0/1), main station (optional)
)

year              <- 2024           # year analysed
reference_station <- "AEROPUERTO"   # coastal reference: base of the gradients and of θ
main_station      <- "OYA_1211"     # station with collectors and visibility sensor
excluded_stations <- c("OYA_1069")  # stations left out of the gradients/profiles (no valid data)

# Classification thresholds (manuscript, Eq. 1)
visibility_fog_threshold <- 1000    # m: fog if visibility < threshold, dew otherwise
night_radiation_max      <- 5       # W m-2: night if global radiation <= value

# Manual corrections of the classification (.R defining `manual_corrections`,
# or .csv with columns start, end, occurrence). NULL = no manual corrections.
manual_corrections_file <- "code/config/manual_corrections_oya1211_2024.R"


# 3. OUTPUT FILES AND FOLDERS ------
output_classification <- "data/derived/oya1211_classification_2024.csv"
output_thermodynamics <- "data/derived/stations_theta_q_2024.csv"
dir_figures <- "figures"             # PNG figures of the paper
dir_results <- "results"             # statistics and tables
dir_reports <- "output"              # .docx reports (not versioned, see .gitignore)


# 4. OPTIONS OF THE .DOCX REPORTS -----
# Days in the daily reports (classification and vertical profiles):
#   "aw"  = only days with at least one fog or dew record at the main station
#   "all" = every day of the year
#   or a vector of dates, e.g. as.Date(c("2024-04-24", "2024-04-28"))
daily_days <- "aw"

daily_dpi  <- 150   # resolution of the daily figures (300 gives very large files)
report_dpi <- 300   # resolution of the figures of the other reports

# Reference lines in the daily gradient profiles (K m-1 and g kg-1 m-1):
# event-based ROC cut-offs of the manuscript (Table 2)
threshold_lines <- list(
  grad_theta = c(0.0037, 0.0057),   # fog | dew | no AW
  grad_q     = c(-0.0021)           # AW | no AW
)

# Stations of the "tendencies per station" sections (NULL = all with data)
tendency_stations <- NULL


# ------------------------------------------------------------------------------
# 5. SETTINGS OF THE PAPER FIGURES (specific to the manuscript)
# ------------------------------------------------------------------------------
paper <- list(
  # Figure 3 and A1: typical days and particular cases (labels: plotmath)
  typical_days = tribble(
    ~date,        ~group,    ~label,
    "2024-04-28", "fog",     'bold("(A) April 28"^"th"*" (fog)")',
    "2024-09-21", "fog",     'bold("(B) September 21"^"st"*" (fog)")',
    "2024-04-24", "dew",     'bold("(C) April 24"^"th"*" (dew)")',
    "2024-11-28", "dew",     'bold("(D) November 28"^"th"*" (dew)")',
    "2024-08-11", "other",   'bold("August 11"^"th"*" (no AW)")',
    "2024-05-17", "other",   'bold("May 17"^"th"*" (particular case)")',
    "2024-06-27", "other",   'bold("June 27"^"th"*" (particular case)")'
  ),
  # Figure 4: offset of the local time axis
  fig04_local_offset = -3, fig04_local_label = "Chile local time (approx., UTC-3)",
  # Figure 5: typical fog and dew days of the vertical profiles
  profile_days = tribble(
    ~date,        ~label,
    "2024-04-28", 'bold("April 28"^"th"*", 2024 (fog)")',
    "2024-04-24", 'bold("April 24"^"th"*", 2024 (dew)")'
  ),
  # Figure 6: thresholds of Lobos Roco et al. (2018), units of 10^-3
  lobos_roco_grad_theta = 3.1, lobos_roco_grad_q = -1.6,
  # Figure 7: diurnal cycle on a fog night and a dew night
  diurnal_days = tribble(
    ~date,        ~fen,  ~dia_lab,            ~dia_expr,
    "2024-07-11", "Fog", "Fog, July 11th",    'bold("Fog, July 11"^"th")',
    "2024-04-10", "Dew", "Dew, April 10th",   'bold("Dew, April 10"^"th")'
  ),
  fig07_local_offset = -4, fig07_local_label = "Local time (UTC-4)",
  # Figure 7 (values only): nocturnal episodes starting in this window are left out
  fig07_exclude_episodes = c("2024-01-01", "2024-01-16"),
  # Figure 9: stations and their position relative to the cloud / MBL
  fig09_stations = c("OYA_518"  = "Below cloud base",
                     "OYA_1128" = "Fog layer (Tillandsia)",
                     "OYA_1211" = "Fog layer (Tillandsia)",
                     "OYA_1354" = "Above the MBL"),
  # Captions of the .docx of figures (figure 1 is a map and photographs, not code)
  captions_file = "code/config/paper_figure_captions.csv"
)


# ==============================================================================
# From here on nothing needs to be edited
# ==============================================================================

for (f in list.files("code/R", pattern = "\\.R$", full.names = TRUE)) source(f)

cfg <- build_config(environment())

# ---- core steps (always) -----------------------------------------------------
message("Reading ", cfg$input_file)
std <- read_standard_table(cfg)

message("Classifying fog and dew at ", cfg$main_station)
classification <- classify_occurrences(std, cfg)

message("Computing θ, q and vertical gradients")
thermo <- add_thermodynamics(std, classification, cfg)

if (cfg$outputs$derived_tables) {
  dir.create(dirname(cfg$output_classification), recursive = TRUE, showWarnings = FALSE)
  write_csv(classification, cfg$output_classification)
  write_csv(thermo, cfg$output_thermodynamics)
  message("Saved ", cfg$output_classification, " and ", cfg$output_thermodynamics)
}

# ---- statistics --------------------------------------------------------------
if (cfg$outputs$statistics_events) {
  message("Event-based statistics")
  event_statistics(thermo, cfg)
}
if (cfg$outputs$seasonal_thresholds) {
  message("Seasonal ∂θ/∂z values")
  seasonal_thresholds(thermo, cfg)
}

# ---- paper figures (PNG) -----------------------------------------------------
if (cfg$outputs$paper_figures_png) {
  message("Paper figures")
  make_paper_figures(classification, thermo, cfg)
}

# ---- .docx reports (Quarto) --------------------------------------------------
reports <- c(docx_classification      = "classification_daily",
             docx_daily_profiles      = "vertical_profiles_daily",
             docx_temporal_tendencies = "temporal_tendencies",
             docx_paper_figures       = "paper_figures")
reports <- reports[unlist(cfg$outputs[names(reports)])]

if (length(reports) > 0) {
  cache <- save_report_cache(classification, thermo, cfg)
  for (r in reports) render_report(r, cache, cfg)
}

message("Done.")
