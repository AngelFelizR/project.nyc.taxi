#' Add and Evaluate Future Trip Alternatives
#'
#' This function identifies and evaluates future trip alternatives for a given sample of trips.
#' It considers various constraints such as proximity to the current location, time window,
#' and trip characteristics like wheelchair accessibility, to determine whether to take the current trip.
#'
#' @param trip_sample A data frame containing the sample of trips to be evaluated. Each row represents a single trip.
#' @param point_mean_distance A data frame containing mean distances between different pickup and drop-off locations.
#' It should include at least PULocationID and DOLocationID columns.
#' @param parquet_path A string specifying the path to the Parquet file containing all historical trips data.
#' @inheritParams future.apply::future_lapply
#'
#' @return A data table with the original trip sample and additional columns:
#'   - percentile_75_performance: The 75th percentile of performance for future trips.
#'   - take_current_trip: An integer (0 or 1) indicating whether the current trip should be taken based on performance metrics.
#'
#' @details The function connects to a DuckDB database to retrieve historical trip data. For each trip in the sample,
#' it fetches potential future trip alternatives that meet specific criteria:
#' - The request time must be between 3 seconds and 15 minutes after the current trip's request time.
#' - Future trips must be from the same company (hvfhs_license_num) as the current trip.
#' - If the current trip is not for a wheelchair-accessible vehicle, future trips must also not be for a wheelchair-accessible vehicle.
#'
#' Each valid future trip is evaluated based on the distance from the current trip and its potential profitability,
#' calculated as performance_per_hour (pay per hour, adjusted for waiting time). The function then compares the performance
#' of each trip against the 75th percentile of performance for future trips and decides whether to take the current trip.
#'
#' @export
add_take_current_trip <- function(trip_sample,
                                  point_mean_distance,
                                  parquet_path,
                                  future.scheduling = 1,
                                  future.chunk.size = NULL) {

  # Input validation
  if (!is.data.frame(trip_sample) || nrow(trip_sample) == 0) {
    stop("trip_sample must be a non-empty data frame")
  }
  if (!is.data.frame(point_mean_distance) || nrow(point_mean_distance) == 0) {
    stop("point_mean_distance must be a non-empty data frame")
  }
  if (!file.exists(parquet_path)) {
    stop("parquet_path does not exist")
  }

  # Ensure trip_sample and point_mean_distance are data.table
  data.table::setDT(trip_sample)
  data.table::setDT(point_mean_distance)

  # Check for required columns in trip_sample
  required_cols <- c("trip_id", "request_datetime", "hvfhs_license_num", "wav_request_flag", "wav_match_flag", "PULocationID", "performance_per_hour")
  missing_cols <- setdiff(required_cols, names(trip_sample))
  if (length(missing_cols) > 0) {
    stop(paste("Missing required columns in trip_sample:", paste(missing_cols, collapse = ", ")))
  }

  # Importing historical trips from parquet file
  tryCatch({
    con <- DBI::dbConnect(duckdb::duckdb())
    all_trips <- DBI::dbGetQuery(con, paste0("SELECT * FROM '", parquet_path, "'"))
    DBI::dbDisconnect(con, shutdown = TRUE)
  }, error = function(e) {
    stop(paste("Error reading parquet file:", e$message))
  })

  # Changing table to data.table
  data.table::setDT(all_trips)

  # Creating function to select valid future trips
  select_valid_future_trips <- function(n_row) {

    trip_sample_i <- trip_sample[n_row]

    distance_to_use <- point_mean_distance[
      trip_sample_i[, c("PULocationID")],
      on = "PULocationID",
      nomatch = NULL,
      j = .(DOLocationID = PULocationID,
            trip_miles_mean)
    ] |>
      # We don't want a many to many join
      unique(by = "DOLocationID")


    valid_future_trips <- all_trips[
      # We only need 15 min of data
      request_datetime >= (trip_sample_i$request_datetime + lubridate::seconds(3)) &
        request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(15)) &
        # The trip must come from same company
        hvfhs_license_num == trip_sample_i$hvfhs_license_num &
        # Confirm if the taxi can take wav trips
        (trip_sample_i$wav_match_flag == "Y" | wav_request_flag == "N")
      # Adding distances to validate
    ][, distance_to_use[.SD, on = "DOLocationID"]
      # Apply distance thresholds
    ][(request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(1)) & trip_miles_mean <= 1) |
        (request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(3)) & trip_miles_mean <= 3) |
        (request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(5)) & trip_miles_mean <= 5) |
        (request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(7)) & trip_miles_mean <= 7) |
        (request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(9)) & trip_miles_mean <= 9) |
        (request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(11)) & trip_miles_mean <= 11) |
        (request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(13)) & trip_miles_mean <= 13) |
        (request_datetime <= (trip_sample_i$request_datetime + lubridate::minutes(15)) & trip_miles_mean <= 15)]

    # Calculate performance
    valid_future_trips[, waiting_secs := as.numeric(difftime(request_datetime, trip_sample_i$request_datetime, units = "secs"))]
    valid_future_trips[, performance_per_hour := (driver_pay + tips) / ((trip_time + waiting_secs) / 3600) ]

    # Adding trip_id for all selected rows
    valid_future_trips[, trip_id := trip_sample_i$trip_id]

    return(valid_future_trips)
  }

  # Getting the future alternatives for each trip
  trip_data <- future.apply::future_lapply(
    # Passing the rows to validate
    seq_len(nrow(trip_sample)),

    # Passing the function to use
    FUN = select_valid_future_trips,

    # Passing large data.frames to avoid duplication
    future.globals = c("trip_sample", "point_mean_distance", "all_trips"),

    # Passing optimization params
    future.chunk.size = future.chunk.size,
    future.scheduling = future.scheduling
  ) |>
    data.table::rbindlist(fill = TRUE)

  # Find the 75th percentile of each sample trip
  future_trip_summary <- trip_data[
    j = .(percentile_75_performance = stats::quantile(performance_per_hour, 0.75, na.rm = TRUE)),
    by = "trip_id"
  ]

  # Define whether we should take the current trip
  final_data <- future_trip_summary[trip_sample, on = "trip_id"
  ][, take_current_trip := data.table::fifelse(performance_per_hour > percentile_75_performance, 1L, 0L)]

  # If not alternatives show 1
  final_data[is.na(take_current_trip),
             take_current_trip := 1L]

  # Define order for new columns
  data.table::setcolorder(final_data, "percentile_75_performance", before = "take_current_trip")

  return(final_data[])
}
