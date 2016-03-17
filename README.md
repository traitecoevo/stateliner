# stateline and R on a mac via docker

Example of using [stateline](https://github.com/NICTA/stateline).

## Setting up docker

The work-flow described below uses docker containers. A comprehensive guide can be found [here](http://docs.docker.com/mac/started/).  If you're using a mac or windows, all docker commands require that you have `docker-machine` set appropriately. For example, to build a virtual box with 3Gb memory and access to 3 cpus, run

```
docker-machine create --driver virtualbox --virtualbox-memory "3000" --virtualbox-cpu-count 3 default
```
(If you want to modify the number of CPUs on an existing machine run `VBoxManage modifyvm MACHINE_NAME --cpus NUM_CPUS`, substituting `MACHINE_NAME` and `NUM_CPUS` for suitable values.)

Then you can start the box

```
docker-machine start default
```

To use it you also need to set the environment in your terminal session

```
eval $(docker-machine env default)
```

## Building the containers

We first need to build the relevant docker containers.  We're going to build two containers

1. `traitecoevo/stateline`: base stateline implementation
2. `traitecoevo/stateliner`: the R interface

Both containers build off other base containers ([ubuntu](https://hub.docker.com/_/ubuntu/) and [r-base](https://hub.docker.com/_/r-base/), so the first thing that will happen when you try to build these is that the docker will pull down that base layer.

To build the `traitecoevo/stateline` container:

    git clone git@github.com:NICTA/stateline.git
    docker build -t traitecoevo/stateline stateline

To build the `traitecoevo/stateliner` container:

    docker build -t traitecoevo/stateliner docker

Instead of building the containers, you can also pull down the pre-built containers from dockerhub:

    docker pull traitecoevo/stateline
    docker pull traitecoevo/stateliner

## Running things

All the examples below run using linked containers. The local folder `config` contains files for configuring stateline `demo-config.json` and for R based workers. When running the material below we mount this folder onto the containers. This enables us to source local files, without requiring that we rebuild the container each time these change.

First, start the stateline server

    docker run --rm -it           \
      --name stateline_server     \
      -v ${PWD}/inst:/config      \
      -v ${PWD}/output:/stateline \
      traitecoevo/stateline         \
      /usr/local/bin/stateline -c /config/gaussian.json

Considerably easier will be to install the package and use the script:

    devtools::install_github("traitecoevo/callr", "traitecoevo/stateliner")
    stateliner::install_scripts("~/bin")

then

    stateline_server --config inst/gaussian.json

which will set up all the appropriate links for you

The options above include

* `--name stateline_server`: name of the container to refer to later
* `-v ${PWD}/inst:/config`: this is how we get the config file into stateline (see the `-c` option)
* `-v ${PWD}/output:/stateline`: this means that the output will end up in `/output`; however, the correct value on the right-hand side of the colon depends on the values set in the configuration (`stateline_server` will map this appropriately)

Then start a worker, using any of the following

    docker run --rm traitecoevo/stateliner --help

    docker run --rm                   \
      --link stateline_server         \
      -v ${PWD}/inst:/example         \
      traitecoevo/stateliner          \
      --address stateline_server:5555 \
      --config /example/gaussian.json \
      --source /example/gaussian.R    \
      --target gaussian

Here, the options after the container name are passed through to the stateliner client and are

* `--config`: then name of the configuration file
* `--source`: a source file to read (several `--source` options are allowed)
* `--target`: the name of the target function to run

As soon as this worker is created, the server will start feeding it tasks; these will turn up in the `output` directory, due to the link when establishing the *server*.

Note that there is no support for the workers detecting that the task is finished.  In theory I guess that the server should send a goodbye message but I don't see that.

If you want to interactively debug, you'll need to start the container in interactive mode:

    docker run --rm -it       \
      --link stateline_server \
      -v ${PWD}/inst:/example \
      -v ${PWD}:/src          \
      --entrypoint bash       \
      traitecoevo/stateliner

Note the `--entrypoint` argument here which overrides the default `stateliner` program running.
