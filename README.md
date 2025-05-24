# Group Scholar Yield Forecast

Group Scholar Yield Forecast is a data-backed CLI for projecting scholarship offer yields. It connects to the Group Scholar PostgreSQL database, summarizes cohort offer performance, and forecasts expected acceptances using historical yield rates.

## Features

- Cohort-level offer and acceptance rollups
- Forecasted acceptances for active cohorts using historical yield
- Optional filtering by cohort name
- Target offer gap tracking per cohort
- Table, CSV, or JSON output formats
- Optional yield-rate override for scenario planning

## Tech

- R (DBI + RPostgres)
- PostgreSQL (production)

## Setup

1. Install R packages:

```r
install.packages(c("DBI", "RPostgres", "jsonlite"))
```

2. Set environment variables (example):

```bash
export PGHOST="db-acupinir.groupscholar.com"
export PGPORT="23947"
export PGUSER="ralph"
export PGPASSWORD="<set-in-shell>"
export PGDATABASE="postgres"
```

3. Run the CLI:

```bash
./bin/gs-yield-forecast --as-of=2026-02-08 --format=table
./bin/gs-yield-forecast --cohort="Spring 2025" --format=json
./bin/gs-yield-forecast --yield-rate=0.62 --format=csv
```

## Database

This project uses the `groupscholar_yield_forecast` schema. Schema and seed files live in `sql/`.

## Testing

```bash
Rscript -e "testthat::test_dir('tests/testthat')"
```

## Roadmap

- Add award amount forecasting for budget planning
- Support cohort groupings (region/program)
