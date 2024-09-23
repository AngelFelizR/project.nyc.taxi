
# Libraries to use

library(DBI)
library(duckdb)
library(data.table)
library(lubridate)


# Connecting to db

con <- dbConnect(duckdb(), dbdir = here::here("../NycTaxi/my-db.duckdb"))


# Getting some valid samples

ValidZoneSample <- dbGetQuery(con, "SELECT * FROM ValidZoneSample ORDER BY year, month")

setDT(ValidZoneSample)

ValidZoneSample <-
  ValidZoneSample[, request_datetime_extra := request_datetime + minutes(15)
                  # For computational limitations we will
                  # exclude trips that need to search in different months
  ][floor_date(request_datetime_extra, unit = "month") ==
      floor_date(request_datetime, unit = "month")]


set.seed(26189)

PointExamples <- ValidZoneSample[sample.int(length(year), 3)]

TimeInterval <-
  PointExamples |>
  with(glue::glue("(request_datetime > '{request_datetime}' AND request_datetime <= '{request_datetime_extra}')")) |>
  paste0(collapse = "\nOR ")



Query <- glue::glue("
SELECT *
FROM NycTrips
WHERE {TimeInterval}
")

TestingData <- dbGetQuery(con, Query)

# Closing connection
dbDisconnect(con, shutdown = TRUE)
rm(con)


# Saving important data
saveRDS(PointExamples,'tests/testthat/fixtures/TakeTripStartPoint.rds')


con <- dbConnect(duckdb(), dbdir = here::here("tests/testthat/fixtures/test-db.duckdb"))
dbCreateTable(con,name = "TakeTripData",fields = TestingData)

# Closing connection
dbDisconnect(con, shutdown = TRUE)
rm(con)

