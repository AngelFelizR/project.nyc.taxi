#' Simulate a date of work for a single taxi driver.
#'
#' @param conn Duckdb connection to NycTrips and PointMeanDistance tables.
#' @param start_points A data.table with the initial trips of each simulation.
#' @param model A tidymodels workflow.
#'
#' @return A data.table.
#' @export
simulate_trips = function(conn,
                          start_points,
                          model = NULL) {

  # Do we have tables?
  conn_tables = DBI::dbListTables(conn)

  if(!all(c("NycTrips", "PointMeanDistance") %chin% conn_tables)){
    stop("Missing NycTrips or PointMeanDistance on DB")
  }

  # Do the tables have the columns we need?

  min_trip_info = c('trip_id',
                    'hvfhs_license_num',
                    'wav_match_flag',
                    'PULocationID',
                    'DOLocationID',
                    'request_datetime',
                    'dropoff_datetime',
                    'driver_pay',
                    'tips')

  check_db_columns(conn,
                   "NycTrips",
                   min_trip_info)
  check_db_columns(conn,
                   "PointMeanDistance",
                   c('PULocationID',
                     'DOLocationID',
                     'trip_miles_mean'))

  # Validating start trips
  stopifnot("start_points must be a data.table" = data.table::is.data.table(start_points))

  missing_trip_cols = setdiff(min_trip_info, names(start_points))

  if(length(missing_trip_cols) > 0L) {
    missing_trip_cols_collapse = paste0(missing_trip_cols, collapse = ", ")
    stop("start_points is missing: ", missing_trip_cols_collapse)
  }

}
