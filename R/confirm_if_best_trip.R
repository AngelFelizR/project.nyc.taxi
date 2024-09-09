#' Confirm whether a taxi driver should take the current trip
#'
#' @param conn Duckdb connection to NycTrips and PointMeanDistance tables.
#' @param start_points A data.table with the initial trips of each simulation.
#'
#' @return A data.table.
#' @export
confirm_if_best_trip <- function(conn,
                                 start_points,
                                 max_min = 20) {

  validate_simulation_data(conn, start_points)


  all_simulations_table =
    lapply(1:nrow(start_points),\(simulation_i){

      # Defining values to keep constant
      taxi_company_code = start_points$hvfhs_license_num[simulation_i]

      # Defining valid wav trip for this simulation
      can_take_wav =
        if(start_points$wav_match_flag[simulation_i] == "Y"){
          "('Y', 'N')"
        }else{
          "('N')"
        }

      current_time = start_points$request_datetime[simulation_i]
      current_position = start_points$PULocationID[simulation_i]

      last_time_to_start_a_trip = current_time + lubridate::minutes(max_min)


      # 4. LOOP FOR GETTINGG ALL TRIPS
      while(current_time < last_time_to_start_a_trip) {

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
        AND t1.request_datetime <= '{trip_time_limit}'
        AND t2.trip_miles_mean <= {trip_dist_limit}
        ORDER BY t1.request_datetime
      ")

        # Running the query
        trips_found = DBI::dbGetQuery(conn, query_to_find_trips)
        data.table::setDT(trips_found)

        # Confirming if we found trips
        if(nrow(trips_found) > 0){

          # PENDING - FILTER BASED ON PREDICTIONS

          # Accepting the first requested trip
          simulated_trips =
            rbind(simulated_trips,
                  trips_found[1L, ],
                  use.names = TRUE,
                  fill = TRUE)

          # Getting ready for a new search
          current_time =
            utils::tail(trips_found$request_datetime, 1L) +
            utils::tail(lubridate::seconds(trips_found$trip_time), 1L)

          current_position =
            utils::tail(trips_found$DOLocationID, 1L)

          n_search_iteration = 0

          trip_time_limit = current_time + lubridate::minutes(1)
          trip_dist_limit = 1

        }else{

          # Getting ready for a new search
          if(n_search_iteration == 0){
            current_time = current_time + lubridate::minutes(1)
          }else{
            current_time = current_time + lubridate::minutes(2)
          }
          n_search_iteration = n_search_iteration + 1
          trip_dist_limit = 1 + n_search_iteration * 2
          trip_time_limit = current_time + lubridate::minutes(2)

        }


        # USEFULL FOR TESTING THE SIMULATION
        # if(length(simulated_trips$trip_id) == 4L && n_search_iteration == 2) {
        #   browser()
        # }


        # Confirming if is time to take the break
        if(break_taken == FALSE && current_time >= time_to_take_break){

          break_taken = TRUE
          current_time = current_time + lubridate::minutes(30)

        }


      }

      # Returning the data in the expected shape
      shaped_table =
        simulated_trips[, list(simulation_id = trip_id[1L],
                               sim_trip_id = trip_id,
                               sim_hvfhs_license_num = hvfhs_license_num,
                               sim_wav_match_flag = wav_match_flag,
                               sim_PULocationID = PULocationID,
                               sim_DOLocationID = DOLocationID,
                               sim_request_datetime = request_datetime,
                               sim_dropoff_datetime = dropoff_datetime,
                               sim_trip_time = trip_time,
                               sim_driver_pay = driver_pay,
                               sim_tips = tips)]

      return(shaped_table)

    }) |>
    data.table::rbindlist()


}
