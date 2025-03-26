## Prepare data for future splitting up
library(tidyverse)

## Set the working directory to the mounted PVC volume ("Data")
setwd("/data/MAPS")

# load boostrapped values
adulttrends_boot <- readRDS("inputs/adulttrends_boot.rds")

## Split the above into species-specific smaller files, creating directories for each species outputs
for(species in unique(adulttrends_boot$SPEC)) {
  onespecies <- adulttrends_boot |>
    filter(SPEC==species)
  
  sppoutdir <- file.path("outputs", species) 
  
  if (!dir.exists(sppoutdir)) dir.create(sppoutdir,recursive=TRUE)
  
  saveRDS(onespecies,file=(paste0("inputs/",species,".rds")))
}

## create a table with the info needed for each run, add an index number to match with the index of the pod job, and save it
MAPS_run_table <- adulttrends_boot |>
  group_by(SPEC,SPEC_STA,STA) |>
  summarize() |>
  ungroup() |>
  mutate(runINDEX=(row_number()-1))

saveRDS(MAPS_run_table,"MAPS_run_table.rds")
