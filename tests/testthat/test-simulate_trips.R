describe("simulate_trips()",{

  # Getting connecting

  temp_con = DBI::dbConnect(duckdb::duckdb(),
                            test_path("fixtures", "test-db.duckdb"))

  SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))

  it("The simulation runs"){

    expect_no_error({
      simulate_trips(con,)
    })

  }

  it("The TLC license number needs to keep constant."){

  }

})
