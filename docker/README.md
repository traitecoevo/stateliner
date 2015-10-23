# stateline + R: the container

The dockerfile here builds a container for creating R stateline clients.  Because the focus is creating and installing R packages, it makes sense to start from the `r-base` image, rather than from the stateline image.  The container gets all the relevant prerequisites for using R and stateline together and can be used to test simple likelihood functions, or as a base container for use with [`dockertest`](https://github.com/traitecoevo/dockertest).

This container does not include a full stateline installation.  In particular, it does not include the server or expose any ports, so you'll want to run a stateline server locally or via the container `lmccalman/stateline`.

To use this with dockertest, add the line:

```yaml
image: traitecoevo/stateliner
```

to your `dockertest.yml` file which will set up the dockerfile with

```
FROM traitecoevo/stateliner
```

The `traitecoevo/stateliner` container comes in currently at 1.543GB, compared with 1GB for the r-base image.  Not really sure what's causing that.
