# WARNING - Generated by {fusen} from dev/flat_functions.Rmd: do not edit by hand

set.seed(1234)

arrow_con <- 
  data.frame(char1 = sample(LETTERS[1:3], 100, replace = TRUE),
             char2 = sample(LETTERS[4:6], 100, replace = TRUE)) |>
  arrow::arrow_table()

# One var
dt1 <- count_pct(arrow_con, char1)

# Two vars
dt2 <-
  count_pct(arrow_con, char1, char2) |>
  count_pct(char1, wt = n)

testthat::test_that("wt is working",{
  
  expect_equal(
    dt2, dt1
  )
  
})

