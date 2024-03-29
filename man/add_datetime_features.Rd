% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_datetime_features.R
\name{add_datetime_features}
\alias{add_datetime_features}
\title{Add more features to explain a date}
\usage{
add_datetime_features(df, date_col)
}
\arguments{
\item{df}{A data.frame with datetime column to use.}

\item{date_col}{A string to define the column to be use}
}
\value{
A data.frame with the new features.
}
\description{
Add more features to explain a date
}
\examples{
data.frame(profit_rate = 15,
           x = as.POSIXct("2024-05-18 08:00:15"),
           y = as.POSIXct("2024-07-04 08:00:15")) |>
  add_datetime_features(date_col = "x") |>
  add_datetime_features(date_col = "y")
}
