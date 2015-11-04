##' Generates vector of names for columns of stateline output files
##' Without any arguments, returns column names for final 5 columns in
##' stateline output files:  energy, sigma, beta, accepted, swap_type.
##' These values are appended to any other names passed in via
##' \code{sample_names}.
##'
##' @title Create vector of sample names from stateline output
##'
##' @param sample_names Vector of names for samples being fitted in the model
##' @export
##' @return character vector.
stateline_sample_names <- function(sample_names = NULL) {
  c(sample_names, "energy", "sigma", "beta", "accepted", "swap_type")
}

##' Load a single stateline output file.
##' We use the \code{read\_csv} function from the \code{readr}
##' package, resulting in faster load times and better display.
##'
##' @title Load a single stateline output file
##'
##' @param stack Number of chain
##' @param path Directory where samples are saved
##' @param sample_names Vector of names for samples being fitted in the model
##' @return Returns a data.frame with named columns.
##' @export
load_chain <- function(stack, path = "output", sample_names = NULL) {

  #Todo: could we make readr optional - i.e. only used if installed?
  data <- readr::read_csv(file.path(path, paste0(stack, ".csv")),
    col_names = FALSE, progress=FALSE)

  if (is.null(sample_names)) {
    sample_names <- paste0("p_", seq_len(ncol(data) - length(stateline_sample_names())))
  }
  names(data) <- stateline_sample_names(sample_names)

  data[["stack"]] <- stack
  data[["iteration"]] <- seq_len(nrow(data))

  data
}

##' Culls all samples taken prior to specified point \code{warmup}
##' from chain or of chains.
##'
##' @title Remove samples from defined warmup period
##'
##' @param data Merged or unmerged list of samples from stateline output,
##' obatined by running \code{load_chains}
##' @param warmup Length of warmup period (number of samples)
##' @export
remove_warmup <- function(data, warmup) {
  f <- function(x) subset(x, x[["iteration"]] > warmup)
  apply_over(f, data)
}

##' Load a collection of stateline output files
##'
##' @title Load a collection of stateline output files
##'
##' @param path Directory where samples are saved
##' @param nstacks Number of stacks to load
##' @param merge Boolean indicating whether stacks should be merged into
##' single data.frame
##' @param ... Arguments to \code{chain}. Including a vector
##' \code{sample\_names}, a vector of names for samples being fitted in the model
##' will give data with appropriate column names.
##' @return Returns a list with elements \code{stack\_1, stack\_2},
##' each being a data.frame with named columns, or in the case where
##' \code{merge=TRUE} a singel merged data.frame
##' @export
load_chains <- function(path, nstacks = 4, merge = FALSE, ...) {

  stacks <- seq_len(nstacks) - 1
  data <- lapply(stacks, load_chain, path = path, ...)
  names(data) <- paste0("stack_", stacks)

  if (merge) {
    data <- merge_chains(data)
  }
  data
}

##' Create a unified data.frame from a list by rbinding files together
##' @title Create single unified data.frame from a list of data.frames
##' @param x A list, or something coercible to a list
##' @export
merge_chains <- function(x) {
# Todo: could use dplyr::bind_rows which is 10x faster, but
# introduces extra package dependency
  do.call("rbind", as.list(x))
}

##' Thin chains down to specified number of samples.
##' Takes samples at fixed intervals across available length.
##'
##' @title Thin chains down to specified number of samples
##'
##' @param data Chain or list of chains to be thinned
##' @param length.out Desired number of samples in output
##' @return data.frame of similar structure to input, but with fewer
##' number of rows.
##' @export
thin_chains <- function(data, length.out = 2000) {
  f <- function(x) {
    i <- seq(1, nrow(x), length.out = min(nrow(x), length.out))
    x[i, ]
  }
  apply_over(f, data)
}

##' Check if object is a data.frame or a list of data.frames
##'
##' @title Check if object is a data.frame or a list of data.frames
##'
##' @param data A single data.frame or list of data.frames
##' @export
is.stack <- function(data) {
  is.list(data[[1]])
}

##' Applies a function over single chain or list of chains
##'
##' @title Applies a function over chains
##'
##' @param f Function to apply
##' @param data A single data.frame or list of data.frames
##' @export
apply_over <- function(f, data) {
  if (is.stack(data)) {
    lapply(data, f)
  } else {
    f(data)
  }
}

##' Drop specified columns from chains
##'
##' @title Drop specified columns from chains
##'
##' @param data A single data.frame or list of data.frames
##' @param to_drop vector of columns names to remove
##' @export
drop_columns <- function(data, to_drop) {
  f <- function(x) {
    x[, !(names(x) %in% to_drop)]
  }
  apply_over(f, data)
}

