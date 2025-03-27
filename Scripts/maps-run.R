## Run the MAPS models ##
library(tidyverse)
library(glmmTMB)

### Get Info from SLURM about this run ###
task_id <- as.numeric(Sys.getenv("JOB_COMPLETION_INDEX"))

## Load the species / site index table
MAPS_run_table <- readRDS("MAPS_run_table.rds")

## Get the info for this run based on the index
MAPS_run_info <- MAPS_run_table |>
  filter(runINDEX==task_id)

run_species <- MAPS_run_info$SPEC
run_station <- MAPS_run_info$STA
run_species_station <- MAPS_run_info$SPEC_STA

## Load the data for the species being run
run_species_data <- readRDS(paste0("inputs/",species,".rds"))

run_species_station_data <- run_species_data |>
  filter(STA==station)

# define safely wrapped model function
glm_wrapped <- function(formula, ...){
  args <- list(formula = formula, ...)
  do.call(glmmTMB::glmmTMB, args)}

# run models for each 1000 models (aka each species/station combination) summarize and assign a name to each object
run_species_station_out <- run_species_station_data |>## Take the data from one station/species combination
  group_by(unique_id) |> # group by unique_id to get all rows for a model
  nest() |> # make a nested data frame with each unique_id 
  mutate(GPmod = map(data, ~ safely(glm_wrapped, otherwise="error") # put safely wrapped glmmTMB model into column
                     (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois)),
         Err = map(GPmod, "error"), # put model error messages into a column
         Res = map(GPmod, "result")) |> # put model results into a column
  filter(Err == "NULL") |> # filter to keep only models with no error messages
  mutate(tidyGP = map(Res, broom.mixed::tidy, conf.int=T, conf.level=0.95)) %>% # tidy model results for models with no errors
  unnest(tidyGP) |> # unnest the tidied model output
  filter(term == "year") |> # drop estimates for intercept and keep only those for year
  filter(!is.na(std.error)) |> # drop models that did not converge. These models will not have estimates for SE
  dplyr::select(-data, -GPmod, -Err, -Res, -effect, -component, -term) |>
  ungroup() |> # remove prior grouping as we want to summarize across all unique_ids
  summarize(mean_tstat = mean(statistic, na.rm=T), # get summary statistics using the values from the 1000 models
            conf.low_tstat = quantile(statistic, 0.025, na.rm=T),
            conf.high_tstat = quantile(statistic, 0.975, na.rm=T),
            mean_slope = mean(estimate, na.rm=T), 
            conf.low_slope = quantile(estimate, 0.025, na.rm=T),
            conf.high_slope = quantile(estimate, 0.975, na.rm=T),
            mean_SE = mean(std.error, na.rm=T), 
            conf.low_SE = quantile(std.error, 0.025, na.rm=T),
            conf.high_SE = quantile(std.error, 0.975, na.rm=T)) |>
  mutate(SPEC_STA=run_species_station) |>
  mutate(k8sindex=task_id)

saveRDS(run_species_station_out, paste0("outputs/",run_species,"/",run_species_station,".rds"))

