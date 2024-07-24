describe("simulate_trips()",{

  # Getting connecting

  temp_con = DBI::dbConnect(duckdb::duckdb(),
                            test_path("fixtures", "test-db.duckdb"))

  SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))


  it("only accepts connections with NycTrips and PointMeanDistance",{

    empty_con = DBI::dbConnect(duckdb::duckdb())

    expect_error({
      simulate_trips(empty_con, SimulationStartTrips)
    })

  })


  it("only accepts data.table as start_points", {

    expect_error({
      simulate_trips(temp_con, as.data.frame(SimulationStartTrips))
    })

  })

  it("runs",{

    expect_no_error({
      simulation_example = simulate_trips(temp_con, SimulationStartTrips)
    })

  })


  it("report the expected columns",{

    expect_equal(names(simulation_example),
                 c("simulation_id",
                   "sim_trip_id",
                   "sim_hvfhs_license_num",
                   "sim_wav_match_flag",
                   "sim_PULocationID",
                   "sim_DOLocationID",
                   "sim_request_datetime",
                   "sim_dropoff_datetime",
                   "sim_driver_pay",
                   "sim_tips"))

  })

  it("the simulation_id correspond to first trip",{

    expect_equal(simulation_example[simulation_id == sim_trip_id, `sim_trip_id`],
                 simulation_example[, .SD[1, `sim_trip_id`], by = "simulation_id"])

  })


  it("keeps the taxi company constant of each simulation",{

    expect_equal(simulation_example[, .(unique_count = uniqueN(sim_hvfhs_license_num)),
                                    by = "simulation_id"][, unique_count],
                 c(1L, 1L))

  })


  it("keeps the taxi company constant wheelchair-accessible",{

    expect_equal(simulation_example[, .(unique_count = uniqueN(sim_wav_match_flag)),
                                    by = "simulation_id"][, unique_count],
                 c(2L, 1L))

  })


})
