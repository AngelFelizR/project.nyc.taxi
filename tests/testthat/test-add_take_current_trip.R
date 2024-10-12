describe("add_take_current_trip", {

  # Defining times to use
  start_time <- as.POSIXct("2023-10-01 09:00:00")
  secs_to_check <- seq(from = 30, to = 20*60, by = 30)
  future_time <- start_time + lubridate::seconds(secs_to_check)

  # The keep the example simple the defining the id for points
  # as their distance from the 0 point
  mean_distance <- data.table::data.table(
    PULocationID = 0,
    DOLocationID = 0:20,
    trip_miles_mean = 0:20
  )

  # Listing a sequence of destinations
  future_dist <- floor(secs_to_check/60)

  # Setup: Create mock data for testing
  # 1. The first trip must be taken
  # 2. The second trips won't be take
  trip_sample <- data.table::data.table(
    trip_id = 1:2,
    request_datetime = start_time,
    hvfhs_license_num = c("HV123", "HV456"),
    wav_request_flag = c("N", "Y"),
    wav_match_flag = c("N", "Y"),
    PULocationID = 0,
    performance_per_hour = c(100, 50)
  )

  # Defining basic future trips
  set.seed(15542)

  future_trips <- data.table::data.table(
    request_datetime = future_time,
    hvfhs_license_num = "HV123",
    wav_request_flag = c(rep("Y", 10), rep("N", 30)),
    wav_match_flag = c(rep("Y", 10), rep("N", 30)),
    DOLocationID = future_dist,
    driver_pay = c(rnorm(10, mean = 150, sd = 10),
                   rnorm(20, mean = 50, sd = 30),
                   rnorm(10, mean = 150, sd = 10)),
    tips = 0,
    trip_time = 3600
  )
  all_trips <- rbind(future_trips, future_trips)
  all_trips[41:80, hvfhs_license_num := "HV456"]

  # Save all_trips to parquet format
  parquet_path <- tempfile(fileext = ".parquet")
  con <- DBI::dbConnect(duckdb::duckdb())
  DBI::dbWriteTable(con, "all_trips", all_trips)
  DBI::dbExecute(con, paste0("COPY (SELECT * FROM all_trips) TO '",parquet_path,"' (FORMAT 'parquet');"))
  DBI::dbDisconnect(con, shutdown = TRUE)
  on.exit(file.remove(parquet_path), add = TRUE)

  # Test data loading and basic functionality
  it("returns the correct output and WAV trips give more money", {
    result <- add_take_current_trip(trip_sample, mean_distance, parquet_path)

    # The result is a data.table
    expect_s3_class(result, "data.table")

    # Getting the same data rows
    expect_equal(result$trip_id, trip_sample$trip_id)

    # WAV trips give more money
    expect_equal(result$take_current_trip, c(1L, 0L))

    # Getting all expected columns
    expect_true(all(c("trip_id", "take_current_trip", "performance_per_hour", "percentile_75_performance") %in% names(result)))
  })

  it("handles invalid input gracefully", {
    expect_error(add_take_current_trip(data.frame(), mean_distance, parquet_path), "trip_sample must be a non-empty data frame")
    expect_error(add_take_current_trip(trip_sample, data.frame(), parquet_path), "point_mean_distance must be a non-empty data frame")
    expect_error(add_take_current_trip(trip_sample, mean_distance, "non_existent_file.parquet"), "parquet_path does not exist")
  })

  it("handles edge cases correctly", {
    # Test with a single trip
    single_trip <- trip_sample[1]
    result_single <- add_take_current_trip(single_trip, mean_distance, parquet_path)
    expect_equal(nrow(result_single), 1)

    # Test with no matching future trips
    no_match_trip <- data.table::data.table(
      trip_id = 1,
      request_datetime = as.POSIXct("2025-01-01 00:00:00"),
      hvfhs_license_num = "HV999",
      wav_request_flag = "N",
      wav_match_flag = "N",
      PULocationID = 0,
      performance_per_hour = 100
    )
    result_no_match <- add_take_current_trip(no_match_trip, mean_distance, parquet_path)
    expect_equal(result_no_match$take_current_trip, 1L)  # Should take current trip if no alternatives
  })
})
