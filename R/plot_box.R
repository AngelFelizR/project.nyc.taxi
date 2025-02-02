#' Map layer: box
#'
#' Creates a map layer displaying a rectangular polygon from input coordinates. The box is rendered with fixed blue borders (2px width) on a CartoDB.Positron basemap.
#'
#' @param x A 2-row matrix with columns named 'x' and 'y' specifying opposite rectangle corners (e.g., bottom-left and top-right). Coordinates should be in WGS84 (longitude/latitude).
#' @return A tmap object displaying the rectangular polygon layer. The map can be rendered by printing or plotting the returned object.
#' @details
#' This function processes input coordinates as follows:
#' 1. Transposes the input matrix to extract x/y coordinates
#' 2. Generates all corner combinations using expand.grid()
#' 3. Orders points to form a closed rectangle polygon (BL → TL → TR → BR → BL)
#' 4. Converts to an sf polygon with CRS 4326
#' 5. Plots using tmap with fixed style parameters
#'
#' Visual properties (border color/width) and basemap are currently hard-coded.
#'
#' @examples
#' # Create a matrix with opposite corners
#' box_coords <- matrix(
#' c(-74.05, 40.7, # Bottom-left
#' -73.95, 40.8), # Top-right
#' nrow = 2, byrow = TRUE,
#' dimnames = list(c("x", "y"), NULL)
#' )
#'
#' # Generate and display map
#' plot_box(box_coords)
#'
#' @seealso [tmap::tm_polygons()], [sf::st_polygon()]
#' @export
plot_box <- function(x) {
  # Input validation
  if (!is.matrix(x))
    stop("x must be a matrix")
  if (nrow(x) != 2)
    stop("Input matrix must have exactly 2 rows")
  if (!is.numeric(x))
    stop("Matrix must contain numeric values")
  if (!all(c("x", "y") %in% rownames(x)))
    stop("Matrix must have rows named 'x' and 'y'")

  # Create polygon geometry
  sf_box <- t(x) |>
    (\(m) expand.grid(x = m[, "x"], y = m[, "y"]))() |>
    (\(df) df[c(1, 3, 4, 2, 1), ])() |>
    as.matrix() |>
    list() |>
    sf::st_polygon() |>
    sf::st_sfc(crs = 4326)

  # Create tmap visualization
  plot_output <- tmap::tm_shape(sf_box) +
    tmap::tm_borders(col = "blue", lwd = 2) +
    tmap::tm_basemap("CartoDB.Positron")

  return(plot_output)
}
