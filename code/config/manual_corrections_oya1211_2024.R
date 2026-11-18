# ==============================================================================
# Manual corrections of the automatic fog/dew classification at OYA1211 (2024)
#
# Time windows (UTC) reclassified after the day-by-day visual review of the
# visibility curve and the GOES-16 FLC signal (see the classification docx).
# A correction only applies to records where at least one collector registered
# water. Windows are applied in order, so a later window overrides an earlier
# one where they overlap. This file is read by run_pipeline.R
# (setting `manual_corrections_file`); it must define `manual_corrections`
# with the columns start, end (POSIXct, UTC) and occurrence ("NIEBLA"/"ROCIO").
# A CSV file with the same three columns is also accepted.
# ==============================================================================

manual_corrections <- tribble(
  ~start, ~end, ~occurrence,

  ymd_hms("2024-01-02 02:00:00", tz = "UTC"),
  ymd_hms("2024-01-02 03:30:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-01-02 10:00:00", tz = "UTC"),
  ymd_hms("2024-01-02 12:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-01-08 10:00:00", tz = "UTC"),
  ymd_hms("2024-01-08 12:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-01-11 03:00:00", tz = "UTC"),
  ymd_hms("2024-01-11 06:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-01-15 09:00:00", tz = "UTC"),
  ymd_hms("2024-01-15 12:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-02-03 02:00:00", tz = "UTC"),
  ymd_hms("2024-02-03 05:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-01-28 12:00:00", tz = "UTC"),
  ymd_hms("2024-01-28 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-01-31 09:00:00", tz = "UTC"),
  ymd_hms("2024-01-31 22:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-02-03 07:00:00", tz = "UTC"),
  ymd_hms("2024-02-03 11:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-02-04 02:00:00", tz = "UTC"),
  ymd_hms("2024-02-04 12:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-02-12 06:00:00", tz = "UTC"),
  ymd_hms("2024-02-12 10:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-02-17 05:00:00", tz = "UTC"),
  ymd_hms("2024-02-17 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-02-18 11:00:00", tz = "UTC"),
  ymd_hms("2024-02-18 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-02-19 04:00:00", tz = "UTC"),
  ymd_hms("2024-02-19 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-02-28 10:00:00", tz = "UTC"),
  ymd_hms("2024-02-28 13:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-03-07 08:00:00", tz = "UTC"),
  ymd_hms("2024-03-07 14:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-03-09 01:00:00", tz = "UTC"),
  ymd_hms("2024-03-09 13:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-03-09 08:00:00", tz = "UTC"),
  ymd_hms("2024-03-09 15:00:00", tz = "UTC"),
  "NIEBLA",

  # uncertain day(s): 10 March

  ymd_hms("2024-03-13 04:00:00", tz = "UTC"),
  ymd_hms("2024-03-13 16:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-03-16 06:00:00", tz = "UTC"),
  ymd_hms("2024-03-16 08:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-03-24 14:00:00", tz = "UTC"),
  ymd_hms("2024-03-24 16:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-03-25 02:00:00", tz = "UTC"),
  ymd_hms("2024-03-25 15:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-03-26 07:00:00", tz = "UTC"),
  ymd_hms("2024-03-26 09:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-03-26 11:00:00", tz = "UTC"),
  ymd_hms("2024-03-26 14:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-02 08:00:00", tz = "UTC"),
  ymd_hms("2024-04-02 14:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-07 00:00:00", tz = "UTC"),
  ymd_hms("2024-04-07 04:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-04-07 06:00:00", tz = "UTC"),
  ymd_hms("2024-04-07 15:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-08 00:00:00", tz = "UTC"),
  ymd_hms("2024-04-08 04:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-04-09 09:00:00", tz = "UTC"),
  ymd_hms("2024-04-09 11:00:00", tz = "UTC"),
  "ROCIO",

  # NOTE: the end time below ("2024-04-1") parses as 1 April, before the start time,
  # so this window has no effect; it is kept as is to reproduce the classification
  # used in the manuscript (probably meant 2024-04-11 03:00).
  ymd_hms("2024-04-11 00:00:00", tz = "UTC"),
  ymd_hms("2024-04-1 03:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-13 08:00:00", tz = "UTC"),
  ymd_hms("2024-04-13 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-15 06:00:00", tz = "UTC"),
  ymd_hms("2024-04-15 07:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-22 14:00:00", tz = "UTC"),
  ymd_hms("2024-04-22 23:50:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-23 04:00:00", tz = "UTC"),
  ymd_hms("2024-04-23 06:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 26 April

  ymd_hms("2024-04-27 00:00:00", tz = "UTC"),
  ymd_hms("2024-04-27 14:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-04-28 04:00:00", tz = "UTC"),
  ymd_hms("2024-04-28 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-05-04 00:00:00", tz = "UTC"),
  ymd_hms("2024-05-04 05:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-05-05 00:00:00", tz = "UTC"),
  ymd_hms("2024-05-05 03:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-05-07 03:00:00", tz = "UTC"),
  ymd_hms("2024-05-07 12:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-05-08 00:00:00", tz = "UTC"),
  ymd_hms("2024-05-08 01:30:00", tz = "UTC"),
  "NIEBLA",

  # uncertain day(s): 10 May

  ymd_hms("2024-05-11 00:00:00", tz = "UTC"),
  ymd_hms("2024-05-11 23:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 12 May

  ymd_hms("2024-05-13 00:00:00", tz = "UTC"),
  ymd_hms("2024-05-13 16:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-05-16 00:00:00", tz = "UTC"),
  ymd_hms("2024-05-16 12:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 17 May

  ymd_hms("2024-05-18 00:00:00", tz = "UTC"),
  ymd_hms("2024-05-19 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-06-09 00:00:00", tz = "UTC"),
  ymd_hms("2024-06-09 23:50:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-07-08 00:00:00", tz = "UTC"),
  ymd_hms("2024-07-08 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-07-11 00:00:00", tz = "UTC"),
  ymd_hms("2024-07-11 05:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-07-18 00:00:00", tz = "UTC"),
  ymd_hms("2024-07-18 23:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 06 August

  ymd_hms("2024-08-22 06:00:00", tz = "UTC"),
  ymd_hms("2024-08-22 07:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 21 August

  ymd_hms("2024-08-30 00:00:00", tz = "UTC"),
  ymd_hms("2024-08-30 08:30:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-08-31 00:00:00", tz = "UTC"),
  ymd_hms("2024-08-31 12:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 06 September

  ymd_hms("2024-09-13 00:00:00", tz = "UTC"),
  ymd_hms("2024-09-13 08:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-10-08 00:00:00", tz = "UTC"),
  ymd_hms("2024-10-08 14:00:00", tz = "UTC"),
  "ROCIO",

  # Reclassified as NIEBLA on 2026-10-10 (manuscript v05): visibility ~500 m and
  # ~4.7 L in the fog collector during this window. It was ROCIO up to v04.
  ymd_hms("2024-10-08 16:00:00", tz = "UTC"),
  ymd_hms("2024-10-08 23:00:00", tz = "UTC"),
  "NIEBLA",

  # uncertain day(s): 09 October

  ymd_hms("2024-10-10 00:00:00", tz = "UTC"),
  ymd_hms("2024-10-10 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-10-19 00:00:00", tz = "UTC"),
  ymd_hms("2024-10-19 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-10-21 00:00:00", tz = "UTC"),
  ymd_hms("2024-10-21 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-10-31 00:00:00", tz = "UTC"),
  ymd_hms("2024-10-31 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-11-01 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-01 08:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-11-01 12:00:00", tz = "UTC"),
  ymd_hms("2024-11-01 23:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-11-02 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-02 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-11-07 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-07 23:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-11-08 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-08 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-11-09 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-09 05:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-11-09 12:00:00", tz = "UTC"),
  ymd_hms("2024-11-09 23:00:00", tz = "UTC"),
  "NIEBLA",

  # uncertain day(s): 10 October

  ymd_hms("2024-11-13 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-13 23:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-11-15 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-15 23:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 18 to 22 November

  ymd_hms("2024-11-25 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-25 05:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-11-27 10:00:00", tz = "UTC"),
  ymd_hms("2024-11-27 23:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-11-29 00:00:00", tz = "UTC"),
  ymd_hms("2024-11-29 23:00:00", tz = "UTC"),
  "ROCIO",

  ymd_hms("2024-12-03 09:00:00", tz = "UTC"),
  ymd_hms("2024-12-03 23:00:00", tz = "UTC"),
  "NIEBLA",

  # uncertain day(s): 09 December

  ymd_hms("2024-12-19 00:00:00", tz = "UTC"),
  ymd_hms("2024-12-19 13:00:00", tz = "UTC"),
  "NIEBLA",

  ymd_hms("2024-12-23 00:00:00", tz = "UTC"),
  ymd_hms("2024-12-23 23:00:00", tz = "UTC"),
  "ROCIO",

  # uncertain day(s): 27 December

  ymd_hms("2024-12-28 02:00:00", tz = "UTC"),
  ymd_hms("2024-12-28 06:00:00", tz = "UTC"),
  "ROCIO"

)
