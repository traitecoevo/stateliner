##' Install script into the path
##' @title Install script
##' @param path Location to install the script
##' @export
install_scripts <- function(path) {
  code <- c("#!/usr/bin/env Rscript", "library(methods)")
  file <- file.path(path, "stateliner")
  writeLines(c(code, "stateliner:::worker_main()"), file)
  Sys.chmod(file, "0755")

  file <- file.path(path, "stateline_server")
  writeLines(c(code, "stateliner:::server_main()"), file)
  Sys.chmod(file, "0755")
}

## TODO: This needs stripping down a little into a argument parser and
## general purpose runner.
worker_main <- function() {
  args <- worker_parse_args()
  target <- worker_main_get_target(args)
  stateliner(target, args$config, args$address, args$verbose)
}

worker_main_get_target <- function(args) {
  e <- new.env(parent=.GlobalEnv)
  load_source_files(args$source, packages=args$package, envir=e)
  get(args$target, e, mode="function", inherits=TRUE)
}

##' @importFrom docopt docopt
worker_parse_args <- function(args=commandArgs(TRUE)) {
  'Usage:
  stateliner [options] [--source FILE...] [--package PKG...]
Options:
  --config=FILE      Configuration filename [default: stateliner.json]
  --address=ADDRESS  Address of the delegator [default: localhost:5555]
  --package=PKG      Packages to load
  --source=FILE      R source files to read in
  --target=TARGET    Name of the negative log likelhood function
  --verbose          Verbose logging output?
' -> doc
  args <- docopt::docopt(doc, args)
  if (is.null(args$target)) {
    stop("target must be given")
  }
  args
}

server_parse_args <- function(args=commandArgs(TRUE)) {
  'Usage:
  stateline_server [options]
Options:
  --config=FILE  Configuration filename
  --output=PATH  Location to write output [default: output]
  --name=NAME    Name for the server container [default: stateline_server]
  --no-rm        Don\'t remove container on exit
' -> doc
  args <- docopt::docopt(doc, args)
  args$rm <- !args[["no-rm"]]
  args
}

server_main <- function() {
  args <- server_parse_args()
  stateline_server(args$config, args$output, args$name, args$rm)
}

load_source_files <- function(source_files, envir=.GlobalEnv,
                              packages=character(0), ...) {
  do_source <- function(file, envir, ...) {
    catch_source <- function(e) {
      stop(sprintf("while sourcing %s:\n%s", file, e$message),
           call.=FALSE)
    }
    tryCatch(sys.source(file, envir, ...),
             error=catch_source)
  }
  for (p in packages) {
    suppressMessages(library(p, character.only=TRUE, quietly=TRUE))
  }
  for (file in source_files) {
    do_source(file, envir, ...)
  }
  invisible(envir)
}
