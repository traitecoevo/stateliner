#!/usr/bin/env Rscript
library(rzmq)
library(loggr)
library(jsonlite)
library(docopt)

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

send_hello <- function(socket, nJobTypes) {
  loggr::log_info("Sending HELLO message...")
  msg <- c("", HELLO, sprintf("0:%s", nJobTypes))
  send.multipart.string(socket, msg)
}

random_string <- function() {
  paste(sample(letters, 10), collapse="")
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
  args <- parse_args()
  addr <- sprintf("ipc:///tmp/sl_worker%s.socket", random_string())

  client_args <- c("-n", args$delegator_address, "-w", addr)
  system2("./stateline-client", client_args, wait=FALSE)

  config <- jsonlite::fromJSON(readLines(args$config))
  nJobTypes <- config$nJobTypes

  ctx <- rzmq::init.context()
  socket <- rzmq::init.socket(ctx, "ZMQ_DEALER")

  loggr::log_info(sprintf("Connecting to %s...", addr))
  connect.socket(socket, addr)
  on.exit(disconnect.socket(socket, addr), add=TRUE)
  loggr::log_info("Connected!")

  send_hello(socket, nJobTypes)
  job_loop(socket)
}

parse_args <- function(args=commandArgs(TRUE)) {
  'Usage:
  demo-worker.R [-c CONFIG] [-n ADDRESS]
  Options:
  -c CONFIG    Filename for the json configuration [default: demo-config.json]
  -n ADDRESS   Address of the delegator [default: localhost:5555]
' -> doc
  args <- docopt(doc, args)
  list(config=args$c, delegator_address=args$n)
}

if (!interactive()) {
  main()
}
