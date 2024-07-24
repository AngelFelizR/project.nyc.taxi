test_that("The map works in all situations",{

  dt = data.table::data.table(
    Borough = c("Queens", "Manhattan", "Brooklyn"),
    Zone = c("Steinway", "Highbridge Park", "Canarsie"),
    lat = c(40.77376, 40.84173, 40.64364),
    long = c(-73.90494, -73.9355, -73.90069)
  )

  # The must basic plot
  expect_no_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat"
    )
  })

  # Adding color
  expect_no_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat",
      color = "red"
    )
  })

  # Adding clusters
  expect_no_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat",
      cluster_points = TRUE
    )
  })

  # Adding palette
  expect_no_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat",
      color_var = "Borough",
      color_palette = c('Manhattan' = '#e41a1c',
                        'Queens' = '#377eb8',
                        'Brooklyn'= '#4daf4a')
    )
  })

})


test_that("The map shows informative errors",{

  dt = data.table::data.table(
    Borough = c("Queens", "Manhattan", "Brooklyn"),
    Zone = c("Steinway", "Highbridge Park", "Canarsie"),
    lat = c(40.77376, 40.84173, 40.64364),
    long = c(-73.90494, -73.9355, -73.90069)
  )

  # The must basic plot
  expect_error({
    plot_map(
      dt,
      lng_var = "long",
    )
  },
  regexp = "no default")

  expect_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat_error"
    )
  },
  regexp = "can not be found")

  # Adding palette
  expect_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat",
      color_palette = c('Manhattan' = '#e41a1c',
                        'Queens' = '#377eb8',
                        'Brooklyn'= '#4daf4a')
    )
  },
  regexp = "you also need to define")


  expect_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat",
      color_var = "error_col",
      color_palette = c('Manhattan' = '#e41a1c',
                        'Queens' = '#377eb8',
                        'Brooklyn'= '#4daf4a')
    )
  },
  regexp = "can not be found")


  expect_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat",
      color_var = "Borough",
      color_palette = c('ERROR_VALUE' = '#e41a1c',
                        'Queens' = '#377eb8',
                        'Brooklyn'= '#4daf4a')
    )
  },
  regexp = "color_levels names don't match with values stored in color_var")


  expect_error({
    plot_map(
      dt,
      lng_var = "long",
      lat_var = "lat",
      label_var = "error_var"
    )
  },
  regexp = "can not be found")

})
