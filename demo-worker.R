## This could be made much more nice if the socket would arrange to
## close once it goes out of scope.

library(rzmq)
library(loggr)
library(jsonlite)

## These are little helpers...
send.socket.string <- function(socket, data, send.more=FALSE) {
  send.socket(socket, charToRaw(data), send.more=send.more, serialize=FALSE)
}
receive.socket.string <- function(socket, ...) {
  rawToChar(receive.socket(socket, unserialize=FALSE, ...))
}
send.multipart.string <- function(socket, parts) {
  for (part in parts[seq_len(length(parts) - 1L)]) {
    send.socket.string(socket, part, send.more=TRUE)
  }
  send.socket.string(socket, parts[[length(parts)]], send.more=FALSE)
}
receive.multipart.string <- function(socket) {
  vapply(receive.multipart(socket), rawToChar, character(1))
}


HELLO     <- "0"
HEARTBEAT <- "1"
REQUEST   <- "2"
JOB       <- "3"
RESULT    <- "4"
GOODBYE   <- "5"

nll <- function(x) {
  0.5 * drop(x %*% x)
}

handle_job <- function(job_type, job_data) {
  sample <- as.numeric(strsplit(job_data, ":", fixed=TRUE)[[1]])
  nll(sample)
}

send_hello <- function(socket, jobTypes) {
  loggr::log_info("Sending HELLO message...")
  msg <- c("", HELLO, paste(jobTypes, collapse=":"))
  send.multipart.string(socket, msg)
}

job_loop <- function(socket) {
  repeat {
    loggr::log_info("Getting job...")
    r <- receive.multipart.string(socket)
    loggr::log_info("Got job!")

    stopifnot(length(r) == 5L)

    ## Oh, if only had destructuring bind
    subject <- r[[2]]
    job_type <- r[[3]]
    job_id <- r[[4]]
    job_data <- r[[5]]

    stopifnot(subject == JOB)

    result <- handle_job(job_type, job_data)

    loggr::log_info("Sending result...")
    rmsg <- c("", RESULT, job_id, result)
    send.multipart.string(socket, rmsg)
    loggr::log_info(sprintf("Sent result %s!", job_id))
  }
}

logging_start <- function(all=TRUE) {
  subscriptions <- c(if (all) "INFO", "DEBUG")
  loggr::log_file("console", .warning=FALSE, .error=FALSE, .message=FALSE,
                  subscriptions=subscriptions)
}

main <- function() {
  logging_start(all=FALSE)
  on.exit(loggr::deactivate_log())

  loggr::log_info("Starting client")
  ## Ideally, we'd harvest the PID here, but that requires a
  ## subprocess-like R package
  system2("./stateline-client", wait=FALSE)

  config <- jsonlite::fromJSON(readLines("python-demo-config.json"))
  jobTypes <- config$jobTypes

  ctx <- rzmq::init.context()
  socket <- rzmq::init.socket(ctx, "ZMQ_DEALER")

  addr <- "ipc:///tmp/sl_worker.socket"

  loggr::log_info(sprintf("Connecting to %s...", addr))
  connect.socket(socket, addr)
  on.exit(disconnect.socket(socket, addr), add=TRUE)
  loggr::log_info("Connected!")

  send_hello(socket, jobTypes)
  job_loop(socket)
}

if (!interactive()) {
  main()
}