##' Statistical summary of distributions
##'
##' @title Statistical summary of distributions
##'
##' @param data A single data.frame or list of data.frames
##' @return A data.frame containing columns parameter, n_samples (number of samples)
##' mean, sd (standard deviation), median, lower (0.25) and upper (0.975) quantiles
##' (also known as Bayesian credible intervals) of the samples in the data
##' @export
summarise_samples <- function(data) {

  if (is.stack(data)) {
    data <- merge_chains(data)
  }

  data <- drop_columns(data, c(stateline_sample_names(), "stack", "iteration"))

  data.frame(parameter = colnames(data), n_samples = nrow(data), mean = colMeans(data),
    sd = apply(data, 2, sd), median = apply(data, 2, median), lower_bci = apply(data,
      2, quantile, 0.025), upper_bci = apply(data, 2, quantile, 0.975), row.names = NULL)
}

##' Gather_samples is built off \code{tidyr}'s \code{gather} function, which
##' takes multiple columns and collapses into key-value pairs with other
##' columns being "stack", "iteration".
##'
##' @title Gather columns into key-value pairs.
##'
##' @param data A single data.frame or list of data.frames
##' @param pars List of parameters to include
##' @param drop List of columns to drop. By default stateline's extra columns
##'  (energy, sigma, beta, accepted, swap_type) are removed.
##' @param thin If set to a numeric value, will thin samples down to
##' specified length using \code{thin\_chains} function.
##' @export
##' @return data.frame with columns stack, iteration, parameter, value
gather_samples <- function(data, pars = NULL, drop = stateline_sample_names(), thin = NULL) {

  if (!is.null(thin)) {
    data <- thin_chains(data, thin)
  }

  if (is.stack(data)) {
    data <- merge_chains(data)
  }

  data <- drop_columns(data, drop)

  samples <- tidyr::gather(data, parameter, value, -c(stack, iteration))
  samples[["stack"]] <- as.factor(samples[["stack"]])

  if (!is.null(pars)) {
    samples <- subset(samples, parameter %in% c(pars, "stack", "iteration"))
  }

  samples
}

##' Default theme used in plotting stateline objects (via \code{ggplot2})
##'
##' @title Default theme used in plotting stateline objects
##'
##' @param ... Extra augments for \code{ggplot2::theme} function.
##' @export
stateline_theme <- function(...) {

  ggplot2::theme_classic() +
    ggplot2::theme(axis.title = ggplot2::element_text(face = "bold", size = 13),
      axis.text = ggplot2::element_text(size = 9),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(color = "black", face = "bold", size = 13),
      plot.title = ggplot2::element_text(size = 18),
       ...)
}

##' Trace plot of specified parameters against iteration number.
##' Good sampling is indicated by convergence and nice mixing of chains.
##'
##' @title Trace plot of specified parameters against iteration number.
##'
##' @param data A single data.frame or list of data.frames
##' @param thin Numeric value (default =2000) indicating number of samples to
##' include in plot. Chains are thinned to specified length using \code{thin\_chains}.
##' @param pars List of parameters to include
##' @param xlab label for xaxis
##' @param ylab label for yaxis
##' @param scales By default set to "free", indicating each subplot will have different
##' scale on yaxis. Set to "fixed" to enforce similar axes over all plots.
##' @param ... Extra augments for \code{ggplot2::theme} function.
##' @export
trace_plot <- function(data, thin = 2000, pars = NULL, xlab = "iterations",
  ylab = "standardized value", scales = "free", ...) {

  samples <- gather_samples(data, pars=pars, thin=thin)

  ggplot2::ggplot(samples, ggplot2::aes(x = iteration, y = value, group = stack, color = stack)) +
    ggplot2::labs(x = xlab, y = ylab) +
    ggplot2::annotate("rect", xmin = -Inf, xmax = Inf, ymin = -Inf,
    ymax = Inf, fill = "gray90") +
    ggplot2::geom_path() +
    ggplot2::scale_colour_brewer(palette = "Set1") +
    stateline_theme(
      legend.position = "none",
      legend.title = ggplot2::element_text(size = 13),
      legend.text = ggplot2::element_text(size = 11), ...) +
    ggplot2::facet_wrap(~parameter, scales = scales)
}

##' Density distributions of specified parameters.
##'
##' @title Density distributions of specified parameters.
##'
##' @param data A single data.frame or list of data.frames
##' @param pars List of parameters to include
##' @param xlab label for xaxis
##' @param scales By default set to "free", indicating each subplot will have different
##' scale on yaxis. Set to "fixed" to enforce similar axes over all plots.
##' @param ... Extra augments for \code{ggplot2::theme} function.
##' @export
density_plot <- function(data, pars = NULL, xlab = "standardized value",
  scales = "free", ...) {

  samples <- gather_samples(data, pars=pars)

  ggplot2::ggplot(samples, ggplot2::aes(x = value, fill = "red")) +
  ggplot2::labs(x = xlab) +
  ggplot2::geom_density(alpha = 0.6) +
  stateline_theme(...) +
  ggplot2::facet_wrap(~parameter, scales = scales)
}
