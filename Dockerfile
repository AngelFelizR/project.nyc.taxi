FROM rocker/rstudio:4.3.3

RUN R -e "install.packages('renv')"

RUN mkdir /home/proyect.nyc.taxi

COPY renv.lock /home/proyect.nyc.taxi/renv.lock

RUN R -e "setwd('/home/proyect.nyc.taxi');renv::init();renv::restore()"
