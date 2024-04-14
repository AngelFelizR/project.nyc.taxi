FROM rocker/rstudio:4.3.3

# Disabling the authentication step
ENV USER="rstudio"
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize", "0", "--auth-none", "1"]


# Install jq to parse json files
RUN apt-get update && apt-get install -y --no-install-recommends \
# devtools & leaflet & DiagrammeR & fs
    make \

# devtools & leaflet & DiagrammeR & knitr
    pandoc \

# devtools & recipes & DiagrammeR & infer
    libicu-dev \

# devtools & leaflet & fusen
    libcurl4-openssl-dev \
    libpng-dev \

# devtools & arrow
    libssl-dev \

# devtools & DiagrammeR
    libxml2-dev \

# arrow
    cmake \

# leaflet
    libgdal-dev \
    gdal-bin \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev \

# devtools & fusen
    zlib1g-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    libtiff-dev \
    git \
    libgit2-dev \

# DiagrammeR
    libglpk-dev


# Creating directory
RUN mkdir /home/rstudio/project
RUN mkdir /home/rstudio/renv
RUN mkdir /home/rstudio/renv/cache

# Set the working directory
WORKDIR /home/rstudio/project

# Install renv from CRAN
RUN R -e "install.packages('renv')"

# Set the environment variable for the renv cache path
ENV RENV_PATHS_CACHE /home/rstudio/renv/cache

# Mount the host's renv cache to the container
VOLUME /home/rstudio/renv/cache

# Restore R packages using renv
RUN R -e "renv::init()"

EXPOSE 8787
