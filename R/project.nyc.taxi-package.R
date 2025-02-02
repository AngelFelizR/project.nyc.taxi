#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom data.table :=
#' @importFrom data.table %between%
#' @importFrom data.table %chin%
#' @importFrom data.table %like%
#' @importFrom data.table as.data.table
#' @importFrom data.table copy
#' @importFrom data.table fcase
#' @importFrom data.table fifelse
#' @importFrom data.table is.data.table
#' @importFrom data.table rbindlist
#' @importFrom data.table setattr
#' @importFrom data.table setDT
#' @importFrom data.table setkeyv
#' @importFrom data.table setnames
#' @importFrom data.table uniqueN
#' @importFrom DBI dbConnect
#' @importFrom DBI dbDisconnect
#' @importFrom DBI dbGetQuery
#' @importFrom duckdb duckdb
#' @importFrom future.apply future_lapply
#' @importFrom glue glue
#' @importFrom glue glue_safe
#' @importFrom leaflet addCircleMarkers
#' @importFrom leaflet addLegend
#' @importFrom leaflet addProviderTiles
#' @importFrom leaflet addTiles
#' @importFrom leaflet colorFactor
#' @importFrom leaflet leaflet
#' @importFrom leaflet markerClusterOptions
#' @importFrom lubridate as_datetime
#' @importFrom lubridate cyclic_encoding
#' @importFrom lubridate hours
#' @importFrom lubridate make_datetime
#' @importFrom lubridate minutes
#' @importFrom lubridate month
#' @importFrom lubridate year
#' @importFrom maptiles get_tiles
#' @importFrom sf st_polygon
#' @importFrom sf st_sfc
#' @importFrom stats median
#' @importFrom stats quantile
#' @importFrom stats sd
#' @importFrom timeDate listHolidays
#' @importFrom tmap tm_basemap
#' @importFrom tmap tm_borders
#' @importFrom tmap tm_shape
#' @importFrom utils tail
#' @importFrom withr local_seed
## usethis namespace: end
NULL



# Solving Global Variables problem

utils::globalVariables(c(

  ## From plot_map
  "color_variable",

  ## From simulate_trips
  "trip_id",
  "hvfhs_license_num",
  "wav_match_flag",
  "PULocationID",
  "DOLocationID",
  "request_datetime",
  "dropoff_datetime",
  "driver_pay",
  "tips",

  # From add_take_current_trip
  ".",
  ".SD",
  "wav_request_flag",
  "percentile_75_performance",
  "performance_per_hour",
  "take_current_trip",
  "trip_miles_mean",
  "trip_time",
  "waiting_secs"

))
