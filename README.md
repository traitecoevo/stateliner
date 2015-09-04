# stateline and R on a mac via docker

On a mac, you may need to run `$(boot2docker shellinit)` to set up all your environment variables in each terminal window that you run docker in, as usual.

First, build the base stateline docker container (adapt the path as necessary).

    docker build -t stateline -f ../stateline/docker/stateline.dock ../stateline

Then build a container that contains a little more dependencies (for the Python worker and R worker examples)

    docker build -t stateliner .

## Running in a single container via exec

Running the main application is pretty straightforward;

    docker run --rm -it --name=mystateline stateline stateline -c /tmp/build/demo-config.json
    stateline -c /tmp/build/demo-config.json
    docker exec -it mystateline demo-worker

Running the python version is a bit more of a faff

    docker build -t stateliner-python-standalone -f python-standalone.dock .
    docker run --rm -it --name=mystateline stateliner-python-standalone stateline -c demo-config.json
    docker exec -it mystateline python /tmp/build/demo-worker.py

## Running the Proper Way with linked containers

There's a little more work needed to get the python containers working; we need to copy the configuration to where it is expected by the scripts, and to copy in a modified version of `demo-python.py` script that allows pointing the delegator at the address of the linked container (i.e., moving from `localhost:5555` to `stateline:5555`).

    docker build -t stateliner-python-server -f python-server.dock .
    docker build -t stateliner-python-worker -f python-worker.dock .

Once these are created, just fire up the server container and then a worker container that links appropriately:

    docker run --rm -it --name=mystateline stateliner-python-server
    docker run --rm -it --link mystateline:stateline stateliner-python-worker

# Old notes below here:

Run the container, mapping the local directory `r-demo-output` (which does not need to exist) to the appropriate place in the container, and launch the stateline server:

    docker run --name=stateline_server -v ${PWD}/r-demo-output:/tmp/build/r-demo-output --rm stateliner ./stateline --config=r-demo-config.json

Then, in another terminal window, run the worker, in the same container, using the demo-worker.R script (which was copied to the container when building `stateliner`)

    docker exec -it stateline_server Rscript demo-worker.R

Note that this second command does not need to be run in the same working directory, though it probably doesn't hurt.

Compare with python output:

    docker run --name=stateline_server -v ${PWD}/python-demo-output:/tmp/build/python-demo-output --rm stateliner ./stateline --config=python-demo-config.json
    docker exec -it stateline_server python demo-worker.py

So far as I can see this seems to work (plots generated with `viz.py` look similar at least).
