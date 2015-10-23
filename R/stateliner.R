##' Run stateline to sample from the given target function.
##' @title Stateline R interface
##' @param target Target function; must be a function taking a single
##'   argument \code{x} and returning a \emph{negative} log-likelhood.
##' @param config Path to the configuration file
##' @param address Address of the delegator
##' @param verbose More verbose logging output?
##' @export
##'
stateliner <- function(target, config, address, verbose=FALSE) {
  logging_start(all=verbose)
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
  ## For issue #1, switch function based on `as.integer(job_type)`;
  ## this will be an integer on 0..(nJobTypes-1).  For now, we just
  ## ignore that and all jobs are handled the same way.
  ##
  ## What is not clear is if we want to pass this through to the
  ## function as a second argument (perhaps if
  ## length(formals(target))>1 or based on some sort of switch to
  ## stateliner()), or if we want to have a *list* of target functions
  ## and index that.
  ##
  ##     job_type <- as.integer(job_type)
  sample <- as.numeric(strsplit(job_data, ":", fixed=TRUE)[[1]])
  target(sample)
}

send_hello <- function(socket, nJobTypes) {
  loggr::log_info("Sending HELLO message...")
  msg <- c("", HELLO, sprintf("0:%s", nJobTypes))
  send_multipart_string(socket, msg)
}

send_goodbye <- function(socket) {
  loggr::log_info("Sending HELLO message...")
  msg <- c("", GOODBYE)
  send_multipart_string(socket, msg)
}

random_string <- function() {
  paste(sample(letters, 10), collapse="")
}

job_loop <- function(socket, target) {
  on.exit(send_goodbye(socket))
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
