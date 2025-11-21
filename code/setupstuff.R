#rm(list=ls())
setwd("E:/ExecutiveSearchYaml/code/")
config <- yaml::read_yaml("enhanced_hospitals.yaml")
source("pattern_based_scraper.R")
source("get_hosptial_info.R")
source("quick_test_single.R")
source("test_all_configured_hospitals.R")
source("hospital_configuration_helper.R")
FAC<-599

quick_test(FAC)
helper$analyze_hospital_structure(599, "Arnprior", "https://www.arnpriorregionalhealth.ca/about-us/")

helper$test_hospital_config(FAC, Name, url, "table_rows")# - Test configuration (reads from YAML)\n")  

helper$generate_batch_config('file.csv')# - Generate config from CSV\n\n")
quick_test_batch(c(
  
  
)) #complete Div_classes failures


### section on running full database extraction and comparing with baseline database
HospitalSummary<-check_configuration_status()
saveRDS(HospitalSummary,"E:/ExecutiveSearchYaml/output/HospitalSummaryNov162025.rds")
test_all_configured_hospitals()
rm(Nov172025BaseLine)
#8:56Am
#9:10
Nov172025<-all_hospitals_20251117_090937


summarizeBaseLine <- Nov172025%>%
  select(FAC, executive_name, executive_title,robots_status) %>%
  group_by(FAC) %>%
  summarise(n_exec = n(), .groups = "drop")


AllHospitals<-check_configuration_status()
summarizeBaseLine <-merge(summarizeBaseLine,AllHospitals,by="FAC")

summarizeBaseLine<-summarizeBaseLine %>%
  mutate(missing=Expected-n_exec)


CheckRobot<-Nov172025 %>%
  select(robots_status) %>%
  group_by(robots_status)%>%
  mutate(Numrobots=n())%>%
  unique()
FindBadTitle<- Nov172025 %>%
  mutate(nameLength=str_length(executive_name)) %>%
  mutate(titleLength=str_length(executive_title)) %>%
  filter(titleLength>=1000)
