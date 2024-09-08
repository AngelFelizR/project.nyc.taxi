describe("confirm_if_best_trip()",{

  it("only accepts connections with NycTrips and PointMeanDistance",{

    # ARRANGE
    empty_con = DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(empty_con, shutdown = TRUE), add = TRUE)
    SimulationStartTrips = readRDS(test_path("fixtures", "SimulationStartTrips.rds"))

    # ACT and ASSERT
    expect_error({
      confirm_if_best_trip(empty_con, SimulationStartTrips)
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
      confirm_if_best_trip(temp_con, SimulationStartTrips)
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
      confirm_if_best_trip(temp_con, SimulationStartTrips)
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
      confirm_if_best_trip(test_con, as.data.frame(SimulationStartTrips))
    },
    regexp = "start_points must be a data.table")

    expect_error({
      confirm_if_best_trip(test_con, data.table::as.data.table(datasets::iris))
    },
    regexp = "start_points is missing:")

  })


})
