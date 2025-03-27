## Combine all the runs together

a<-bind_rows(readRDS("ACFL_14420.rds"), readRDS("ACFL_14422.rds"), readRDS("ACFL_14423.rds"))