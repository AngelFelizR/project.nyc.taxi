# run the container with the host cache mounted in the container
docker run -d --rm -ti \
    --name TaxiProject \
    -e DISABLE_AUTH=true \
    -p 127.0.0.1:5555:8787 \
    -v /home/angelfeliz/Documents/r-projects:/home/rstudio \
    -v /home/angelfeliz/Documents/r-projects/r-lib-4.4:/usr/local/lib/R/site-library \
    -e "RENV_PATHS_CACHE=/home/rstudio/.cache/R/renv/library/project.nyc.taxi-dd1eca8a/linux-ubuntu-jammy/R-4.4/x86_64-pc-linux-gnu" \
    -v /home/angelfeliz/Documents/r-projects/cache_4.4:/home/rstudio/.cache/R/renv/library/project.nyc.taxi-dd1eca8a/linux-ubuntu-jammy/R-4.4/x86_64-pc-linux-gnu \
    angelfelizr/project.nyc.taxi:0.0.0.9000

# We need to wait 1 second
sleep 1

# We need to open the page
chromium http://localhost:5555
