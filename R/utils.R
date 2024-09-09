
validate_simulation_data = function(conn, start_points) {

  # Do we have tables?
  conn_tables = DBI::dbListTables(conn)

  if(!all(c("NycTrips", "PointMeanDistance") %chin% conn_tables)){
    stop("Missing NycTrips or PointMeanDistance on DB")
  }

  # Do the tables have the columns we need?

  # Saving vector as we will need it later to confirm start points
  min_trip_info = c('trip_id',
                    'hvfhs_license_num',
                    'wav_match_flag',
                    'PULocationID',
                    'DOLocationID',
                    'request_datetime',
                    'trip_time',
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


check_db_columns = function(conn,
                            table_name,
                            col_names) {

  db_table_cols =
    DBI::dbGetQuery(conn = conn,
                    glue::glue_safe("SELECT * FROM {table_name} WHERE FALSE")) |>
    names()

  missing_cols = setdiff(col_names, db_table_cols)

  if(length(missing_cols) > 0L){
    missing_cols_collapse = paste0(missing_cols, collapse = ", ")
    stop(glue::glue_safe("{table_name} is missing: {missing_cols_collapse}"))
  }

}
