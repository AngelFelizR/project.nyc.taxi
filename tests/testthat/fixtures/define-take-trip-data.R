
# Libraries to use

library(DBI)
library(duckdb)
library(data.table)
library(lubridate)


# Connecting to db

con <- dbConnect(duckdb(), dbdir = here::here("../NycTaxi/my-db.duckdb"))


# Getting some valid samples

InitialSample <- dbGetQuery(con, "SELECT * FROM ValidZoneSample")

setDT(InitialSample)

# For computational limitations we will
# exclude trips that need to search in different months
SameMonthSample <- InitialSample[
  floor_date(request_datetime, unit = "month") ==
    floor_date(request_datetime + minutes(15), unit = "month")
]


set.seed(26189)

SamplesToUse <-
  SameMonthSample[, .SD[sample.int(length(year), 20)],
                  by = c("hvfhs_license_num", "wav_request_flag")]


# Simulating data for each group

data.table(

)


# Defining point distance

PointMeanDistance <- dbGetQuery(con, "SELECT * FROM PointMeanDistance")


dbDisconnect(con, shutdown = TRUE)
