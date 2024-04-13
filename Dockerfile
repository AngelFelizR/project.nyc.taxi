FROM rocker/rstudio:4.3.3

RUN apt-get update && apt-get install -y \
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


# Set the working directory
WORKDIR /project

# Install renv from CRAN
RUN R -e "install.packages('renv')"

# Set the environment variable for the renv cache path
ENV RENV_PATHS_CACHE /renv/cache

# Mount the host's renv cache to the container
VOLUME /renv/cache

# Restore R packages using renv
RUN R -e "renv::init()"


