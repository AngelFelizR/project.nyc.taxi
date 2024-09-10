#' Confirm whether a taxi driver should take the current trip
#'
#' @param conn Duckdb connection to NycTrips and PointMeanDistance tables.
#' @param start_points A data.table all trips to evaluate.
#' @param max_min Defines the time limit and distance to find better trips
#' @param trip_criteria Defines the criteria we want to use when selecting a trip.
#'
#' @return A data.table.
#' @export
set_take_current_trip <- function(conn,
                                  start_points,
                                  max_min = 15,
                                  trip_criteria = c("one_trip", "median", "75%")) {

  trip_criteria = match.arg(trip_criteria)

  validate_simulation_data(conn, start_points)

  take_trip_confirmation =
    sapply(1:nrow(start_points),\(simulation_i){

      # Defining values to keep constant
      taxi_company_code = start_points$hvfhs_license_num[simulation_i]

      # Defining valid wav trip for this simulation
      can_take_wav =
        if(start_points$wav_match_flag[simulation_i] == "Y"){
          "('Y', 'N')"
        }else{
          "('N')"
        }

      # The current trip defines the current position, time and performance
      current_position = start_points$PULocationID[simulation_i]
      current_time = start_points$request_datetime[simulation_i]
      current_performace = start_points$performance_per_hour[simulation_i]

      distance_time_limit =
        seq(3, max_min, by = 2) |>
        (\(x) if(!max_min %in% x) c(x, max_min) else x )() |>
        (\(x) paste0("OR (t1.request_datetime <= (TIMESTAMP '",current_time,"' + INTERVAL ", x, " MINUTE) AND t2.trip_miles_mean <= ", x,")") )() |>
        paste0(collapse = " ")

        # The query to extract information from DB
        query_to_find_trips = glue::glue("
        SELECT t1.*
        FROM NycTrips t1
        INNER JOIN (
          SELECT * FROM PointMeanDistance WHERE PULocationID = {current_position}
        ) t2
          ON t1.PULocationID = t2.DOLocationID
        WHERE t1.hvfhs_license_num = '{taxi_company_code}'
        AND t1.wav_match_flag IN {can_take_wav}
        AND t1.request_datetime >= '{current_time}'
        AND (
         (t1.request_datetime <= (TIMESTAMP '{current_time}' + INTERVAL 1 MINUTE) AND t2.trip_miles_mean <= 1)
         {distance_time_limit}
        )
        ORDER BY t1.request_datetime
      ")

        # Running the query
        trips_found = DBI::dbGetQuery(conn, query_to_find_trips)
        data.table::setDT(trips_found)

        trips_found[, waiting_secs := difftime(request_datetime, current_time, units = "secs") |> as.double()]
        trips_found[, performance_per_hour := (driver_pay + tips) / ((trip_time + waiting_secs) / 3600)]

        take_current_trip =
          switch (trip_criteria,
                  "one_trip" = !any(trips_found$performance_per_hour > current_performace),
                  "median" = stats::median(trips_found$performance_per_hour, na.rm = TRUE) < current_performace,
                  "75%" = stats::quantile(trips_found$performance_per_hour, prob = 0.75, na.rm = TRUE) < current_performace) |>
          as.integer()

      return(take_current_trip)

    })

  start_points[, take_current_trip := take_trip_confirmation]

  return(start_points[])

}
