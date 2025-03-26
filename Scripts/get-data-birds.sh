#!/bin/env bash

mkdir -p /data/MAPS
mkdir -p /data/MAPS/test/inputs
mkdir -p /data/MAPS/test/outputs
mkdir -p /data/MAPS/outputs
mkdir -p /data/MAPS/inputs

cd /data/MAPS

# Get full data file
# wget "https://gitlab.nrp-nautilus.io/sappleby/maps/-/raw/main/adulttrends_boot.rds?inline=false" -O /inputs/adulttrends_boot.rds
curl -o /inputs/adulttrends_boot.rds "https://gitlab.nrp-nautilus.io/sappleby/maps/-/raw/main/adulttrends_boot.rds?inline=false"

# Get the data prep file (this should both divide the above data file into species-level files, and create a directory structure for the files to go into)
# wget "https://raw.githubusercontent.com/slejennings/MAPS-Bootstrap/refs/heads/main/Scripts/bird_data_prep.R" -O bird_data_prep.R
curl -o bird_data_prep.R "https://raw.githubusercontent.com/slejennings/MAPS-Bootstrap/refs/heads/main/Scripts/bird_data_prep.R"
