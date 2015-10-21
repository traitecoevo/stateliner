##' Run stateline to sample from the given target function.
##' @title Stateline R interface
##' @param target Target function; must be a function taking a single
##'   argument \code{x} and returning a \emph{negative} log-likelhood.
##' @param config Path to the configuration file
##' @param address Address of the delegator
##' @export
##'
stateliner <- function(target, config, address) {
  logging_start(all=FALSE)
  on.exit(logging_stop())

  loggr::log_info("Starting client")
  addr <- sprintf("ipc:///tmp/sl_worker%s.socket", random_string())

  client_args <- c("-n", address, "-w", addr)
  system2("/usr/local/bin/stateline-client", client_args, wait=FALSE)

  config <- jsonlite::fromJSON(readLines(config))
  nJobTypes <- config$nJobTypes

  ctx <- rzmq::init.context()
  socket <- rzmq::init.socket(ctx, "ZMQ_DEALER")

  loggr::log_info(sprintf("Connecting to %s...", addr))
  rzmq::connect.socket(socket, addr)
  on.exit(rzmq::disconnect.socket(socket, addr), add=TRUE)
  loggr::log_info("Connected!")

  send_hello(socket, nJobTypes)
  job_loop(socket, target)
}

## Stateline constants:
HELLO     <- "0"
HEARTBEAT <- "1"
REQUEST   <- "2"
JOB       <- "3"
RESULT    <- "4"
GOODBYE   <- "5"

handle_job <- function(target, job_type, job_data) {
  sample <- as.numeric(strsplit(job_data, ":", fixed=TRUE)[[1]])
  target(sample)
}

send_hello <- function(socket, nJobTypes) {
  loggr::log_info("Sending HELLO message...")
  msg <- c("", HELLO, sprintf("0:%s", nJobTypes))
  send_multipart_string(socket, msg)
}

random_string <- function() {
  paste(sample(letters, 10), collapse="")
}

job_loop <- function(socket, target) {
  repeat {
    loggr::log_info("Getting job...")
    r <- receive_multipart_string(socket)
    loggr::log_info("Got job!")

    stopifnot(length(r) == 5L)

    ## Oh, if only had destructuring bind
    subject <- r[[2]]
    job_type <- r[[3]]
    job_id <- r[[4]]
    job_data <- r[[5]]

    stopifnot(subject == JOB)

    result <- handle_job(target, job_type, job_data)

    loggr::log_info("Sending result...")
    rmsg <- c("", RESULT, job_id, result)
    send_multipart_string(socket, rmsg)
    loggr::log_info(sprintf("Sent result %s!", job_id))
  }
}
