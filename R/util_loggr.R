##' @importFrom loggr log_file
logging_start <- function(all=TRUE) {
  subscriptions <- c(if (all) "INFO", "DEBUG")
  loggr::log_file("console", .warning=FALSE, .error=FALSE, .message=FALSE,
                  subscriptions=subscriptions)
}

logging_stop <- function() {
  loggr::deactivate_log()
}
