#' Defines the start point for each day to simulate.
#'
#' This table is a random sample of all trips in 2023, generated using the `reservoir` method of duckdb with a seed of 3518, as described in `vignette("02-business-understanding")`.
#'
#' @format ## `SimulationStartDay`
#' A data frame with 60 rows and 22 columns:
#' \describe{
#'   \item{trip_id}{An unique indentifier for each trip.}
#'   \item{hvfhs_license_num}{The TLC license number of the HVFHS base or business. See Details.}
#'   \item{dispatching_base_num}{The TLC Base License Number of the base that dispatched the trip.}
#'   \item{originating_base_num}{Base number of the base that received the original trip request.}
#'   \item{request_datetime}{Date/time when passenger requested to be picked up.}
#'   \item{on_scene_datetime}{Date/time when driver arrived at the pick-up location (Accessible Vehicles-only).}
#'   \item{pickup_datetime}{The date and time of the trip pick-up.}
#'   \item{dropoff_datetime}{The date and time of the trip drop-off.}
#'   \item{PULocationID}{TLC Taxi Zone in which the trip began.}
#'   \item{DOLocationID}{TLC Taxi Zone in which the trip ended.}
#'   \item{trip_miles}{Total miles for passenger trip.}
#'   \item{trip_time}{Total time in seconds for passenger trip.}
#'   \item{base_passenger_fare}{Base passenger fare before tolls, tips, taxes, and fees.}
#'   \item{tolls}{Total amount of all tolls paid in trip.}
#'   \item{bcf}{Total amount collected in trip for Black Car Fund.}
#'   \item{sales_tax}{Total amount collected in trip for NYS sales tax.}
#'   \item{congestion_surcharge}{Total amount collected in trip for NYS congestion surcharge.}
#'   \item{airport_fee}{$2.50 for both drop off and pick up at LaGuardia, Newark, and John F. Kennedy airports.}
#'   \item{tips}{Total amount of tips received from passenger.}
#'   \item{driver_pay}{Total driver pay (not including tolls or tips and net of commission, surcharges, or taxes).}
#'   \item{shared_request_flag}{Did the passenger agree to a shared/pooled ride? (Y/N)}
#'   \item{shared_match_flag}{Did the passenger share the vehicle with another passenger? (Y/N)}
#'   \item{access_a_ride_flag}{Was the trip administered on behalf of the Metropolitan Transportation Authority (MTA)? (Y/N)}
#'   \item{wav_request_flag}{Did the passenger request a wheelchair-accessible vehicle (WAV)? (Y/N)}
#'   \item{wav_match_flag}{Did the trip occur in a wheelchair-accessible vehicle (WAV)? (Y/N)}
#'   \item{performance_per_hour}{Represent the return if the would have taken an hour}
#' }
#' @source <https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>
"SimulationStartDay"
