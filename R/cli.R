#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(DBI)
  library(jsonlite)
})

script_path <- {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NULL
}
script_dir <- if (!is.null(script_path)) dirname(normalizePath(script_path)) else getwd()

source(file.path(script_dir, "forecast.R"))
source(file.path(script_dir, "db.R"))

parse_args <- function(args) {
  parsed <- list(as_of = NULL, cohort = NULL, format = "table")
  for (arg in args) {
    if (grepl("^--as-of=", arg)) {
      parsed$as_of <- sub("^--as-of=", "", arg)
    } else if (grepl("^--cohort=", arg)) {
      parsed$cohort <- sub("^--cohort=", "", arg)
    } else if (grepl("^--format=", arg)) {
      parsed$format <- sub("^--format=", "", arg)
    }
  }
  parsed
}

run_cli <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  as_of <- if (is.null(args$as_of)) Sys.Date() else as.Date(args$as_of)

  conn <- get_db_connection()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  cohorts <- DBI::dbGetQuery(
    conn,
    "SELECT cohort_id, name, start_date, end_date FROM groupscholar_yield_forecast.cohorts ORDER BY start_date"
  )

  offers <- DBI::dbGetQuery(
    conn,
    "SELECT offer_id, cohort_id, offer_date, accepted_at FROM groupscholar_yield_forecast.offers"
  )

  forecast <- compute_yield_forecast(cohorts, offers, as_of = as_of)

  if (!is.null(args$cohort)) {
    forecast <- forecast[forecast$name == args$cohort, , drop = FALSE]
  }

  if (args$format == "json") {
    cat(jsonlite::toJSON(forecast, pretty = TRUE, na = "null"))
  } else {
    print(forecast[, c("name", "status", "offers_count", "accepted_count", "acceptance_rate", "baseline_rate", "forecast_acceptances")])
  }
}

if (sys.nframe() == 0) {
  run_cli()
}
