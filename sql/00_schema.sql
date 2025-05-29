CREATE SCHEMA IF NOT EXISTS groupscholar_yield_forecast;

CREATE TABLE IF NOT EXISTS groupscholar_yield_forecast.cohorts (
  cohort_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  target_offers INTEGER NOT NULL DEFAULT 0,
  program TEXT NOT NULL DEFAULT 'General',
  region TEXT NOT NULL DEFAULT 'Global'
);

ALTER TABLE groupscholar_yield_forecast.cohorts
  ADD COLUMN IF NOT EXISTS program TEXT NOT NULL DEFAULT 'General';

ALTER TABLE groupscholar_yield_forecast.cohorts
  ADD COLUMN IF NOT EXISTS region TEXT NOT NULL DEFAULT 'Global';

CREATE TABLE IF NOT EXISTS groupscholar_yield_forecast.offers (
  offer_id SERIAL PRIMARY KEY,
  cohort_id INTEGER NOT NULL REFERENCES groupscholar_yield_forecast.cohorts(cohort_id),
  offer_date DATE NOT NULL,
  accepted_at DATE,
  award_amount NUMERIC(10,2) NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS offers_cohort_id_idx
  ON groupscholar_yield_forecast.offers (cohort_id);
