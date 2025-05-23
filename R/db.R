suppressPackageStartupMessages({
  library(DBI)
  library(RPostgres)
})

get_db_connection <- function() {
  required <- c("PGHOST", "PGPORT", "PGUSER", "PGPASSWORD", "PGDATABASE")
  missing <- required[nzchar(Sys.getenv(required)) == FALSE]
  if (length(missing) > 0) {
    stop("Missing required environment variables: ", paste(missing, collapse = ", "))
  }

  DBI::dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("PGHOST"),
    port = as.integer(Sys.getenv("PGPORT")),
    user = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    dbname = Sys.getenv("PGDATABASE")
  )
}
