# stateline and R on a mac via docker

Example of using [stateline](https://github.com/NICTA/stateline).

If you're using a mac or windows, all docker commands require that you have `docker-machine` (or `boot2docker`) set appropriately.  A comprehensive guide can be found [here](http://docs.docker.com/mac/started/), but usually something like

```
docker-machine start
eval $(docker-machine env default)
```

will suffice.

## Building the containers

We first need to build the relevant docker containers.  We're building a container
off the [lmccalman/stateline](https://hub.docker.com/r/lmccalman/stateline/) image from dockerhub, so the first thing that will happen when you try to build the stateliner image is that the docker will pull down that repo.

Then build a container that contains a little more dependencies (for the R worker example)

    docker build -t traitecoevo/stateliner docker

## Running things

Instead of building the conatiner you can also pull it (and the stateline server container) from dockerhub:

    docker pull lmccalman/stateline
    docker pull traitecoevo/stateliner

All the examples below run using linked containers. The local folder `config` contains files for configuring stateline `demo-config.json` and for R based workers. When running the material below we mount this folder onto the containers. This enables us to source local files, without requiring that we rebuild the container each time these change.

First, start the stateline server

    docker run --rm -it           \
      --name stateline_server     \
      -v $(PWD)/inst:/config      \
      -v $(PWD)/output:/stateline \
      lmccalman/stateline         \
      /usr/local/bin/stateline -c /config/gaussian.json

Considerably easier will be to install the package and use the script:

    devtools::install_github("traitecoevo/callr", "traitecoevo/stateliner")
    stateliner::install_scripts("~/bin")

then

    stateline_server --config inst/gaussian.json

which will set up all the appropriate links for you

The options above include

* `--name stateline_server`: name of the container to refer to later
* `-v $(PWD)/inst:/config`: this is how we get the config file into stateline (see the `-c` option)
* `-v $(PWD)/output:/stateline`: this means that the output will end up in `/output`; however, the correct value on the rhs of the colon depends on the values set in the configuration (`stateline_server` will map this appropriately)

Then start a worker, using any of the following

    docker run --rm traitecoevo/stateliner --help

    docker run --rm                   \
      --link stateline_server         \
      -v ${PWD}/inst:/example         \
      traitecoevo/stateliner stateliner \
      --address=stateline_server:5555 \
      --config /example/gaussian.json \
      --source=/example/gaussian.R    \
      --target=gaussian

Here, the options after the container name are passed through to the stateliner client and are

* `--config`: then name of the configuration file
* `--source`: a source file to read (serveral `--source` options are allowed)
* `--target`: the name of the target function to run

As soon as this worker is created, the server will start feeding it tasks; these will turn up in the `output` directory, due to the link when establishing the *server*.

Note that there is no support for the workers detecting that the task is finished.  In theory I guess that the server should send a goodbye message but I don't see that.
