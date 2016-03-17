# Stateliner: an R interface to the stateline MCMC engine for R via docker

## Introduction

[Stateline](https://github.com/NICTA/stateline) is a framework for distributed Markov Chain Monte Carlo (MCMC) sampling written in C++.  Stateline is designed specifically for difficult inference problems in computational science; e.g. it allows for target distributions that are highly non-Gaussian, for conditioning on data that is non-linearly related to the model parameters, or where the models are expensive ‘black box’ functions, such as the solutions to numerical simulations. Some notable features of stateline include:

- random walk Metropolis-Hastings algorithm with parallel tempering to improve chain mixing
- an adaptive proposal distribution, to speed up convergence
- allowing the user to factorise their likelihoods (eg. over sensors or data),
- built for deploying computation on a cluster, e.g. Amazon Web Services
- allowing users to execute likelihood calculations in their preferred language (eg. C++, R, python, ...).

For more about stateline and the techniques involved, see the [stateline package.](https://github.com/NICTA/stateline).

## Why stateliner

The `stateliner` package is designed to make it easy for those using R code to interface with and use stateline. While stateline potentially allows for likelihoods to be written in any language, there is a certain amount of infrastructure needed to communicate between the works (your model in R) and stateline. The `stateliner` package provides that infrastructure, so that all you need to do is write R code.

The work-flow described below uses docker containers. Docker containers are virtual machines that can be mounted onto your local machine, or a remote cluster environment. A comprehensive guide to docker can be found [here](http://docs.docker.com/mac/started/). There are two reasons we use docker here:

1. It saves installing the stateline engine and other required components on your local machine. (Instead these are all accessed via the docker containers).
2. It enables a seamless transition to running your compute in a cloud environment such as Amazon Web services (because the docker container can be mounted onto the remote machine).

Please note that `stateliner` is ONLY set up to work with docker containers. (We do not support local installations.)


## Setting up docker

If you're using a mac or windows, all docker commands require that you have `docker-machine` set appropriately. (By contrast, docker is available by default on linux). First [install docker](http://docs.docker.com/mac/started/). For example, to build a virtual box with 3Gb memory and access to 3 cpus, run (in a terminal session)

```
docker-machine create --driver virtualbox --virtualbox-memory "3000" --virtualbox-cpu-count 3 default
```
(If you want to modify the number of CPUs on an existing machine run `VBoxManage modifyvm MACHINE_NAME --cpus NUM_CPUS`, substituting `MACHINE_NAME` and `NUM_CPUS` for suitable values.)

Then you can start the box

```
docker-machine start default
```

And to use it you also need to set the environment in your terminal session

```
eval $(docker-machine env default)
```

## Building or fetching the containers

Once docker is installed, you can build the necessary containers, or pull down the pre-built containers from dockerhub. We're going to require two containers

1. `traitecoevo/stateline`: contains the stateline server and engine
2. `traitecoevo/stateliner`: an R interface to the stateline server

When we run stateline (below) we deploy both containers in a linked fashion. The `traitecoevo/stateline` container has a full installation of stateline, and is built directly from the [stateline](https://github.com/NICTA/stateline) repo. For the `traitecoevo/stateliner` container, the  focus is creating and installing R packages; it therefore makes sense to start from the `r-base` image, rather than from the stateline image.  The container gets all the relevant prerequisites for using R and stateline together and can be used to test simple likelihood functions, or as a base container in your own projects (eg. via  [`dockertest`](https://github.com/traitecoevo/dockertest)). The container contains the  stateline client, but does not contain a full stateline installation.

To pull down the pre-built containers:

    docker pull traitecoevo/stateline
    docker pull traitecoevo/stateliner

To build the `traitecoevo/stateline` container:

    git clone git@github.com:NICTA/stateline.git
    docker build -t traitecoevo/stateline stateline

To build the `traitecoevo/stateliner` container:

    docker build -t traitecoevo/stateliner docker

The dockerfile for building this container is in [docker/Dockerfile](docker/Dockerfile). Both containers build off other base containers ([ubuntu](https://hub.docker.com/_/ubuntu/) and [r-base](https://hub.docker.com/_/r-base/), so the first thing that will happen when you try to build these is that the docker will pull down that base layer.

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

## Analysis

The stateliner package also includes routines for doing basic analysis of stateline output.
For example, the code below should work for the output from the above example

    library(stateliner)
    path <- "output"

Loads each chain in a list object

    raw_samples <- load_chains(path)
    sapply(raw_samples, nrow)

We can remove an custom-defined warmup period

    warmup <- 200
    samples_minus_burnin <- remove_warmup(raw_samples, warmup)

Or examine trace_plots to check

    trace_plot(raw_samples, scales = "fixed")

And calculate summary statistics of parameter posteriors

    posterior_summary <- summarise_samples(samples_minus_burnin)

Here is a density plot of the parameter posteriors

    density_plot(remove_warmup(raw_samples, warmup))
