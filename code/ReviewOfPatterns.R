# Review of Patterns
#rm(list=ls())
source<-"E:/ExecutiveSearchYaml/code"
library(tidyr)
library(tidyverse)

setwd("E:/ExecutiveSearchYaml/code")

source("test_all_configured_hospitals.R")
AllHospitals<-check_configuration_status()
saveRDS(AllHospitals,"pattern_summary.rds")
OKpatterns<-AllHospitals %>%
  filter(tolower(Status)=='ok') %>%
  filter(!Has_Missing)
saveRDS(OKpatterns,"GoodHospitals.rds")

#
pattern_summary<-readRDS("E:/ExecutiveSearchYaml/code/pattern_summary.rds")
##### 
#Consolidate with YAML files
####

PatternsInSummary<-pattern_summary %>%
  select(Pattern) %>%
  group_by(Pattern) %>%
  mutate(Count=n()) %>%
  unique()
ConsolidatedPatterns<-pattern_summary %>%
  select(-c("Hospital","FAC")) %>%
  group_by(Pattern) %>%
  mutate(NumPatterns=n()) %>%
  relocate(NumPatterns) %>%
  arrange(desc("NumPatterns")) %>%
  unique()
library(dplyr)

# Create the consolidated dataframe
consolidated_df <- pattern_summary %>%
  mutate(FACName=paste0(FAC,"->",Hospital))%>%
  select(-c(FAC,Hospital)) %>%
  group_by(Pattern) %>%
  mutate(NumByPattern=n())%>%
  summarise(across(everything(), ~ paste(unique(na.omit(.)), collapse = " : "))) %>%
  ungroup() %>%
  mutate(NumByPattern=as.integer(NumByPattern))%>%
  relocate(NumByPattern)

# View the result
print(consolidated_df, n = 14)  # Show all 14 rows
