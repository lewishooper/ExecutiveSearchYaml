# working filesetup
# basically just a spot to do Transformation and Manipulation of the code
#rm(list=ls())
library(tidyr)
library(tidyverse)
setwd("E:/ExecutiveSearchYaml/code/")
source("pattern_based_scraper.R")
source("test_all_configured_hospitals.R")
source("ExtractLeadership.R")
source("get_hosptial_info.R")


baseline_sample <- create_baseline_dataframe(sample_size = 10)

StartTime=Sys.time()
 baseline_full <- create_baseline_dataframe(sample_size = NULL, output_csv = TRUE)
EndTime=Sys.time()

Duration<-EndTime-StartTime
print(Duration)
findDuplicateNames<-baseline_full %>%
  select(FAC,hospital_name,executive_name,executive_title) %>%
  group_by(executive_name) %>%
  mutate(DupNames=n()) %>%
  filter(DupNames>=2) %>%
  filter(!is.na(executive_name))
FindPartnershipHosptials<-findDuplicateNames %>%
  ungroup() %>%
  select(hospital_name,FAC) %>%
  unique()
ManualEntry<-baseline_full %>%
  filter(str_detect(pattern_used,"manual")) %>%
  select(FAC,hospital_name) %>% unique()

ForScrnScraper<-as.data.frame(get_hospital_info(666))
ForScrnScraper<-ForScrnScraper[0,] # Create a blank dataframe
i<-3
for(i in 1:nrow(ManualEntry)){
  Temp1<-as.data.frame(get_hospital_info(ManualEntry[i,"FAC"]))
  ForScrnScraper<-bind_rows(ForScrnScraper,Temp1)
}
ForScrnScraper<-ForScrnScraper %>%
  select(url,FAC,name,type) %>%
  rename(facility_id=FAC,facility_name=name,facility_type=type)
saveRDS(ForScrnScraper,"E:/Public/ExecProjectSharedData/ManualEntryHospitals.rds")
write.csv(ForScrnScraper,"E:/Public/ExecProjectSharedData/ManualEntryHospitals.csv")
