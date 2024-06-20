FROM rocker/rstudio:4.4.1

# Install jq to parse json files
RUN apt-get update && apt-get install -y --no-install-recommends \

# devtools & leaflet & DiagrammeR & fs
    make \

# devtools & leaflet & DiagrammeR & knitr
    pandoc \

# devtools & recipes & DiagrammeR & infer
    libicu-dev \

# devtools, leaflet, fusen & magick
    libcurl4-openssl-dev \
    libpng-dev \

# devtools, arrow & magick
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
    libglpk-dev \

# magick
    imagemagick \
    libmagick++-dev \
    gsfonts

RUN R -e "install.packages('pak');pak::pkg_install('rstudio/renv@v1.0.7')"
