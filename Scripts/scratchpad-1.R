
task_id=2
run_species_station=run_species_station2


MAPS_run_info2 <- MAPS_run_table |>
  filter(runINDEX==3)

species2 <- MAPS_run_info2$SPEC
station2 <- MAPS_run_info2$STA
run_species_station2 <- MAPS_run_info2$SPEC_STA
run_species_data2 <- readRDS(paste0("inputs/",species2,".rds"))

run_species_station_data2 <- run_species_data2 |>
  filter(STA==station2)

# starting with SOSP (song sparrow)
# create a list where each station is a tibble within the list
SOSP_boot_list2 <- run_species_station_data2 %>% 
  group_split(SPEC_STA) %>% 
  setNames(unique(run_species_station_data2$SPEC_STA))

SOSP_boot_list3 <- run_species_data2 %>% 
  group_split(SPEC_STA) %>% 
  setNames(unique(run_species_data2$SPEC_STA))