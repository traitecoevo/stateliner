# As before, take the overall stateline container and add a bunch of
# stuff to it.
FROM lmccalman/stateline
MAINTAINER Daniel Falster <daniel.falster@mq.edu.au>

# Base R installation, along with packages we need to bootstrap other
# packages.  This largely builds on the sort of thing done in the
# basic docker r-base image and dockertest, but we can't use that
# because of the diamond problem.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    littler \
    r-base \
    r-base-dev \
    r-recommended \
    vim-tiny \
    wget \
  && /usr/share/doc/littler/examples/install.r \
    docopt \
    devtools

# R packages used by *this* project
RUN /usr/share/doc/littler/examples/install.r jsonlite \
  && /usr/share/doc/littler/examples/installGithub.r \
    armstrtw/rzmq \
    smbache/loggr \
    traitecoevo/callr

# The actual stateliner package
RUN /usr/share/doc/littler/examples/installGithub.r traitecoevo/stateliner \
  && r -e 'stateliner::install_scripts("/usr/local/bin")'

ENTRYPOINT ['/usr/local/bin/stateliner']
