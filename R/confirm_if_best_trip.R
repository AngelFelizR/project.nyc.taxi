#' Confirm whether a taxi driver should take the current trip
#'
#' @param conn Duckdb connection to NycTrips and PointMeanDistance tables.
#' @param start_points A data.table all trips to evaluate.
#' @param max_min Defines the time limit and distance to find better trips
#' @param trip_criteria Defines the criteria we want to use when selecting a trip.
#'
#' @return A data.table.
#' @export
set_take_current_trip <- function(path_to_parquet,
                                  start_points,
                                  max_min = 15,
                                  trip_criteria = c("one_trip", "median", "75%")) {

  withr::local_options(list(future.globals.maxSize = 7 * 1024^3))

  apply::plan(multisession, workers = 4)

  results <-
    lapply(1:nrow(SampleMonths), \(month_i){

      ValidZoneSample_i <- ValidZoneSample[SampleMonths[month_i], on = c("year", "month")]
      NycTrips_i <- dbGetQuery(con,glue("SELECT * FROM {ParquetFiles[month_i]}"))
      setDT(NycTrips_i)


      # Step 1: Calculate waiting_secs and performance_per_hour for joined data
      trip_data <-
        future_lapply(1:nrow(ValidZoneSample_i), \(n_row){

          time_trips <-
            NycTrips_i[ValidZoneSample_i[n_row],
                       on = "hvfhs_license_num"
            ][request_datetime >= i.request_datetime &
                request_datetime <= request_datetime_extra]

          current_trip_alternatives <-
            PointMeanDistance[.(ValidZoneSample_i$`PULocationID`[n_row]),
                              on = "PULocationID",
                              nomatch = NULL
            ][time_trips,
              on = c("DOLocationID" = "PULocationID"),
            ][, waiting_secs := as.numeric(difftime(request_datetime, i.request_datetime, units = "secs"))
            ][, performance_per_hour := (driver_pay + tips) / ((trip_time + waiting_secs) / 3600)
            ][(request_datetime <= i.request_datetime + 60 & trip_miles_mean <= 1) |
                (request_datetime <= i.request_datetime + 180 & trip_miles_mean <= 3) |
                (request_datetime <= i.request_datetime + 300 & trip_miles_mean <= 5) |
                (request_datetime <= i.request_datetime + 420 & trip_miles_mean <= 7) |
                (request_datetime <= i.request_datetime + 540 & trip_miles_mean <= 9) |
                (request_datetime <= i.request_datetime + 660 & trip_miles_mean <= 11) |
                (request_datetime <= i.request_datetime + 780 & trip_miles_mean <= 13) |
                (request_datetime <= i.request_datetime + 900 & trip_miles_mean <= 15) &
                ((i.wav_match_flag == 'Y' & wav_match_flag %in% c('Y', 'N')) |
                   (i.wav_match_flag == 'N' & wav_match_flag == 'N'))]

          return(current_trip_alternatives)

        }) |>
        rbindlist()

      # Step 2: Aggregate data by performance metrics
      aggregated_data <- trip_data[
        , .(percentile_75_performance = quantile(performance_per_hour, 0.75, na.rm = TRUE)),
        by = "trip_id"
      ]


      # Step 3: Join aggregated data with ValidZoneSample
      final_data <-
        ValidZoneSample_i[aggregated_data,
                          on = "trip_id"
        ][, take_current_trip := fifelse(performance_per_hour > percentile_75_performance, 0L, 1L)]


      # Result
      return(final_data[])

    })|>
    rbindlist()

}
