describe("simulate_trips()",{

  names(BaseLineSimulation)

  temp_con = DBI::dbConnect(duckdb::duckdb())

  start_trips = data.frame(
    trip_id = 1:3,
    hvfhs_license_num = c("HV0003", "HV0003", "HV0005")
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
