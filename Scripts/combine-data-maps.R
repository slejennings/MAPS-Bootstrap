## Combine all the MAPS runs together##
library(tidyverse)

maps_output_table <- list.files(path="outputs/",pattern=".rds",recursive=TRUE,full.names=TRUE) |>
  map(readRDS) |>
  list_rbind()

saveRDS(maps_output_table,file="MAPS_output_table.rds")
