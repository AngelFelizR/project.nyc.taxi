describe("simulate_trips()",{

  # Creating a temporal connection
  temp_con = DBI::dbConnect(duckdb::duckdb())

  # To create a my own example a need to create 5 locations
  # in a concrete space using x and y as coordinates
  location_positions =
    data.frame(id = 1:5,
               x = c(0, 1, 1, 3, 3),
               y = c(0, 0, 5, 0, 7))

  # We can check the configuration using ggplot2
  # ggplot2::ggplot(location_positions,
  #                 ggplot2::aes(x,y)) +
  #   ggplot2::geom_label(ggplot2::aes(label = id)) +
  #   ggplot2::scale_x_continuous(breaks = scales::breaks_width(1))+
  #   ggplot2::scale_y_continuous(breaks = scales::breaks_width(1))+
  #   ggplot2::theme_classic()

  # Now we can calculate the distance for each point in both sense
  all_distance <-
    dist(location_positions[, -1], upper = TRUE)  |>
    as.matrix() |>
    as.data.frame()

  # Now we just need to reshape the distance
  data.table::setDT(all_distance)[, PULocationID := location_positions$id]

  PointMeanDistance = data.table::melt(
    all_distance,
    id.vars = "PULocationID",
    variable.name = "DOLocationID",
    value.name = "trip_miles_mean",
    variable.factor = FALSE
  )[, DOLocationID := as.integer(DOLocationID)]

  DBI::dbWriteTable(temp_con, "PointMeanDistance", PointMeanDistance)


  # Saving distance


    names(BaseLineSimulation)

  start_trips = data.table::data.table(
    trip_id = c(218799831, 260042034, 260089720),
    hvfhs_license_num = c("HV0005", "HV0003", "HV0003"),
    dispatching_base_num = c("B03406", "B03404", "B03404"),
    originating_base_num = c(NA, "B03404", "B03404"),
    request_datetime = as.POSIXct(
      c("2023-01-12 20:14:29", "2023-03-17 18:50:16", "2023-03-17 19:18:02"),
      tz = "UTC"
    ),
    dropoff_datetime = as.POSIXct(
      c("2023-01-12 20:25:49", "2023-03-17 19:11:35", "2023-03-17 19:49:02"),
      tz = "UTC"
    ),
    PULocationID = c(50, 80, 11),
    DOLocationID = c(230, 17, 14),
    trip_miles = c(0.993, 2.25, 4.52),
    trip_time = c(481, 989, 1732),
    base_passenger_fare = c(8.26, 16.93, 24),
    tolls = numeric(3),
    bcf = c(0.25, 0.51, 0.72),
    sales_tax = c(0.73, 1.5, 2.13),
    congestion_surcharge = c(2.75, 0, 0),
    airport_fee = numeric(3),
    tips = numeric(3),
    driver_pay = c(5.47, 13.32, 22.22),
    shared_request_flag = rep("N", 3L),
    shared_match_flag = rep("N", 3L),
    access_a_ride_flag = c("N", " ", " "),
    wav_request_flag = rep("N", 3L),
    wav_match_flag = rep("N", 3L),
    month = c("01", "03", "03"),
    year = rep(2023, 3L),
    performance_per_hour = c(28.958823529411763, 37.49179046129789, 43.00645161290322)
  )

  DBI::dbWriteTable(temp_con, "start_trips", start_trips)


  it("The simulation runs"){

    expect_no_error({
      simulate_trips(con,)
    })

  }

  it("The TLC license number needs to keep constant."){

  }

})
