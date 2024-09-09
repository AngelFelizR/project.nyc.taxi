#' Confirm whether a taxi driver should take the current trip
#'
#' @param conn Duckdb connection to NycTrips and PointMeanDistance tables.
#' @param start_points A data.table with the initial trips of each simulation.
#'
#' @return A data.table.
#' @export
confirm_if_best_trip <- function(conn,
                                 start_points,
                                 max_min) {

  validate_simulation_data(conn, start_points)

}
