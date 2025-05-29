INSERT INTO groupscholar_yield_forecast.cohorts (name, start_date, end_date, target_offers, program, region)
SELECT name, start_date, end_date, target_offers, program, region
FROM (
  VALUES
    ('Spring 2024', DATE '2024-01-10', DATE '2024-05-20', 120, 'STEM Scholars', 'Midwest'),
    ('Fall 2024', DATE '2024-08-15', DATE '2024-12-10', 140, 'STEM Scholars', 'Northeast'),
    ('Spring 2025', DATE '2025-01-12', DATE '2025-05-22', 150, 'Arts & Culture', 'South'),
    ('Fall 2025', DATE '2025-08-18', DATE '2025-12-12', 165, 'Arts & Culture', 'West'),
    ('Spring 2026', DATE '2026-01-13', DATE '2026-05-23', 175, 'Leadership Fellows', 'Midwest')
) AS seed(name, start_date, end_date, target_offers, program, region)
WHERE NOT EXISTS (
  SELECT 1 FROM groupscholar_yield_forecast.cohorts
  WHERE cohorts.name = seed.name AND cohorts.start_date = seed.start_date
);

INSERT INTO groupscholar_yield_forecast.offers (cohort_id, offer_date, accepted_at, award_amount)
SELECT cohort_id, offer_date, accepted_at, award_amount
FROM (
  VALUES
    (1, DATE '2024-02-01', DATE '2024-02-10', 2500.00),
    (1, DATE '2024-02-05', DATE '2024-02-18', 3000.00),
    (1, DATE '2024-03-01', NULL, 2000.00),
    (1, DATE '2024-03-15', DATE '2024-03-28', 2800.00),
    (1, DATE '2024-04-05', NULL, 2200.00),
    (2, DATE '2024-09-01', DATE '2024-09-12', 2600.00),
    (2, DATE '2024-09-08', NULL, 2400.00),
    (2, DATE '2024-10-01', DATE '2024-10-15', 3200.00),
    (2, DATE '2024-10-10', DATE '2024-10-24', 2800.00),
    (2, DATE '2024-11-02', NULL, 2300.00),
    (3, DATE '2025-02-01', DATE '2025-02-12', 2700.00),
    (3, DATE '2025-02-08', NULL, 2500.00),
    (3, DATE '2025-03-01', DATE '2025-03-18', 3100.00),
    (3, DATE '2025-03-14', DATE '2025-03-30', 2900.00),
    (3, DATE '2025-04-02', NULL, 2400.00),
    (4, DATE '2025-09-03', DATE '2025-09-16', 2800.00),
    (4, DATE '2025-09-15', NULL, 2600.00),
    (4, DATE '2025-10-04', DATE '2025-10-22', 3300.00),
    (4, DATE '2025-10-21', NULL, 2550.00),
    (4, DATE '2025-11-06', DATE '2025-11-20', 2950.00),
    (5, DATE '2026-01-20', NULL, 2900.00),
    (5, DATE '2026-01-25', NULL, 2750.00),
    (5, DATE '2026-02-02', NULL, 3100.00),
    (5, DATE '2026-02-05', NULL, 2650.00)
) AS seed(cohort_id, offer_date, accepted_at, award_amount)
WHERE NOT EXISTS (
  SELECT 1 FROM groupscholar_yield_forecast.offers
  WHERE cohort_id = seed.cohort_id AND offer_date = seed.offer_date AND award_amount = seed.award_amount
);
