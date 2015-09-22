# stateline and R on a mac via docker

Example of using [stateline](https://github.com/NICTA/stateline).

You'll need to have docker-machine running and have to set up all your environment variables in each terminal window that you run docker in, as usual. (e.g. on a mac, run `eval "$(docker-machine env default)"`)

We first need to build the relevant docker containers.  We're building a container
off the [lmccalman/stateline](https://hub.docker.com/r/lmccalman/stateline/) image from dockerhub, so the first thing that will happen when you try to build the stateliner image is that the docker will pull down that repo.

Then build a container that contains a little more dependencies (for the Python worker and R worker examples)

    docker build -t traitecoevo/stateliner .

Instead of building the conatiner you can also pull it from dockerhub 

    docker pull lmccalman/stateline 
    docker pull traitecoevo/stateliner 

All the examples below run using linked containers. The local folder `config` contains files for configuring stateline `demo-config.json` and for R and python based workers. When running the material below we mount this folder onto the containers. This enables us to source local files, without requiring that we rebuild the container each time these change.

First, start server

    docker run --rm --name mystateline -it -v $(pwd)/config:/config lmccalman/stateline /usr/local/bin/stateline -c /config/demo-config.json

Then start a worker, using any of the following

inbuilt worker written in cpp

    docker run --rm -it --link mystateline:stateline -v $(pwd)/config:/config lmccalman/stateline /usr/local/bin/demo-worker -a stateline:5555

python worker

    docker run --rm -it --link mystateline:stateline -v $(pwd)/config:/config traitecoevo/stateliner python /config/demo-worker.py
(note needs stateliner image because lmccalman/stateline lacks zeromq)

R worker

    docker run --rm -it --link mystateline:stateline  -v $(pwd)/config:/config traitecoevo/stateliner /config/demo-worker.R -n stateline:5555 -c /config/demo-config.json

These all seem to work; only problem is that we need to locate output files. Previously we mounted `-v $(pwd)/output/stateline:/tmp/build/output/stateline` but this no longer works because the tmp direcoty no longer exists. Once we locate the output files in the container we can do something similar. 
