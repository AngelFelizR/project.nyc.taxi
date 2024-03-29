% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/highlight_top_zones.R
\name{highlight_top_zones}
\alias{highlight_top_zones}
\title{Highlight the most repeated zones in a Borough}
\usage{
highlight_top_zones(
  dt,
  borough,
  borough_color = "blue",
  top_color = "red",
  top_length = 5L,
  borough_col = "borough",
  col_prefix = NULL,
  zone_col = "zone",
  long_col = "long",
  lat_col = "lat"
)
}
\arguments{
\item{dt}{A \code{data.table} with the data to use from.}

\item{borough}{Defines the borough to focus the attention.}

\item{borough_color}{Defines the base color for the points to show.}

\item{top_color}{Defines the color to use for the top points.}

\item{top_length}{Defines the number points to highlight.}

\item{borough_col}{Name of Borough column to filter.}

\item{col_prefix}{Update the following column's names with this prefix.}

\item{zone_col}{Name of column with each zone name.}

\item{long_col}{Name of column with each zone long.}

\item{lat_col}{Name of column with each zone lat.}
}
\value{
A leaflet map
}
\description{
Highlight the most repeated zones in a Borough
}
