FROM rocker/tidyverse:4.3.3

RUN apt-get update && apt-get install -y \
    libglpk-dev \
    libxml2-dev \
    libgdal-dev \
    gdal-bin \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev

RUN R -e "install.packages('pak')"

RUN R -e "pak::pkg_install('rstudio/renv@v1.0.5')"

RUN mkdir /home/proyect.nyc.taxi

COPY renv.lock /home/proyect.nyc.taxi/renv.lock

RUN R -e "setwd('/home/proyect.nyc.taxi');renv::init();renv::restore()"
