# As before, take the overall stateline container and add a bunch of
# stuff to it.
FROM stateline
# Python dependencies for the example:
RUN apt-get update && apt-get install -y \
    python \
    python-dev \
    python-matplotlib \
    python-numpy \
    python-pip && \
  pip install \
    pyzmq \
    triangle_plot

# R dependencies for building our own example:
RUN apt-get update && apt-get install -y \
  r-base \
  r-base-dev \
  r-recommended \
  vim-tiny

RUN wget https://github.com/armstrtw/rzmq/archive/master.zip && \
  unzip master.zip && R CMD INSTALL rzmq-master && rm -fr master.zip rzmq-master

RUN wget https://github.com/smbache/loggr/archive/master.zip && \
  unzip master.zip && R CMD INSTALL loggr-master && rm -fr master.zip loggr-master

RUN Rscript -e 'install.packages("jsonlite", repos="http://cran.rstudio.com")'

# # Update error in demo config, and add R config
# COPY python-demo-config.json ./
# COPY r-demo-config.json demo-worker.R ./
