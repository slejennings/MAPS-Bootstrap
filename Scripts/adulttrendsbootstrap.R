#### Bootstrapping MAPS Adult Abundance Trend Models ####

# load and/or install packages
#install.packages("here", "tidyverse", "broom", "broom.mixed", "rsample", "glmmTMB")
library(here)
library(tidyverse)
library(parallel) # this should be installed as default
library(broom)
library(broom.mixed)
library(glmmTMB)
library(rsample)

###### SCOTT - YOU DO NOT NEED TO DO THESE STEPS. 
###### I'VE LEFT THEM HERE IN CASE WE NEED TO MAKE CHANGES. SKIP TO LINE 59 
# import files
adulttrends <- readRDS(here("Data", "adulttrendfinal.rds"))
colnames(adulttrends)
adult_50 <- readRDS(here("Data", "adult_50.rds"))
colnames(adult_50)

# get vector of species we want bootstrapped abundance models for
SPEClist <- adult_50 %>% pull(SPEC)

# make a data frame containing all species from SPEClist and the banding stations where they have data 
SPECSTA <- adulttrends %>% 
  filter(SPEC %in% SPEClist) %>%
  select(SPEC, STA) %>% 
  arrange(SPEC, STA) %>%
  distinct() %>%
  mutate(name = seq_along(.$SPEC)) # add name column to facilitate join in later step

#############################################################################
# generate bootstrapped data
# note: this may produce warning messages about assessment set containing zero rows. It is okay to proceed

set.seed(612)

adulttrends_boot <- adulttrends %>%
  filter(SPEC %in% SPEClist) %>%
  arrange(SPEC, STA, year) %>% 
  group_by(SPEC, STA) %>% 
  group_map(~ {rsample::bootstraps(., times=1000) %>% # create 1000 bootstrapped data sets for each species-station combination
      mutate(bootdat = map(splits, rsample::analysis)) %>% 
      select(-splits) %>%
      unnest(bootdat)}) %>%
  enframe() %>% # convert list to data frame
  unnest(value) %>% # unnest value (which is where the data is stored)
  left_join(SPECSTA, by="name") %>% # add the Species and Station names back to the data frame
  mutate(SPEC_STA = paste(SPEC, STA, sep="_"),
         id = str_replace(id, "Bootstrap", "BS"),
         unique_id = paste(SPEC, STA, id, sep="_")) %>% # create a unique ID
  group_by(unique_id) %>%
  mutate(numeric_id = cur_group_id()) %>% # assign a unique numeric id to each group
  ungroup() %>%
  select(SPEC, STA, SPEC_STA, id, unique_id, numeric_id, year:Effort) # reorganize data frame

saveRDS(adulttrends_boot, here("Data", "adulttrends_boot.rds"))


####### SCOTT - YOU SHOULD BE ABLE TO START HERE ##########
adulttrends_boot <- readRDS(here("Data", "adulttrends_boot.rds"))
# this takes a long time to load bc it's all the data for all the models (haha)
# I'm guessing we'll want to break it up. More on that below
print(adulttrends_boot, n =50)

length(unique(adulttrends_boot$numeric_id)) # there are 3940000 models
nrow(adulttrends_boot)/length(unique(adulttrends_boot$numeric_id)) # on average, each model has 15.6 data points

colnames(adulttrends_boot)
# Based on what we've discussed, I highly suspect we'll want to break up this huge data frame into smaller chunks
# there are two columns that can be used to parse out into just the data for each individual model
# they are numeric_id (which is all numeric) or unique_id 
# Both will achieved the same thing
# these will divide the data set into the ~ 16 points for each individual model
length(unique(adulttrends_boot$unique_id)) # 3940000 separate data frames

# alternatively, the column SPEC_STA could also be used
# this will break the data into the 1000 models associated with each bird spp at each banding station
length(unique(adulttrends_boot$SPEC_STA)) # 3940
# trials below indicate that chunks of this size can run in ~ 7 mins



# My original plan (before realizing the magnitude of this task) was to implement the models like this:

# write a function for the model that will cooperate with safely() and continue to run even if there are errors
glm_wrapped <- function(formula, ...){
  args <- list(formula = formula, ...)
  do.call(glmmTMB::glmmTMB, args)}

# run a "safe" loop for the models that will continue even if it encounters errors
adult_boot_models <- adulttrends_boot %>%
  group_by(unique_id) %>% # group by unique_id to get all rows for a model
  group_map(~ safely(glm_wrapped, otherwise="error")
            (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
              control = glmmTMBControl(parallel = 4))) 


