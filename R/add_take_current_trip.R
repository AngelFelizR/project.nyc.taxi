#' Add and Evaluate Future Trip Alternatives
#'
#' This function identifies and evaluates future trip alternatives for a given sample of trips.
#' It considers various constraints such as proximity to the current location, the time window,
#' and trip characteristics like wheelchair accessibility, to determine whether to take the current trip.
#'
#' @param trip_sample A data frame containing the sample of trips to be evaluated. Each row represents a single trip.
#' @param point_mean_distance A data table containing mean distances between different pickup and drop-off locations.
#' It should include at least `PULocationID` and `DOLocationID` columns.
#' @param parquet_path A string specifying the path to the Parquet file containing all historical trips data, which is queried using DuckDB.
#'
#' @return A data table with the original trip sample and an additional column, `take_current_trip`, indicating whether the current trip should be taken (1) or not (0) based on performance metrics.
#'
#' @details The function connects to a DuckDB database to retrieve historical trip data. For each trip in the sample, it fetches potential future trip alternatives that meet a set of criteria:
#' - The request time must be between 3 seconds and 15 minutes after the current trip's request time.
#' - Future trips must be from the same company (`hvfhs_license_num`) as the current trip.
#' - If the current trip is not for a wheelchair-accessible vehicle, future trips must also not be for a wheelchair-accessible vehicle.
#'
#' Each valid future trip is evaluated based on the distance from the current trip and its potential profitability,
#' calculated as `performance_per_hour` (pay per hour, adjusted for waiting time). The function then compares the performance
#' of each trip against the 75th percentile of performance for future trips and decides whether to take the current trip.
#'
#' @examples
#' # Example usage:
#' trip_sample <- data.frame(
#'   trip_id = 1:5,
#'   request_datetime = as.POSIXct(Sys.time() + c(0, 60, 120, 180, 240), origin = "1970-01-01"),
#'   hvfhs_license_num = sample(c('HV001', 'HV002'), 5, replace = TRUE),
#'   wav_match_flag = sample(c('Y', 'N'), 5, replace = TRUE),
#'   PULocationID = sample(1:100, 5, replace = TRUE),
#'   DOLocationID = sample(1:100, 5, replace = TRUE)
#' )
#'
#' point_mean_distance <- data.table::data.table(
#'   PULocationID = 1:100,
#'   DOLocationID = 1:100,
#'   trip_miles_mean = runif(100)
#' )
#'
#' parquet_path <- "path_to_parquet_file"
#' add_take_current_trip(trip_sample, point_mean_distance, parquet_path)
#'
#' @export
add_take_current_trip <- function(trip_sample,
                                  point_mean_distance,
                                  parquet_path) {

  con = DBI::dbConnect(duckdb::duckdb())
  all_trips = DBI::dbGetQuery(con, paste0("SELECT * FROM '", parquet_path, "'"))
  DBI::dbDisconnect(con, shutdown = TRUE)

  # Step 1: Getting the future alternatives for each trip
  trip_data =
    future.apply::future_lapply(1:nrow(trip_sample), \(n_row){
browser()
      # Selecting the row to use
      trip_sample_i = trip_sample[n_row]

      # Assuming that the taxi is close to the current request position
      # We get the distance for all points related that position
      ditance_to_use =
        PointMeanDistance[trip_sample_i[, c("PULocationID")],
                          on = "PULocationID",
                          nomatch = NULL]

      # A trip can only be available to be take need to take place
      valid_future_trips =

        # - From 3 seconds to 15 minutes after the original request received
        # - The trips needs to be from the same taxi company of the original request
        # - If the original trips wasn't for wheelchair-accessible vehicle
        #   the next trip cannot be for a wheelchair-accessible vehicle.
        all_trips[request_datetime >= (trip_sample_i$request_datetime + lubridate::seconds(3)) &
                    request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(15)) &
                    hvfhs_license_num == trip_sample_i$hvfhs_license_num &
                    (if(trip_sample_i$wav_match_flag == "Y") wav_match_flag %chin% c('Y', 'N') else  wav_match_flag == "N")
        ][trip_sample_i,
          on = "hvfhs_license_num",
          nomatch = NULL

          # Adding the distance from origin position to the new request position
        ][, ditance_to_use[.SD, on = c("DOLocationID" = "PULocationID")]

          # The long distance trips to pick up are only available as the time runs
        ][(request_datetime <= (i.request_datetime + lubridate::minutes(1)) & trip_miles_mean <= 1) |
            (request_datetime <= (i.request_datetime + lubridate::minutes(3)) & trip_miles_mean <= 3) |
            (request_datetime <= (i.request_datetime + lubridate::minutes(5)) & trip_miles_mean <= 5) |
            (request_datetime <= (i.request_datetime + lubridate::minutes(7)) & trip_miles_mean <= 7) |
            (request_datetime <= (i.request_datetime + lubridate::minutes(9)) & trip_miles_mean <= 9) |
            (request_datetime <= (i.request_datetime + lubridate::minutes(11)) & trip_miles_mean <= 11) |
            (request_datetime <= (i.request_datetime + lubridate::minutes(13)) & trip_miles_mean <= 13) |
            (request_datetime <= (i.request_datetime + lubridate::minutes(15)) & trip_miles_mean <= 15)]

      # Defining performance for each future trip
      # Taking in consideration the waiting time
      valid_future_trips[, waiting_secs := as.numeric(difftime(request_datetime, i.request_datetime, units = "secs"))]
      valid_future_trips[, performance_per_hour := (driver_pay + tips) / ((trip_time + waiting_secs) / 3600)]

      return(valid_future_trips)

    }) |>
    data.table::rbindlist()


  # Step 2: Find the 3er quartile of each sample trip
  future_trip_summary <- trip_data[
    , .(percentile_75_performance = stats::quantile(performance_per_hour, 0.75, na.rm = TRUE)),
    by = "trip_id"
  ]


  # Step 3: Define whether we should take the current trip
  final_data <-
    trip_sample[future_trip_summary,
                on = "trip_id"
    ][, take_current_trip := fifelse(performance_per_hour > percentile_75_performance, 0L, 1L)]


  # Result
  return(final_data[])


}
