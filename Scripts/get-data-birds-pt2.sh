#!/bin/env bash

cd /data/MAPS

# Get full data file
# wget "https://gitlab.nrp-nautilus.io/sappleby/maps/-/raw/main/adulttrends_boot.rds?inline=false" -O /inputs/adulttrends_boot.rds
curl -o maps-run.sh "https://raw.githubusercontent.com/slejennings/MAPS-Bootstrap/refs/heads/main/Scripts/maps-run.sh"

# Get the data prep file (this should both divide the above data file into species-level files, and create a directory structure for the files to go into)
# wget "https://raw.githubusercontent.com/slejennings/MAPS-Bootstrap/refs/heads/main/Scripts/bird_data_prep.R" -O bird_data_prep.R
curl -o maps-run.R "https://raw.githubusercontent.com/slejennings/MAPS-Bootstrap/refs/heads/main/Scripts/maps-run.R"
