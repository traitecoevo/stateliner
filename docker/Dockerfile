FROM r-base
MAINTAINER Daniel Falster <daniel.falster@mq.edu.au>

# Fetch stateline dependencies; this is tricky, and based off of the
# set up in the stateline Dockerfile (by Lachlan).  Probably worth
# pinning the stateline against a release, but I think that NICTA tend
# to be very conservative about what makes it onto github.  We don't
# actually need most of the dependencies (checked with ldd) so we'll
# purge them after the bits of stateline we need have built.
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
				cmake \
		git \
		nmap \
	&& git clone https://github.com/NICTA/stateline /usr/local/src/stateline \
	&& mkdir -p /stateline /tmp/build \
	&& BUILD_DIR=/tmp/build PREREQ_DIR=/usr/local /usr/local/src/stateline/tools/fetch-deps \
	&& ldconfig

# Build *just* the stateline client, and install that appropriately,
# then remove all the dependencies that we no longer need.
WORKDIR /tmp/build
RUN PREREQ_DIR=/usr/local cmake /usr/local/src/stateline -DCMAKE_BUILD_TYPE=Release -DLOCAL_INSTALL=OFF -DPREREQ_DIR=/usr/local \
	&& make stateline-client \
	&& install stateline-client /usr/local/bin \
	&& install libstatelineclient.so /usr/local/lib \
	&& rm -rf \
		/tmp/build/ \
		/usr/local/include/boost-1_59 \
		/usr/local/include/eigen3 \
		/usr/local/lib/libboost* \
		/usr/local/share/pkgconfig/eigen3.pc \
		/usr/local/src/gtest-1.7.0 \
		/usr/local/src/stateline
WORKDIR /

# TODO: Waiting on avoiding cache invalidation due to bitbucket being down, but:
#   * trim whitespace before cmake
#   * don't create /stateline

## Then, we need some packages for stateliner itself (including
## stateliner).  This *could* be done with dockertest but given the
## amount of mess above doing it separately is probably simpler.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		gfortran \
		libcurl4-openssl-dev \
		libssl-dev \
		libxml2-dev \
	&& install2.r --error \
		devtools \
		jsonlite \
	&& installGithub.r \
		armstrtw/rzmq \
		smbache/loggr \
		traitecoevo/callr

## Finally install the actual stateliner package (separate because
## this is going to need to be refreshed a bit).
RUN installGithub.r traitecoevo/stateliner \
	&& r -e 'stateliner::install_scripts("/usr/local/bin")'

ENTRYPOINT ["/usr/local/bin/stateliner"]
