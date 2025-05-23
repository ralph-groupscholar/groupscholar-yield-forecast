source(file.path("R", "forecast.R"))

library(testthat)

test_that("compute_yield_forecast calculates baseline and forecasts", {
  cohorts <- data.frame(
    cohort_id = c(1, 2),
    name = c("Past", "Active"),
    start_date = as.Date(c("2024-01-01", "2025-01-01")),
    end_date = as.Date(c("2024-06-01", "2026-06-01"))
  )

  offers <- data.frame(
    offer_id = 1:4,
    cohort_id = c(1, 1, 2, 2),
    offer_date = as.Date(c("2024-02-01", "2024-03-01", "2025-02-01", "2025-02-10")),
    accepted_at = as.Date(c("2024-02-10", NA, NA, NA))
  )

  result <- compute_yield_forecast(cohorts, offers, as_of = as.Date("2026-02-08"))
  past <- result[result$name == "Past", ]
  active <- result[result$name == "Active", ]

  expect_equal(past$offers_count, 2)
  expect_equal(past$accepted_count, 1)
  expect_equal(round(past$acceptance_rate, 2), 0.5)
  expect_equal(round(active$baseline_rate, 2), 0.5)
  expect_equal(active$forecast_acceptances, 1)
})
