describe("add_take_current_trip", {

  # Setup: Create mock data for testing
  trip_sample <- data.table::data.table(
    trip_id = 1:2,
    request_datetime = as.POSIXct(c("2023-10-01 10:00:00", "2023-10-01 11:00:00")),
    hvfhs_license_num = c("HV123", "HV456"),
    wav_match_flag = c("N", "Y"),
    PULocationID = c(1, 2),
    performance_per_hour = c(100, 50)
  )

  PointMeanDistance <- data.table::data.table(
    PULocationID = c(1, 2),
    DOLocationID = c(3, 4),
    trip_miles_mean = c(1.5, 2.3)
  )

  all_trips <- data.table::data.table(
    request_datetime = as.POSIXct(rep(c("2023-10-01 10:01:00", "2023-10-01 10:02:00"), 50)),
    hvfhs_license_num = rep(c("HV123", "HV456"), 50),
    wav_match_flag = rep(c("N", "Y"), 50),
    DOLocationID = rep(c(3, 4), 50),
    driver_pay = rnorm(100, mean = 25, sd = 5),
    tips = rnorm(100, mean = 5, sd = 2),
    trip_time = rnorm(100, mean = 600, sd = 100)
  )

  # Save all_trips to parquet format
  parquet_path <- tempfile(fileext = ".parquet")
  arrow::write_parquet(all_trips, parquet_path)
  on.exit(file.remove(parquet_path), add = TRUE)

  # Test data loading and basic functionality
  it("should load data and return correct output structure", {
    result <- add_take_current_trip(trip_sample, PointMeanDistance, parquet_path)

    expect_s3_class(result, "data.table")
    expect_equal(nrow(result), nrow(trip_sample))
    expect_true(all(c("trip_id", "take_current_trip", "performance_per_hour", "percentile_75_performance") %in% names(result)))
  })

  # Test filtering and constraints
  it("should correctly filter trips based on time, company, and wheelchair accessibility", {
    result <- add_take_current_trip(trip_sample, PointMeanDistance, parquet_path)

    for (i in 1:nrow(trip_sample)) {
      filtered_trips <- result[trip_id == i]
      expect_true(all(filtered_trips$request_datetime >= (trip_sample$request_datetime[i] + lubridate::seconds(3))))
      expect_true(all(filtered_trips$request_datetime <= (trip_sample$request_datetime[i] + lubridate::minutes(15))))
      expect_equal(unique(filtered_trips$hvfhs_license_num), trip_sample$hvfhs_license_num[i])

      if (trip_sample$wav_match_flag[i] == "N") {
        expect_true(all(filtered_trips$wav_match_flag == "N"))
      } else {
        expect_true(all(filtered_trips$wav_match_flag %in% c("Y", "N")))
      }
    }
  })

  # Test distance matching and long-distance pickup rules
  it("should correctly match distances and apply long-distance pickup rules", {
    result <- add_take_current_trip(trip_sample, PointMeanDistance, parquet_path)

    expect_equal(result[trip_id == 1, unique(trip_miles_mean)], PointMeanDistance[PULocationID == 1, trip_miles_mean])
    expect_equal(result[trip_id == 2, unique(trip_miles_mean)], PointMeanDistance[PULocationID == 2, trip_miles_mean])

    # Check long-distance pickup rules
    expect_true(all(
      result[, (request_datetime <= (i.request_datetime + lubridate::minutes(1)) & trip_miles_mean <= 1) |
               (request_datetime <= (i.request_datetime + lubridate::minutes(3)) & trip_miles_mean <= 3) |
               (request_datetime <= (i.request_datetime + lubridate::minutes(5)) & trip_miles_mean <= 5) |
               (request_datetime <= (i.request_datetime + lubridate::minutes(7)) & trip_miles_mean <= 7) |
               (request_datetime <= (i.request_datetime + lubridate::minutes(9)) & trip_miles_mean <= 9) |
               (request_datetime <= (i.request_datetime + lubridate::minutes(11)) & trip_miles_mean <= 11) |
               (request_datetime <= (i.request_datetime + lubridate::minutes(13)) & trip_miles_mean <= 13) |
               (request_datetime <= (i.request_datetime + lubridate::minutes(15)) & trip_miles_mean <= 15)]
    ))
  })

  # Test performance calculation and decision making
  it("should calculate performance correctly and make proper decisions", {
    result <- add_take_current_trip(trip_sample, PointMeanDistance, parquet_path)

    expect_true(all(result$waiting_secs >= 3 & result$waiting_secs <= 900))
    expect_true(all(result$performance_per_hour > 0, na.rm = TRUE))

    for (i in 1:nrow(trip_sample)) {
      trip_results <- result[trip_id == i]
      expect_equal(trip_results$percentile_75_performance, quantile(trip_results$performance_per_hour, 0.75, na.rm = TRUE))
      expect_true(all(trip_results$take_current_trip == (trip_results$performance_per_hour <= trip_results$percentile_75_performance)))
    }
  })

  # Test edge cases
  it("should handle edge cases gracefully", {
    # Create edge case data
    edge_trips <- data.table::copy(all_trips)
    edge_trips$trip_time[1] <- 0  # Zero trip time
    edge_trips$driver_pay[2] <- NA  # Missing pay
    edge_trips$tips[3] <- -5  # Negative tips
    edge_trips$driver_pay[4] <- 1e6  # Extremely large pay

    edge_parquet_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(edge_trips, edge_parquet_path)

    result <- add_take_current_trip(trip_sample, PointMeanDistance, edge_parquet_path)

    expect_true(is.nan(result$performance_per_hour[1]) || is.infinite(result$performance_per_hour[1]))
    expect_true(is.na(result$performance_per_hour[2]))
    expect_true(result$performance_per_hour[3] < 0)
    expect_true(result$performance_per_hour[4] > 1e4)
  })

  # Test empty input handling
  it("should handle empty inputs gracefully", {
    empty_trip_sample <- trip_sample[0]
    empty_point_mean_distance <- PointMeanDistance[0]
    empty_all_trips <- all_trips[0]

    empty_parquet_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(empty_all_trips, empty_parquet_path)

    expect_error(add_take_current_trip(empty_trip_sample, PointMeanDistance, parquet_path), NA)
    expect_error(add_take_current_trip(trip_sample, empty_point_mean_distance, parquet_path), NA)

    result <- add_take_current_trip(trip_sample, PointMeanDistance, empty_parquet_path)
    expect_true(nrow(result) == nrow(trip_sample) && all(is.na(result$take_current_trip)))
  })

  # Test no matching future trips scenario
  it("should handle scenarios with no matching future trips", {
    future_trips <- data.table::copy(all_trips)
    future_trips[, request_datetime := as.POSIXct("2023-10-01 12:00:00")]  # All trips outside the time window

    no_matches_parquet_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(future_trips, no_matches_parquet_path)

    result <- add_take_current_trip(trip_sample, PointMeanDistance, no_matches_parquet_path)

    expect_true(all(is.na(result$take_current_trip)))
    expect_true(all(is.na(result$performance_per_hour)))
  })
})
