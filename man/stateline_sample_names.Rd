% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/analysis.R
\name{stateline_sample_names}
\alias{stateline_sample_names}
\title{Create vector of sample names from stateline output}
\usage{
stateline_sample_names(sample_names = NULL)
}
\arguments{
\item{sample_names}{Vector of names for samples being fitted in the model}
}
\value{
character vector.
}
\description{
Generates vector of names for columns of stateline output files
Without any arguments, returns column names for final 5 columns in
stateline output files:  energy, sigma, beta, accepted, swap_type.
These values are appended to any other names passed in via
\code{sample_names}.
}

