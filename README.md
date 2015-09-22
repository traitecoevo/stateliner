# stateline and R on a mac via docker

Example of using [stateline](https://github.com/NICTA/stateline). 

On a mac, you'll need to have docker-machine running and have to set up all your environment variables in each terminal window that you run docker in, as usual. (e.g. `eval "$(docker-machine env default)"`)

To run stateline, we first need to build the relevant docker containers.  We're building our image
off the [lmccalman/stateline](https://hub.docker.com/r/lmccalman/stateline/) image, so the first thing that will happen when you try to build is that the docker will pull down that repo. 

Then build a container that contains a little more dependencies (for the Python worker and R worker examples)

    docker build -t stateliner .

## Running in a single, linked container

    docker run --rm -it --name=mystateline lmccalman/stateline /usr/local/bin/stateline -c /usr/local/src/stateline/src/bin/demo-config.json
    docker exec -it mystateline /usr/local/bin/demo-worker

Running the python version is a bit more of a faff

    docker build -t stateliner-python-standalone -f python-standalone.dock .
    docker run --rm -it --name=mystateline stateliner-python-standalone stateline -c demo-config.json
    docker exec -it mystateline python /usr/local/src/stateline/src/bin/demo-worker.py

## Running the Proper Way with linked containers

There's a little more work needed to get the python containers working; we need to copy the configuration to where it is expected by the scripts, and to copy in a modified version of `demo-python.py` script that allows pointing the delegator at the address of the linked container (i.e., moving from `localhost:5555` to `stateline:5555`).

    docker build -t stateliner-python-server -f python-server.dock .
    docker build -t stateliner-python-worker -f python-worker.dock .

Once these are created, just fire up the server container and then a worker container that links appropriately:

    docker run --rm -it --name=mystateline stateliner-python-server
    docker run --rm -it --link mystateline:stateline stateliner-python-worker

## Running the R bits, with linked containers

    docker build -t stateliner-r-server -f python-server.dock .
    docker build -t stateliner-r-worker -f r-worker.dock .

    docker run --rm -it --name=mystateline stateliner-python-server
    docker run --rm -it --link mystateline:stateline stateliner-r-worker -n stateline:5555
