#!/bin/env bash

# Move to /data/MAPS for following commands
cd /data/MAPS

# Call the pre-process program
Rscript maps-run.R $JOB_COMPLETION_INDEX
