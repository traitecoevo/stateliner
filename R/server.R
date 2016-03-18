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

  output <- normalizePath(output)

  ## Output in the container:
  output_subdir <- jsonlite::fromJSON(readLines(config))[["outputPath"]]
  ## if relative path, remove ./
  output_subdir <- sub("^[./]*", "", output_subdir)

  output_sl <- file.path("/stateline", output_subdir)
  output_local <- file.path(output, output_subdir)

  ## Ensure directory exists on the host
  if (!file.exists(output_local)) {
    dir.create(output_local, FALSE, TRUE)
  }

  message("Starting server in container: ", name)
  ## TODO: here we can actually print the worker command almost entirely.

  message("Output saved in directory: ", output_local)

  system2(c(callr::Sys_which("docker"), "run",
            "--name", name,
            if (rm) "--rm",
            c("-v", paste0(dirname(config), ":/config")),
            c("-v", paste0(output_local, ":", output_sl)),
            "traitecoevo/stateline",
            "/usr/local/bin/stateline",
            "-c", file.path("/config", basename(config))))
}
