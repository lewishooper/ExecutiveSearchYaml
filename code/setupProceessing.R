# Process most recent output


#rm(list=ls())
#source("session_startup.R")
source("E:/ExecutiveSearchYaml/code/process_hospital_data.R")

result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/AllHospitalsNov232025.csv",
  config_file = "enhanced_hospitals.yaml",
  output_folder = "E:/ExecutiveSearchYaml/processed"
)

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
