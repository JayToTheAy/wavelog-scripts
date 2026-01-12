#!/bin/sh
sudo docker compose stop
# sudo docker compose rm -f  # should be unnecessary, re-enable if updates are not being applied
sudo docker compose pull   
sudo docker compose up -d
