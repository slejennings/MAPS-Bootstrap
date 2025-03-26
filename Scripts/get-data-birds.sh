#!/bin/env bash

mkdir -p /data/MAPS
mkdir -p /data/MAPS/test/inputs
mkdir -p /data/MAPS/test/outputs
mkdir -p /data/MAPS/outputs
mkdir -p /data/MAPS/inputs

cd /data/MAPS

# Get full data file
wget "https://drive.usercontent.google.com/downloa?id=1kuN0S9sZGzjQOtSCdUR_dfnhpLszIWlB&export=download&authuser=0&confirm=yes" -O adulttrends_boot.rds

# Get the data prep file (this should both divide the above data file into species-level files, and create a directory structure for the files to go into)
wget "https://gitlab.nrp-nautilus.io/sappleby/k8stest/-/raw/main/hello_job_R/bird_data_prep.R" -O bird_data_prep.R
