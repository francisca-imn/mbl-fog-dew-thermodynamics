# Shared set-up of the .docx reports: packages, functions of code/R and the
# objects computed by run_pipeline.R (cache). `params` comes from Quarto.
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(scales)
  library(patchwork)
  library(knitr)
})
for (f in list.files(file.path(params$root, "code", "R"), pattern = "\\.R$", full.names = TRUE)) source(f)
pipeline <- readRDS(params$cache)
cfg <- pipeline$cfg
classification <- pipeline$classification
thermo <- pipeline$thermo
main_lab <- station_label(cfg$main_station)
ref_lab  <- station_label(cfg$reference_station)

# paths of the configuration are relative to the repository root
abs_path <- function(p) {
  if (is.null(p) || is.na(p) || grepl("^(/|~|[A-Za-z]:)", p)) p else file.path(params$root, p)
}
cfg$manual_corrections_file <- abs_path(cfg$manual_corrections_file)
cfg$dir_figures <- abs_path(cfg$dir_figures)
cfg$paper$captions_file <- abs_path(cfg$paper$captions_file)
