% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/grass.r
\name{find_grass}
\alias{find_grass}
\title{Try to locate a user's GRASS GIS installation}
\usage{
find_grass()
}
\value{
The path to the user's grass location, or NULL if not found
}
\description{
Locates a grass installation in common locations on Mac, Windows, and Linux. This is normally
run automatically when the package is loaded. If multiple
installations are present, the function will prefer 7.8, 7.6, 7.4, and then whatever is most recent.
}
\details{
In some (many?) cases, this function will fail to find a grass installation, or users may wish
to specify a different version than what is detected automatically. In these cases, it is possible
to manually specify the grass location using \code{options(gisBase = "path/to/grass")}.
}
