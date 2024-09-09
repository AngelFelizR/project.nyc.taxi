describe("simulate_trips()",{

  it("only accepts connections with NycTrips and PointMeanDistance",{

    # ARRANGE
    empty_con = DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(empty_con, shutdown = TRUE), add = TRUE)
    SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))

    # ACT and ASSERT
    expect_error({
      simulate_trips(empty_con, SimulationStartTrips)
    },
    regexp = "Missing NycTrips or PointMeanDistance on DB")

  })

  it("NycTrips must have the correct columns",{

    # ARRANGE
    test_con = DBI::dbConnect(duckdb::duckdb(), test_path("fixtures", "test-db.duckdb"))
    on.exit(DBI::dbDisconnect(test_con, shutdown = TRUE), add = TRUE)

    temp_con = DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(temp_con, shutdown = TRUE), add = TRUE)
    DBI::dbWriteTable(temp_con, "NycTrips", datasets::iris)
    DBI::dbWriteTable(temp_con, "PointMeanDistance", DBI::dbReadTable(test_con, "PointMeanDistance"))

    SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))

    # ACT and ASSERT
    expect_error({
      simulate_trips(temp_con, SimulationStartTrips)
    },
    regexp = "NycTrips is missing:")

  })

  it("PointMeanDistance must have the correct columns",{

    # ARRANGE
    test_con = DBI::dbConnect(duckdb::duckdb(), test_path("fixtures", "test-db.duckdb"))
    on.exit(DBI::dbDisconnect(test_con, shutdown = TRUE), add = TRUE)

    temp_con = DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(temp_con, shutdown = TRUE), add = TRUE)
    DBI::dbWriteTable(temp_con, "PointMeanDistance", datasets::iris)
    DBI::dbWriteTable(temp_con, "NycTrips", DBI::dbReadTable(test_con, "NycTrips"))

    SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))

    # ACT and ASSERT
    expect_error({
      simulate_trips(temp_con, SimulationStartTrips)
    },
    regexp = "PointMeanDistance is missing:")

  })


  it("only accepts data.table as start_points", {

    # ARRANGE
    test_con = DBI::dbConnect(duckdb::duckdb(), test_path("fixtures", "test-db.duckdb"))
    on.exit(DBI::dbDisconnect(test_con, shutdown = TRUE), add = TRUE)

    SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))


    # ACT and ASSERT
    expect_error({
      simulate_trips(test_con, as.data.frame(SimulationStartTrips))
    },
    regexp = "start_points must be a data.table")

    expect_error({
      simulate_trips(test_con, data.table::as.data.table(datasets::iris))
    },
    regexp = "start_points is missing:")

  })


  it("simulates as expected",{

    # ARRANGE
    test_con = DBI::dbConnect(duckdb::duckdb(), test_path("fixtures", "test-db.duckdb"))
    on.exit(DBI::dbDisconnect(test_con, shutdown = TRUE), add = TRUE)

    SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))

    # ACT
    simulation_example = simulate_trips(test_con, SimulationStartTrips)

    # ASSERT

    # It has the expected columns
    expect_equal(names(simulation_example),
                 c("simulation_id",
                   "sim_trip_id",
                   "sim_hvfhs_license_num",
                   "sim_wav_match_flag",
                   "sim_PULocationID",
                   "sim_DOLocationID",
                   "sim_request_datetime",
                   "sim_dropoff_datetime",
                   "sim_trip_time",
                   "sim_driver_pay",
                   "sim_tips"))

    # The simulation_id correspond to first trip
    expect_equal(simulation_example[simulation_id == sim_trip_id, `sim_trip_id`],
                 simulation_example[, .SD[1], by = "simulation_id"]$`sim_trip_id`)

    # The taxi company is constant on each simulation
    expect_equal(simulation_example[, .(unique_count = uniqueN(sim_hvfhs_license_num)),
                                    by = "simulation_id"][, unique_count],
                 c(1L, 1L))

    # Only "Y" wheelchair-accessible can take those trips agains
    expect_equal(simulation_example[, .(unique_count = uniqueN(sim_wav_match_flag)),
                                    by = "simulation_id"][, unique_count],
                 c(2L, 1L))

    # The total time working when taking last trip
    last_trip_hours_working =
      simulation_example[, .(min_time = min(sim_request_datetime),
                             max_time = max(sim_request_datetime)),
                         by = "simulation_id"
      ][, diff_hours :=
          difftime(max_time, min_time, units = "hours") |>
          as.double()]

    expect_lte(last_trip_hours_working$diff_hours[1L], 8.5)
    expect_lte(last_trip_hours_working$diff_hours[2L], 8.5)

    # Validating the remaining rules based on trips taken
    expect_equal(simulation_example$sim_trip_id,
                 # UBER TRIPS
                 c(218799831,
                   # picking the first trip 1 one mile
                   1,
                   # it can take WA trips
                   5,
                   # Skipping trip 8 due 30 min BREAK
                   # Now taking a trip after the brake
                   10,
                   # Skipping trip 12 as 5 min waiting is not enough for long recollection trip
                   # But some seconds after a long trip is enough to take the trip
                   14,

                   # OTHER TAXI
                   218799832,
                   # picking the first trip 1 one mile
                   3,
                   # don't take trip 6 as this taxi don't support WA
                   # Even after waiting 2 min we can take a 1 mile distance trip
                   7,
                   # Skipping trip 9 due 30 min BRAKE
                   # Now taking a trip after the brake
                   11,
                   # Skipping trip 13 as 5 min waiting is not enough for long recollection trip
                   # But some seconds after a long trip is enough to take the trip
                   15
                 )
    )
  })

})
