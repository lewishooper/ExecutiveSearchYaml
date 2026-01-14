#rm(list=ls())
project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}
config <- yaml::read_yaml("code/enhanced_hospitals.yaml")
source("code/pattern_based_scraper.R")
source("code/get_hosptial_info.R")
source("code/quick_test_single.R")
source("code/test_all_configured_hospitals.R")
source("code/hospital_configuration_helper.R")
FAC<-714



quick_test(FAC)

helper$analyze_hospital_structure(611, "NSHN", "https://www.nshn.care/senior-leadership-team")

helper$test_hospital_config(FAC, Name, url, "table_rows")# - Test configuration (reads from YAML)\n")  

helper$generate_batch_config('file.csv')# - Generate config from CSV\n\n")
quick_test_batch(c(655,648,646,611,965,962)) #complete Div_classes failures


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
##
## find Manual entry finder

# From your R console in project directory:
source("E:/ExecutiveSearchYaml/code/count_manual_entry_hospitals.R")
source("E:/ExecutiveSearchYaml/code/setup_environment.R")

source("E:/ExecutiveSearchYaml/code/screenshot_capture_function_v2.R")
result<-test_screenshot_capture()
source("E:/ExecutiveSearchYaml/code/api_extraction_function.R")
test_api_extraction()

source("E:/ExecutiveSearchYaml/code/test_full_pipeline.R")
source("E:/ExecutiveSearchYaml/code/step1_screenshot_capture.R")
source("E:/ExecutiveSearchYaml/code/step2_api_extraction.R")
source("E:/ExecutiveSearchYaml/code/step2_api_extraction.R")

list.files("E:/ExecutiveSearchYaml/output", pattern = "hospital_executives")
