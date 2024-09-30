#' Confirm whether is better to wait for other trip
#'
#' The function helps to confirm for each trip passed to the `trip_sample` argument
#' whether we can find several trips in the next 15 minutes that can be better
#' than the current one.
#'
#' @param trip_sample A data.table table listing all trips to evaluate.
#' @param point_mean_distance A data.table with the trip_miles_mean between
#' PULocationID and DOLocationID points.
#' @param parquet_path A path to a parquet file listing the data to be use
#' in other to defining a trip should be taken.
#'
#' @return A data.table with the same number of rows as `trip_sample`.
#' @export
add_take_current_trip <- function(trip_sample,
                                  point_mean_distance,
                                  parquet_path) {

  con = DBI::dbConnect(duckdb::duckdb())
  all_trips = DBI::dbGetQuery(con, paste0("SELECT * FROM ", parquet_path))

  # Step 1: Getting the future alternatives for each trip
  trip_data =
    future.apply::future_lapply(1:nrow(trip_sample), \(n_row){

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
    rbindlist()


  # Step 2: Find the 3er quartile of each sample trip
  future_trip_summary <- trip_data[
    , .(percentile_75_performance = quantile(performance_per_hour, 0.75, na.rm = TRUE)),
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
