library(data.table)
library(DBI)

# 1. Creating connection ----
temp_con = DBI::dbConnect(duckdb::duckdb(),
                          here::here("tests/testthat/fixtures/test-db.duckdb"))

# 2. Defining the PointMeanDistance table ----

# To create a my own example a need to create 5 locations
# in a concrete space using x and y as coordinates
location_positions =
  data.frame(id = 1:5,
             x = c(0, 1, 1, 3, 3),
             y = c(0, 0, sqrt(3^2 - 1^2), 0, sqrt(7^2 - 3^2)))

# We can check the configuration using ggplot2
if(interactive()){
  ggplot2::ggplot(location_positions, ggplot2::aes(x,y)) +
    ggplot2::geom_label(ggplot2::aes(label = id)) +
    ggplot2::scale_x_continuous(breaks = scales::breaks_width(1))+
    ggplot2::scale_y_continuous(breaks = scales::breaks_width(1))+
    ggplot2::theme_classic()
}

# Now we can calculate the distance for each point in both sense
all_distance =
  stats::dist(location_positions[, -1], upper = TRUE)  |>
  as.matrix() |>
  round(2) |>
  as.data.frame()

# Now we just need to reshape the distance
data.table::setDT(all_distance)[, PULocationID := location_positions$id]

PointMeanDistance = data.table::melt(
  all_distance,
  id.vars = "PULocationID",
  variable.name = "DOLocationID",
  value.name = "trip_miles_mean",
  variable.factor = FALSE
)[, DOLocationID := as.integer(DOLocationID)]

DBI::dbWriteTable(temp_con,
                  name = "PointMeanDistance",
                  value = PointMeanDistance,
                  overwrite = TRUE)

# 3. Start Trips example ----

StartTime = as.POSIXct("2023-01-12 20:25:49", tz = "UTC")

SimulationStartTrips = data.table::data.table(

  # Unique Ids
  trip_id = c(218799831, 218799832),

  # Fixed conditions
  hvfhs_license_num = c("HV0005", "HV0003"),
  wav_match_flag = c("Y", "N"),

  # Trip details
  PULocationID = 5,
  DOLocationID = 1,
  request_datetime = as.POSIXct("2023-01-12 20:14:29", tz = "UTC"),
  dropoff_datetime = StartTime,
  trip_time = 680,
  driver_pay = c(5.47, 5.47),
  tips = 0

)

saveRDS(SimulationStartTrips,
        "tests/testthat/fixtures/SimulationStartTrips.rds")


# 4. Defining the table to query from ----

NycTripsList = vector("list", 15L)
TripDuration = lubridate::minutes(20)


# 1. TAKE TRIPS 1 and 3 to confirm we are picking the first trip 1 one mile

# A trips after some seconds
NycTripsList[[1L]] = data.table::data.table(
  # Unique Ids
  trip_id = 1,

  # UBER TRIP
  hvfhs_license_num = "HV0005",

  # Wheelchair-accessible
  wav_match_flag = "N",

  # From 1 to 2: 1 mile trip and 30 seconds
  PULocationID = 2,
  DOLocationID = 1,
  request_datetime = StartTime + lubridate::seconds(30),
  dropoff_datetime = StartTime + lubridate::seconds(30) + TripDuration
)

# TAXI 2 can take take that trip
NycTripsList[[3L]] = data.table::copy(
  NycTripsList[[1L]]
)[, `:=`(trip_id = 3L,
         hvfhs_license_num = "HV0003")
][]


# A trips after one second we cannot take the trip
NycTripsList[[2L]] = data.table::copy(
  NycTripsList[[1L]]
  )[, `:=`(trip_id = 2,
           request_datetime = request_datetime + lubridate::seconds(1),
           dropoff_datetime = dropoff_datetime + lubridate::seconds(1))
  ][]

NycTripsList[[4L]] = data.table::copy(
  NycTripsList[[3L]]
)[, `:=`(trip_id = 4,
         request_datetime = request_datetime + lubridate::seconds(1),
         dropoff_datetime = dropoff_datetime + lubridate::seconds(1))
][]


# 2. TAKE Trips 5 and 7 as only taxi 1 can take WA trips
#    and after 2 min waiting we can start looking trips in
#    3 miles radius

# Taxi 1 can take WA trips
NycTripsList[[5L]] = data.table::copy(
  NycTripsList[[1L]]
)[, `:=`(trip_id = 5,
         wav_match_flag = "Y",
         # From 1 to 3: 3-mile radius
         PULocationID = 3,
         DOLocationID = 5,
         request_datetime = dropoff_datetime + lubridate::minutes(2),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(2) + lubridate::hours(4))
][]

