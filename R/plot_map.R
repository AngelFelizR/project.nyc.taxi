#' Creates an interactive map with colors
#'
#' @param dt A data.table with the points to show.
#' @param lng_var A character vector indicating the longitude in dt.
#' @param lat_var A character vector indicating the latitude in dt.
#' @param color A character vector to define a custom color for all points.
#' @param color_var A character vector indicating a categorical column in dt.
#' @param color_palette A character selecting the color to use by each level.
#' @param label_var A character vector indicating a categorical column in dt with information .
#' @param map_provider A character vector indicating
#' @param radius A double defining the size of circles to plot.
#' @param radius_var A character vector indicating a numeric column.
#' @param cluster_points If `TRUE` if we have many points it will stop showing all points and showing the sum by sub-regions.
#'
#' @return An interactive map
#' @export
#'
#' @examples
#'
#' dt = data.table::data.table(
#'   Borough = c("Queens", "Manhattan", "Brooklyn"),
#'   Zone = c("Steinway", "Highbridge Park", "Canarsie"),
#'   lat = c(40.77376, 40.84173, 40.64364),
#'   long = c(-73.90494, -73.9355, -73.90069)
#' )
#'
#' plot_map(
#'   dt,
#'   lng_var = "long",
#'   lat_var = "lat",
#'   color_var = "Borough",
#'   color_palette = c('Manhattan' = '#e41a1c',
#'                     'Queens' = '#377eb8',
#'                     'Brooklyn'= '#4daf4a'),
#'   label_var = "Zone"
#' )
#'
plot_map <- function(dt,
                     lng_var,
                     lat_var,
                     color = NULL,
                     color_var = NULL,
                     color_palette = NULL,
                     label_var = NULL,
                     map_provider = "CartoDB",
                     radius = 6,
                     radius_var = NULL,
                     cluster_points = FALSE) {

  # Selecting base information
  dt_col_names <- names(dt)

  ## Assertive programming

  # Confirming forming formating
  stopifnot("dt must be a data.table" =
              data.table::is.data.table(dt))

  # The variable are in the data
  stopifnot("lng_var and lat_var can not be found in dt" =
              all(c(lng_var, lat_var) %chin% dt_col_names))

  stopifnot("color_var can not be found in dt" =
              is.null(color_var) || color_var %chin% dt_col_names)

  stopifnot("label_var can not be found in dt" =
              is.null(label_var) || label_var %chin% dt_col_names)

  stopifnot("radius_var can not be found in dt" =
              is.null(radius_var) || radius_var %chin% dt_col_names)

  # Confirming we have all information needed
  stopifnot("If you have defined a color_var you also need to define a color_palette" =
              is.null(color_var) == is.null(color_palette))


  # If want to show color we need to apply the next steps

  if(!is.null(color_var)) {

    color_levels <- names(color_palette)

    # Confirming we are selecting a valid values for the palette
    stopifnot("color_levels names don't match with values stored in color_var" =
                is.null(color_levels) || all(color_levels %chin% unique(dt[[color_var]])))

    # Updating data
    dt <-
      dt[color_variable %chin% color_levels,
         env = list(color_variable = color_var)]

    # Defining palette
    pal <- leaflet::colorFactor(
      palette = color_palette,
      levels = color_levels
    )

  }

  pick_values <- function(x, temp_dt = dt) {
    if(is.null(x)) return(x)
    temp_dt[[x]]
  }

  # Creating interactive map
  final_map <-
    leaflet::leaflet() |>
    leaflet::addTiles() |>
    leaflet::addProviderTiles(map_provider) |>
    leaflet::addCircleMarkers(
      lng = pick_values(lng_var),
      lat = pick_values(lat_var),
      radius = if(is.null(radius_var)) radius else radius * (pick_values(radius_var) / max(pick_values(radius_var))) ,
      color = if(is.null(color_var)) color else pal(pick_values(color_var)),
      label = pick_values(label_var),
      clusterOptions = if(cluster_points) leaflet::markerClusterOptions() else NULL
    )

  # Adding legend when need it
  if(!is.null(color_var)) {
    final_map <- leaflet::addLegend(
      final_map,
      position = "topleft",
      pal = pal,
      values = color_levels
    )
  }


  return(final_map)

}
