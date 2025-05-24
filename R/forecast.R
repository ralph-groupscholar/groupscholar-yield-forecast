compute_yield_forecast <- function(cohorts, offers, as_of = Sys.Date(), yield_rate_override = NULL) {
  as_of <- as.Date(as_of)

  cohorts$start_date <- as.Date(cohorts$start_date)
  cohorts$end_date <- as.Date(cohorts$end_date)
  offers$offer_date <- as.Date(offers$offer_date)
  offers$accepted_at <- as.Date(offers$accepted_at)

  if (!"target_offers" %in% names(cohorts)) {
    cohorts$target_offers <- 0
  }

  offers <- offers[offers$offer_date <= as_of, , drop = FALSE]

  offer_counts <- aggregate(offer_id ~ cohort_id, offers, length)
  accepted_counts <- aggregate(!is.na(accepted_at) ~ cohort_id, offers, sum)
  names(accepted_counts)[2] <- "accepted_count"

  summary <- merge(cohorts, offer_counts, by = "cohort_id", all.x = TRUE)
  summary <- merge(summary, accepted_counts, by = "cohort_id", all.x = TRUE)

  summary$offer_id[is.na(summary$offer_id)] <- 0
  summary$accepted_count[is.na(summary$accepted_count)] <- 0
  names(summary)[names(summary) == "offer_id"] <- "offers_count"

  summary$acceptance_rate <- ifelse(
    summary$offers_count > 0,
    summary$accepted_count / summary$offers_count,
    0
  )

  summary$status <- ifelse(summary$end_date < as_of, "closed", "active")

  closed <- summary[summary$status == "closed", , drop = FALSE]
  baseline_rate <- if (nrow(closed) > 0 && sum(closed$offers_count) > 0) {
    sum(closed$accepted_count) / sum(closed$offers_count)
  } else {
    0.5
  }

  if (!is.null(yield_rate_override)) {
    baseline_rate <- max(min(yield_rate_override, 1), 0)
  }

  summary$forecast_acceptances <- ifelse(
    summary$status == "closed",
    summary$accepted_count,
    round(summary$offers_count * baseline_rate)
  )

  summary$baseline_rate <- ifelse(summary$status == "closed", summary$acceptance_rate, baseline_rate)
  summary$offer_gap <- summary$target_offers - summary$offers_count

  summary
}
