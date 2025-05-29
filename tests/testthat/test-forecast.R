find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = FALSE)
  for (i in 1:6) {
    candidate <- file.path(current, "R", "forecast.R")
    if (file.exists(candidate)) {
      return(current)
    }
    parent <- dirname(current)
    if (parent == current) {
      break
    }
    current <- parent
  }
  stop("Unable to locate project root for forecast.R")
}

project_root <- find_project_root()
source(file.path(project_root, "R", "forecast.R"))

library(testthat)

test_that("compute_yield_forecast calculates baseline and forecasts", {
  cohorts <- data.frame(
    cohort_id = c(1, 2),
    name = c("Past", "Active"),
    start_date = as.Date(c("2024-01-01", "2025-01-01")),
    end_date = as.Date(c("2024-06-01", "2026-06-01")),
    target_offers = c(2, 5)
  )

  offers <- data.frame(
    offer_id = 1:4,
    cohort_id = c(1, 1, 2, 2),
    offer_date = as.Date(c("2024-02-01", "2024-03-01", "2025-02-01", "2025-02-10")),
    accepted_at = as.Date(c("2024-02-10", NA, NA, NA)),
    award_amount = c(2500, 1500, 2000, 2200)
  )

  result <- compute_yield_forecast(cohorts, offers, as_of = as.Date("2026-02-08"))
  past <- result[result$name == "Past", ]
  active <- result[result$name == "Active", ]

  expect_equal(past$offers_count, 2)
  expect_equal(past$accepted_count, 1)
  expect_equal(round(past$acceptance_rate, 2), 0.5)
  expect_equal(round(active$baseline_rate, 2), 0.5)
  expect_equal(active$forecast_acceptances, 1)
  expect_equal(active$offer_gap, 3)
  expect_equal(past$offers_total_award, 4000)
  expect_equal(past$accepted_award_total, 2500)
  expect_equal(active$forecast_award_total, 2100)
})

test_that("compute_yield_forecast groups by region", {
  cohorts <- data.frame(
    cohort_id = c(1, 2, 3),
    name = c("West Past", "West Active", "East Active"),
    start_date = as.Date(c("2024-01-01", "2025-01-01", "2025-01-01")),
    end_date = as.Date(c("2024-06-01", "2026-06-01", "2026-06-01")),
    target_offers = c(2, 4, 3),
    program = c("Bridge", "Bridge", "Launch"),
    region = c("West", "West", "East")
  )

  offers <- data.frame(
    offer_id = 1:6,
    cohort_id = c(1, 1, 2, 2, 3, 3),
    offer_date = as.Date(c("2024-02-01", "2024-03-01", "2025-02-01", "2025-02-10", "2025-02-05", "2025-02-12")),
    accepted_at = as.Date(c("2024-02-10", NA, NA, NA, NA, NA)),
    award_amount = c(2500, 1500, 2000, 2200, 1800, 1900)
  )

  grouped <- compute_yield_forecast(
    cohorts,
    offers,
    as_of = as.Date("2026-02-08"),
    group_by = "region"
  )

  west <- grouped[grouped$group == "West", ]
  east <- grouped[grouped$group == "East", ]

  expect_equal(west$offers_count, 4)
  expect_equal(west$accepted_count, 1)
  expect_equal(west$forecast_acceptances, 2)
  expect_equal(round(west$baseline_rate, 2), 0.5)

  expect_equal(east$offers_count, 2)
  expect_equal(east$forecast_acceptances, 1)
})

test_that("compute_yield_forecast honors yield overrides", {
  cohorts <- data.frame(
    cohort_id = 1,
    name = "Active",
    start_date = as.Date("2025-01-01"),
    end_date = as.Date("2026-06-01"),
    target_offers = 4
  )

  offers <- data.frame(
    offer_id = 1:4,
    cohort_id = 1,
    offer_date = as.Date(c("2025-02-01", "2025-02-10", "2025-02-20", "2025-03-01")),
    accepted_at = as.Date(c(NA, NA, NA, NA)),
    award_amount = c(2500, 2400, 2300, 2200)
  )

  result <- compute_yield_forecast(
    cohorts,
    offers,
    as_of = as.Date("2026-02-08"),
    yield_rate_override = 0.75
  )

  expect_equal(round(result$baseline_rate, 2), 0.75)
  expect_equal(result$forecast_acceptances, 3)
  expect_equal(result$forecast_award_total, 7050)
})

test_that("compute_yield_forecast supports program groupings", {
  cohorts <- data.frame(
    cohort_id = c(1, 2, 3),
    name = c("Closed STEM", "Active STEM", "Active Arts"),
    start_date = as.Date(c("2024-01-01", "2025-01-01", "2025-02-01")),
    end_date = as.Date(c("2024-06-01", "2026-06-01", "2026-06-01")),
    target_offers = c(4, 4, 2),
    program = c("STEM", "STEM", "Arts"),
    region = c("Midwest", "Midwest", "South")
  )

  offers <- data.frame(
    offer_id = 1:10,
    cohort_id = c(1, 1, 1, 1, 2, 2, 2, 2, 3, 3),
    offer_date = as.Date(c(
      "2024-02-01", "2024-02-05", "2024-02-10", "2024-02-20",
      "2025-02-01", "2025-02-05", "2025-02-10", "2025-02-20",
      "2025-03-01", "2025-03-10"
    )),
    accepted_at = as.Date(c(
      "2024-02-10", "2024-02-18", "2024-02-25", NA,
      NA, NA, NA, NA,
      NA, NA
    )),
    award_amount = c(2500, 2600, 2700, 2400, 2200, 2300, 2100, 2000, 1800, 1900)
  )

  result <- compute_yield_forecast(
    cohorts,
    offers,
    as_of = as.Date("2026-02-08"),
    group_by = "program"
  )

  stem <- result[result$group == "STEM", ]
  arts <- result[result$group == "Arts", ]

  expect_equal(stem$offers_count, 8)
  expect_equal(stem$accepted_count, 3)
  expect_equal(stem$forecast_acceptances, 6)
  expect_equal(round(stem$baseline_rate, 2), 0.75)
  expect_equal(stem$status, "mixed")

  expect_equal(arts$offers_count, 2)
  expect_equal(arts$forecast_acceptances, 2)
  expect_equal(arts$status, "active")
})
