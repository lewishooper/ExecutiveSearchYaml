# Process most recent output
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives_20251201.csv",
  config_file = "enhanced_hospitals.yaml",
  output_folder = "E:/ExecutiveSearchYaml/processed"
)

# Generate validation sample
validation_sample <- validate_classification(
  bind_rows(result$employees, result$volunteers),
  sample_size = 100
)



result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/AllHospitalsNov202025.csv",
  config_file = "enhanced_hospitals.yaml",
  output_folder = "E:/ExecutiveSearchYaml/processed"
)

HospTypeProblems<-HospitalExecutives_Employees_2025_11_21 %>%
  filter(hospital_type=="Unknown")
