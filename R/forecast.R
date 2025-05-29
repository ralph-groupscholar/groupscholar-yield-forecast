compute_yield_forecast <- function(cohorts,
                                   offers,
                                   as_of = Sys.Date(),
                                   yield_rate_override = NULL,
                                   group_by = NULL) {
  as_of <- as.Date(as_of)

  cohorts$start_date <- as.Date(cohorts$start_date)
  cohorts$end_date <- as.Date(cohorts$end_date)
  offers$offer_date <- as.Date(offers$offer_date)
  offers$accepted_at <- as.Date(offers$accepted_at)

  if (!"target_offers" %in% names(cohorts)) {
    cohorts$target_offers <- 0
  }

  if (!"program" %in% names(cohorts)) {
    cohorts$program <- "Unassigned"
  }

  if (!"region" %in% names(cohorts)) {
    cohorts$region <- "Unassigned"
  }

  if (!"award_amount" %in% names(offers)) {
    offers$award_amount <- 0
  }

  offers <- offers[offers$offer_date <= as_of, , drop = FALSE]

  if (nrow(offers) > 0) {
    offer_counts <- aggregate(offer_id ~ cohort_id, offers, length)
    accepted_counts <- aggregate(!is.na(accepted_at) ~ cohort_id, offers, sum)
    names(accepted_counts)[2] <- "accepted_count"

    award_totals <- aggregate(award_amount ~ cohort_id, offers, sum)
    names(award_totals)[2] <- "offers_total_award"
  } else {
    offer_counts <- data.frame(cohort_id = integer(), offer_id = integer())
    accepted_counts <- data.frame(cohort_id = integer(), accepted_count = integer())
    award_totals <- data.frame(cohort_id = integer(), offers_total_award = numeric())
  }

  accepted_offers <- offers[!is.na(offers$accepted_at), , drop = FALSE]
  if (nrow(accepted_offers) > 0) {
    accepted_awards <- aggregate(award_amount ~ cohort_id, accepted_offers, sum)
    names(accepted_awards)[2] <- "accepted_award_total"
  } else {
    accepted_awards <- data.frame(cohort_id = integer(), accepted_award_total = numeric())
  }

  summary <- merge(cohorts, offer_counts, by = "cohort_id", all.x = TRUE)
  summary <- merge(summary, accepted_counts, by = "cohort_id", all.x = TRUE)
  summary <- merge(summary, award_totals, by = "cohort_id", all.x = TRUE)
  summary <- merge(summary, accepted_awards, by = "cohort_id", all.x = TRUE)

  summary$offer_id[is.na(summary$offer_id)] <- 0
  summary$accepted_count[is.na(summary$accepted_count)] <- 0
  summary$offers_total_award[is.na(summary$offers_total_award)] <- 0
  summary$accepted_award_total[is.na(summary$accepted_award_total)] <- 0
  names(summary)[names(summary) == "offer_id"] <- "offers_count"

  summary$acceptance_rate <- ifelse(
    summary$offers_count > 0,
    summary$accepted_count / summary$offers_count,
    0
  )

  summary$average_award <- ifelse(
    summary$offers_count > 0,
    summary$offers_total_award / summary$offers_count,
    0
  )

  summary$status <- ifelse(summary$end_date < as_of, "closed", "active")

  closed <- summary[summary$status == "closed", , drop = FALSE]
  baseline_rate <- if (nrow(closed) > 0 && sum(closed$offers_count) > 0) {
    sum(closed$accepted_count) / sum(closed$offers_count)
  } else {
    0.5
  }

  group_rates <- NULL
  if (!is.null(group_by)) {
    if (!group_by %in% c("program", "region")) {
      stop("group_by must be one of: program, region")
    }
    if (nrow(closed) > 0) {
      group_rates <- aggregate(
        cbind(accepted_count, offers_count) ~ closed[[group_by]],
        closed,
        sum
      )
      names(group_rates)[1] <- "group"
      group_rates$group_baseline <- ifelse(
        group_rates$offers_count > 0,
        group_rates$accepted_count / group_rates$offers_count,
        NA
      )
    }
  }

  if (!is.null(yield_rate_override)) {
    baseline_rate <- max(min(yield_rate_override, 1), 0)
  }

  summary$baseline_rate <- baseline_rate
  if (!is.null(group_by) && is.null(yield_rate_override) && !is.null(group_rates)) {
    group_match <- match(summary[[group_by]], group_rates$group)
    group_baseline <- group_rates$group_baseline[group_match]
    summary$baseline_rate <- ifelse(
      !is.na(group_baseline),
      group_baseline,
      baseline_rate
    )
  }

  summary$baseline_rate <- ifelse(
    summary$status == "closed",
    summary$acceptance_rate,
    summary$baseline_rate
  )

  summary$forecast_acceptances <- ifelse(
    summary$status == "closed",
    summary$accepted_count,
    round(summary$offers_count * summary$baseline_rate)
  )

  summary$forecast_award_total <- ifelse(
    summary$status == "closed",
    summary$accepted_award_total,
    round(summary$offers_total_award * summary$baseline_rate, 2)
  )

  summary$offer_gap <- summary$target_offers - summary$offers_count

  if (is.null(group_by)) {
    return(summary)
  }

  group_values <- summary[[group_by]]
  grouped <- aggregate(
    cbind(
      target_offers,
      offers_count,
      offer_gap,
      accepted_count,
      forecast_acceptances,
      offers_total_award,
      accepted_award_total,
      forecast_award_total
    ) ~ group_values,
    summary,
    sum
  )
  names(grouped)[1] <- "group"

  grouped$acceptance_rate <- ifelse(
    grouped$offers_count > 0,
    grouped$accepted_count / grouped$offers_count,
    0
  )

  grouped$average_award <- ifelse(
    grouped$offers_count > 0,
    grouped$offers_total_award / grouped$offers_count,
    0
  )

  status_map <- tapply(summary$status, group_values, function(values) {
    if (all(values == "closed")) {
      "closed"
    } else if (all(values == "active")) {
      "active"
    } else {
      "mixed"
    }
  })
  grouped$status <- unname(status_map[grouped$group])

  if (!is.null(yield_rate_override)) {
    grouped$baseline_rate <- baseline_rate
  } else if (!is.null(group_rates)) {
    rate_match <- match(grouped$group, group_rates$group)
    grouped$baseline_rate <- group_rates$group_baseline[rate_match]
    grouped$baseline_rate[is.na(grouped$baseline_rate)] <- baseline_rate
  } else {
    grouped$baseline_rate <- baseline_rate
  }

  grouped
}
