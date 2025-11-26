# Process most rece


#rm(list=ls())
#source("session_startup.R")
source("E:/ExecutiveSearchYaml/code/process_hospital_data.R")

result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/AllHospitalsNov232025.csv",
  config_file = "enhanced_hospitals.yaml",
  output_folder = "E:/ExecutiveSearchYaml/processed"
)



# Quick verification
employees <- result$employees
volunteers <- result$volunteers

# Check priority flags
table(employees$priority_flag)
table(volunteers$priority_flag)

# Check credentials extraction
sum(!is.na(employees$credentials))
sum(!is.na(volunteers$credentials))



# Generate validation sample
validation_sample <- validate_classification(
  bind_rows(result$employees, result$volunteers),
  sample_size = 100
)


### REviews and tests

PatternSummary<-test_summary_20251123_132650 %>%
  group_by(Pattern,Status) %>%
  select(Pattern,Status) %>%
  mutate(Size=n())%>% unique() %>%
  pivot_wider(names_from = "Status",values_from = "Size") %>%
  mutate(completionRate=(COMPLETE-sum(NO_RESULTS,EXTRA,INCOMPLETE,ERROR,na.rm=TRUE))/COMPLETE)
Extra<-test_summary_20251123_132650 %>%
  filter(Expected!=Found)

CredentialSplitting<-HospitalExecutives_Employees_2025_11_24 %>%
  select(fac_number,person_name,credentials) %>%
  mutate(SpacesINName=str_count(person_name,",")) %>%
  filter(SpacesINName>=1) %>%
  mutate(StartSub=str_locate(person_name,",")) %>%
  mutate(EndSub=str_length(person_name))%>%
  mutate(extraCredentials=str_sub(person_name,StartSub[1,1]),EndSub)
