# run the container with the host cache mounted in the container
docker compose up -d

# We need to wait 1 second
sleep 1

# We need to open the page
chromium http://localhost:5555