# save the models
saveRDS(adult_boot_models, here("Models", "adult_boot_models.rds"))

# there are probably many other ways to do this
# and the code above will need to be modified based on the chunks we pick

####################################################################################
### test runs to look at run time across different sized chunks of data and using differing numbers of core

# test some models for time to inform how we parse the data (how small of chunks!)
SOSP_boot <- adulttrends_boot %>% filter(SPEC == "SOSP") # pull out one species (SOSP)

############## single model tests ###############
SOSP_boot_1 <- SOSP_boot %>% filter(STA == "11106", id == "BS0001") # get data for one model to experiment with

# run single model with varying number of cores for optimization process
# get time to completion
# try 1 to 8 cores
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 1))) # 0.437 elapsed
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 2))) # 0.402 elapsed
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 3))) # 0.401 elapsed
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 4))) # 0.399 elapsed
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 5))) # 0.400 elapsed
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 6))) # 0.371 elapsed
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 7))) # 0.370 elapsed
system.time(glmmTMB(Adult ~ year, data = SOSP_boot_1, offset = log(Effort), family=genpois, 
                control = glmmTMBControl(parallel = 8))) # 0.369 elapsed

############## 10 model tests ###############

# vector of ids to use for 10 models
id_10 <- c("BS0001", "BS0002", "BS0003", "BS0004", "BS0005", "BS0006",
           "BS0007", "BS0008", "BS0009", "BS0010")

# data for 10 models
SOSP_boot_10 <- SOSP_boot %>% 
  filter(STA == "11106") %>%
  filter(id %in% id_10)
        
# write a function for the model that will cooperate with safely() and continue to run even if there are errors
glm_wrapped <- function(formula, ...){
  args <- list(formula = formula, ...)
  do.call(glmmTMB::glmmTMB, args)}

# run batches of 10 models and get time to completion
# alter number of cores for optimization process to see how run time changes
# trying even values 2 through 8
system.time(SOSP_boot_10 %>%
              group_by(unique_id) %>% # group by unique_id to get all rows for a model
              group_map(~ safely(glm_wrapped, otherwise="error")
                        (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
                          control = glmmTMBControl(parallel = 2)))) # 3.927 elapsed

system.time(SOSP_boot_10 %>%
  group_by(unique_id) %>% # group by unique_id to get all rows for a model
  group_map(~ safely(glm_wrapped, otherwise="error")
            (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
              control = glmmTMBControl(parallel = 4)))) # 3.718 elapsed

system.time(SOSP_boot_10 %>%
              group_by(unique_id) %>% # group by unique_id to get all rows for a model
              group_map(~ safely(glm_wrapped, otherwise="error")
                        (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
                          control = glmmTMBControl(parallel = 6))))  # 3.703 elapsed

system.time(SOSP_boot_10 %>%
              group_by(unique_id) %>% # group by unique_id to get all rows for a model
              group_map(~ safely(glm_wrapped, otherwise="error")
                        (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
                          control = glmmTMBControl(parallel = 8)))) # 3.693 elapsed


############## 1000 model tests ###############

# get data for 1000 models
SOSP_11106 <- SOSP_boot %>% 
  filter(STA == "11106")

# run batches of 1000 models and get time to completion
# alter number of cores for optimization process to see how run time changes
# trying even values 2 through 8
system.time(SOSP_11106 %>%
              group_by(unique_id) %>% # group by unique_id to get all rows for a model
              group_map(~ safely(glm_wrapped, otherwise="error")
                        (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
                          control = glmmTMBControl(parallel = 2)))) # 410.687 elapsed

system.time(SOSP_11106 %>%
              group_by(unique_id) %>% # group by unique_id to get all rows for a model
              group_map(~ safely(glm_wrapped, otherwise="error")
                        (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
                          control = glmmTMBControl(parallel = 4)))) # 406.009 elapsed

system.time(SOSP_11106 %>%
              group_by(unique_id) %>% # group by unique_id to get all rows for a model
              group_map(~ safely(glm_wrapped, otherwise="error")
                        (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
                          control = glmmTMBControl(parallel = 6)))) # 401.501 elapsed

system.time(SOSP_11106 %>%
              group_by(unique_id) %>% # group by unique_id to get all rows for a model
              group_map(~ safely(glm_wrapped, otherwise="error")
                        (Adult ~ year, data = .x, offset = log(.x$Effort), family=genpois, 
                          control = glmmTMBControl(parallel = 8)))) # 400.679


