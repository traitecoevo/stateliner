% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/analysis.R
\name{summarise_samples}
\alias{summarise_samples}
\title{Statistical summary of distributions}
\usage{
summarise_samples(data)
}
\arguments{
\item{data}{A single data.frame or list of data.frames}
}
\value{
A data.frame containing columns parameter, n_samples (number of samples)
mean, sd (standard deviation), median, lower (0.25) and upper (0.975) quantiles
(also known as Bayesian credible intervals) of the samples in the data
}
\description{
Statistical summary of distributions
}

