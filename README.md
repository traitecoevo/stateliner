# stateline and R on a mac via docker

First, build the stateline docker container.

Then build a container that contains a little more:

    docker build -t stateliner .

Run the container, mapping the local directory `r-demo-output` (which does not need to exist) to the appropriate place in the container, and launch the stateline server:

    docker run --name=stateline_server -v ${PWD}/r-demo-output:/tmp/build/r-demo-output --rm stateliner ./stateline --config=r-demo-config.json

Then, in another terminal window, run the worker, in the same container, using the demo-worker.R script (which was copied to the container when building `stateliner`)

    docker exec -it stateline_server Rscript demo-worker.R

Note that this second command does not need to be run in the same working directory, though it probably doesn't hurt.

Compare with python output:

    docker run --name=stateline_server -v ${PWD}/python-demo-output:/tmp/build/python-demo-output --rm stateliner ./stateline --config=python-demo-config.json
    docker exec -it stateline_server python demo-worker.py

So far as I can see this seems to work (plots generated with `viz.py` look similar at least).
