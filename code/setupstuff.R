#rm(list=ls())
setwd("E:/ExecutiveSearchYaml/code/")
config <- yaml::read_yaml("enhanced_hospitals.yaml")
source("pattern_based_scraper.R")
source("get_hosptial_info.R")
source("test_all_configured_hospitals.R")
FAC<-676




quick_test(FAC)
helper$analyze_hospital_structure(FAC, "HollandBloorview", "https://hollandbloorview.ca/about-us/about-holland-bloorview/governance-and-leadership/hospital-executive-leadership-team")

helper$test_hospital_config(FAC, Name, url, "table_rows")# - Test configuration (reads from YAML)\n")  

helper$generate_batch_config('file.csv')# - Generate config from CSV\n\n")
quick_test_batch(c(928,684,824,979,751,699)) #complete Div_classes failures


summarizeBaseLine <- Nov152025%>%
  select(FAC, executive_name, executive_title) %>%
  group_by(FAC) %>%
  summarise(n_exec = n(), .groups = "drop")


AllHospitals<-check_configuration_status()
summarizeBaseLine <-merge(summarizeBaseLine,AllHospitals,by="FAC")

summarizeBaseLine<-summarizeBaseLine %>%
  mutate(missing=Expected-n_exec)

rm(list=ls())
.rs.restartR()  # RStudio-specific restart command

# Wait for restart, then:
setwd("E:/ExecutiveSearchYaml/code/")
source("pattern_based_scraper.R")
source("get_hosptial_info.R") 
source("quick_test_single.R")
source("test_all_configured_hospitals.R")

FAC <- 978
quick_test(FAC)
