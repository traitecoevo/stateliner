##' Start a stateline server in a docker container
##' @title Start a stateline server
##' @param config Configuration file
##' @param output Location to store output on the host computer
##' @param name Name of the server container
##' @param rm Delete the container on exit (default is to delete)
##' @export
stateline_server <- function(config, output="output", name="stateline_server",
                             rm=TRUE) {
  config <- normalizePath(config)

  ## Output on the host:
  if (!file.exists(output)) {
    dir.create(output, FALSE, TRUE)
  }
  output <- normalizePath(output)

  ## Output in the container:
  output_sl <- jsonlite::fromJSON(readLines(config))[["outputPath"]]
  if (!grepl("^/", output_sl)) { # relative path
    output_sl <- sub("/$", "",
                     file.path("/stateline", sub("^.?/?", "", output_sl)))
  }

  message("Starting server in container: ", name)
  ## TODO: here we can actually print the worker command almost entirely.

  ## TODO: Do print the interesting bits of information here about
  ## where the output will be found.

  system2(callr::Sys_which("docker"),
          c("run",
            "--name", name,
            if (rm) "--rm",
            c("-v", paste0(dirname(config), ":/config")),
            c("-v", paste0(output, ":", output_sl)),
            "traitecoevo/stateline",
            "/usr/local/bin/stateline",
            "-c", file.path("/config", basename(config))))
}
