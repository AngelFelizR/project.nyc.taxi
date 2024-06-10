# run the container with the host cache mounted in the container
docker run -d --rm -ti \
    --name TaxiProject \
    -e PASSWORD=wxz \
    -e ROOT=true  \
    -e DISABLE_AUTH=true \
    -p 127.0.0.1:5555:8787 \
    -v /home/angel/R-Folder:/home/rstudio \
    -v /home/angel/R-Folder/r-lib-4.4:/usr/local/lib/R/site-library \
    -e "RENV_PATHS_CACHE=/home/rstudio/.cache/R/renv/cache/v5/R-4.3/x86_64-pc-linux-gnu" \
    -v /home/angel/R-Folder/cache_4.3:/home/rstudio/.cache/R/renv/cache/v5/R-4.3/x86_64-pc-linux-gnu \
    angelfelizr/project.nyc.taxi:0.0.0.9000

# We need to wait 1 second
sleep 1

# We need to open the page
chromium http://localhost:5555