# Taxi 2 cannot take WA trips
NycTripsList[[6L]] = data.table::copy(
  NycTripsList[[3L]]
)[, `:=`(trip_id = 6,
         wav_match_flag = "Y",
         # From 1 to 3: 3-mile radius
         PULocationID = 3,
         DOLocationID = 5,
         request_datetime = dropoff_datetime + lubridate::minutes(2),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(2) + lubridate::hours(4))
][]

# We want to validate if it can take also lower distance after the time
# we aren't adding more time as it was added on element 6
NycTripsList[[7L]] = data.table::copy(
  NycTripsList[[6L]]
)[, `:=`(trip_id = 7,
         # Changing the problem condition
         wav_match_flag = "N",
         # From 1 to 2: 1-mile radius
         PULocationID = 2,
         DOLocationID = 5,
         request_datetime = request_datetime + lubridate::seconds(5))
][]


# 3. TAKE 10 and 11 TRIPS as TAXIS need a 30 min break
#    and take trips in 5 miles radius after waiting 3 min

# Taxi 1 No due break
NycTripsList[[8L]] = data.table::copy(
  NycTripsList[[5L]]
)[, `:=`(trip_id = 8,
         wav_match_flag = "N",
         # From 5 to 3: 4.03 mile radius
         PULocationID = 3,
         DOLocationID = 1,
         request_datetime = dropoff_datetime + lubridate::minutes(4),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(4) + TripDuration)
][]

# Taxi 2 No due break
NycTripsList[[9L]] = data.table::copy(
  NycTripsList[[7L]]
)[, `:=`(trip_id = 9,
         # From 5 to 3: 4-mile radius
         PULocationID = 3,
         DOLocationID = 1,
         request_datetime = dropoff_datetime + lubridate::minutes(4),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(4) + TripDuration)
][]

# After passing the break Taxi 1 take the trip
NycTripsList[[10L]] = data.table::copy(
  NycTripsList[[5L]]
)[, `:=`(trip_id = 10,
         wav_match_flag = "N",
         # From 5 to 3: 4.03 mile radius
         PULocationID = 3,
         DOLocationID = 1,
         request_datetime = dropoff_datetime + lubridate::minutes(34),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(34) + TripDuration)
][]

# After passing the break Taxi 2 take the trip
NycTripsList[[11L]] = data.table::copy(
  NycTripsList[[7L]]
)[, `:=`(trip_id = 11,
         wav_match_flag = "N",
         # 5-mile radius
         PULocationID = 3,
         DOLocationID = 1,
         request_datetime = dropoff_datetime + lubridate::minutes(34),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(34) + TripDuration)
][]


# 3. TAKE 14 and 15 to only take over 5 miles trips
#    only after waiting for more than 5 minutes

# 4 minutes is not enough for long trip

NycTripsList[[12L]] = data.table::copy(
  NycTripsList[[10L]]
)[, `:=`(trip_id = 12,
         wav_match_flag = "N",
         # From 1 to 5: 7-mile radius
         PULocationID = 5,
         DOLocationID = 1,
         request_datetime =
           dropoff_datetime + lubridate::minutes(4) + lubridate::seconds(30),
         dropoff_datetime =
           dropoff_datetime + lubridate::minutes(4) + lubridate::seconds(30) + TripDuration)
][]

NycTripsList[[13L]] = data.table::copy(
  NycTripsList[[11L]]
)[, `:=`(trip_id = 13,
         wav_match_flag = "N",
         # From 1 to 5: 7-mile radius
         PULocationID = 5,
         DOLocationID = 1,
         request_datetime =
           dropoff_datetime + lubridate::minutes(4) + lubridate::seconds(30),
         dropoff_datetime =
           dropoff_datetime + lubridate::minutes(4) + lubridate::seconds(30) + TripDuration)
][]


# We need to wait 7 min to take a trip of 7 miles
NycTripsList[[14L]] = data.table::copy(
  NycTripsList[[12L]]
)[, `:=`(trip_id = 14L,
         request_datetime = request_datetime + lubridate::minutes(3),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(3))
][]

NycTripsList[[15L]] = data.table::copy(
  NycTripsList[[13L]]
)[, `:=`(trip_id = 15L,
         request_datetime = request_datetime + lubridate::minutes(3),
         dropoff_datetime = dropoff_datetime + lubridate::minutes(3))
][]

# Consolidating table and adding money

set.seed(1587)

final_table =
  data.table::rbindlist(NycTripsList
  )[, `:=`(trip_time = difftime(dropoff_datetime, request_datetime, units = "secs") |> as.double(),
           driver_pay = runif(.N, 10, 60),
           tips = runif(.N, 0, 10))]

set.seed(NULL)

# Saving the results on DB

DBI::dbWriteTable(temp_con,
                  name = "NycTrips",
                  value =  final_table,
                  overwrite = TRUE)


# Disconnecting from duckdb ----

DBI::dbDisconnect(temp_con, shutdown = TRUE)
rm(temp_con)

