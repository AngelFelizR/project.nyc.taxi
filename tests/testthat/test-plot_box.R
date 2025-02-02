test_that("plot_box creates correct spatial structure", {
  # Create test input - NYC approximate bounding box
  test_input <- matrix(
    c(-74.05, 40.7,   # Bottom-left (long, lat)
      -73.95, 40.8),  # Top-right (long, lat)
    nrow = 2, byrow = TRUE,
    dimnames = list(c("x", "y"), NULL)
  )

  # Run function
  result <- plot_box(test_input)

  # Test 1: Verify output is tmap object
  expect_s3_class(result, "tmap")

  # Test 2: Verify coordinate reference system
  expect_equal(sf::st_crs(result[[1L]][['shp']])$epsg, 4326L)

  # Test 3: Verify polygon geometry type
  expect_s3_class(result[[1L]]$shp, "sfc_POLYGON")
})

test_that("plot_box handles invalid inputs appropriately", {
  # Test 4: Non-matrix input
  expect_error(plot_box(data.frame(x = 1, y = 2)),
               "x must be a matrix")

  # Test 5: Matrix with incorrect column names
  bad_colnames <- matrix(1:4, ncol = 2)
  expect_error(plot_box(bad_colnames),
               "Matrix must have rows named 'x' and 'y'")

  # Test 6: Matrix with non-numeric values
  char_matrix <- matrix(c("a", "b", "c", "d"), ncol = 2,
                        dimnames = list(NULL, c("x", "y")))
  expect_error(plot_box(char_matrix),
               "Matrix must contain numeric values")

  # Test 7: Matrix with wrong number of rows
  three_row <- matrix(1:6, ncol = 2,
                      dimnames = list(NULL, c("x", "y")))
  expect_error(plot_box(three_row),
               "Input matrix must have exactly 2 rows")
})

test_that("plot_box creates correct polygon coordinates", {
  # Simple test case
  simple_input <- matrix(
    c(0, 0,   # BL
      1, 1),  # TR
    nrow = 2, byrow = FALSE,
    dimnames = list(c("x", "y"), NULL)
  )

  # Expected coordinates (BL → TL → TR → BR → BL)
  expected_coords <- matrix(
    c(0, 0,
      0, 1,
      1, 1,
      1, 0,
      0, 0),
    ncol = 2, byrow = TRUE,
    dimnames = list(NULL,c("X", "Y"))
  )

  # Extract coordinates from the plot object
  result <- plot_box(simple_input)
  poly_coords <- sf::st_coordinates(result[[1]]$shp)
  rownames(poly_coords) <- NULL

  # Test 8: Verify coordinate sequence
  expect_equal(poly_coords[, c("X", "Y")], expected_coords)

  # Test 9: Verify closure (first and last coordinates match)
  expect_equal(poly_coords[1, c("X", "Y")],
               poly_coords[nrow(poly_coords), c("X", "Y")])

  # Test 10: Verify number of points (4 corners + closure)
  expect_equal(nrow(poly_coords), 5)
})
