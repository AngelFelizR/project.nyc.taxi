# WARNING - Generated by {fusen} from dev/flat_functions.Rmd: do not edit by hand

#' Transform number into factors
#'
#' Transform a numeric vector in factor with a level for each day of a week.
#'
#' @param x A numeric vector with values from 1 to 7
#'
#' @return A factor vector
#' @export
#'
#' @examples
#'
#' factor_weekday(c(1,7,5))
#'
factor_weekday <- function(x){
  
  stopifnot("The vector must be numeric" = is.numeric(x))
  
  if(!all(x %in% 1:7)){
    warning("One of the number is not from 1 to 7")
  }

  weekdays_name <- c("Mo", "Tu", "We", "Th", "Fr", "Sa", "Su")

  factor(weekdays_name[x], levels = weekdays_name)

}
