# ==============================================================================
# DIAGNOSTIC SCRIPT: Check Dec → Jan Issues
# ==============================================================================

source("code/master_reference_functions.R")

# Load data
cat("Loading data...\n")
dec_employees <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Employees_2025-12-01.csv") %>%
  filter(!(fac_number == 961 & grepl("OfficerVice", title)))
dec_volunteers <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Volunteers_2025-12-01.csv")

jan_employees <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Employees_2026-01-01.csv")
jan_volunteers <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Volunteers_2026-01-01.csv")

# Combine data
dec_all <- bind_rows(
  dec_employees %>% mutate(person_type = "Employee"),
  dec_volunteers %>% mutate(person_type = "Volunteer")
)

jan_all <- bind_rows(
  jan_employees %>% mutate(person_type = "Employee"),
  jan_volunteers %>% mutate(person_type = "Volunteer")
)

# Load master files
personnel_master_dec <- read.csv("processed/PersonnelMaster_2025-12-01.csv")
personnel_master_jan <- read.csv("processed/PersonnelMaster_2026-01-01.csv")

# Re-run comparison
cat("\nRunning comparison...\n")
comparison <- compare_all_hospitals(
  dec_employees, dec_volunteers,
  jan_employees, jan_volunteers,
  personnel_master_dec
)

# === DIAGNOSTIC 1: Check for whole-hospital failures ===
cat("\n")
cat(strrep("=", 70), "\n")
cat("DIAGNOSTIC 1: Whole-Hospital Departure Detection\n")
cat(strrep("=", 70), "\n")

hospital_failures <- diagnose_hospital_failures(comparison, threshold = 0.5)

# === DIAGNOSTIC 2: Check for name matching failures ===
cat("\n")
cat(strrep("=", 70), "\n")
cat("DIAGNOSTIC 2: Individual Name Matching Failures\n")
cat(strrep("=", 70), "\n")

name_failures <- diagnose_name_matching_failures(dec_all, jan_all, 
                                                 personnel_master_jan, threshold = 0.90)

# === DIAGNOSTIC 3: Check data quality ===
cat("\n")
cat(strrep("=", 70), "\n")
cat("DIAGNOSTIC 3: Data Quality Issues\n")
cat(strrep("=", 70), "\n")

data_issues <- diagnose_data_quality(dec_all, jan_all)

# === SUMMARY ===
cat("\n")
cat(strrep("=", 70), "\n")
cat("DIAGNOSTIC SUMMARY\n")
cat(strrep("=", 70), "\n")

cat(sprintf("\nHospitals with suspected scraper failures: %d\n", nrow(hospital_failures)))
cat(sprintf("Individuals with potential name matching issues: %d\n", nrow(name_failures)))
cat(sprintf("December data quality issues: %d rows\n", nrow(data_issues$dec_issues)))
cat(sprintf("January data quality issues: %d rows\n", nrow(data_issues$jan_issues)))

# Save results for review
if (nrow(hospital_failures) > 0) {
  write.csv(hospital_failures, "processed/DIAGNOSTIC_Hospital_Failures.csv", row.names = FALSE)
  cat("Saved: DIAGNOSTIC_Hospital_Failures.csv\n")
}
if (nrow(name_failures) > 0) {
  write.csv(name_failures, "processed/DIAGNOSTIC_Name_Matching_Failures.csv", row.names = FALSE)
  cat("Saved: DIAGNOSTIC_Name_Matching_Failures.csv\n")
}
if (nrow(data_issues$dec_issues) > 0) {
  write.csv(data_issues$dec_issues, "processed/DIAGNOSTIC_Dec_Data_Issues.csv", row.names = FALSE)
  cat("Saved: DIAGNOSTIC_Dec_Data_Issues.csv\n")
}
if (nrow(data_issues$jan_issues) > 0) {
  write.csv(data_issues$jan_issues, "processed/DIAGNOSTIC_Jan_Data_Issues.csv", row.names = FALSE)
  cat("Saved: DIAGNOSTIC_Jan_Data_Issues.csv\n")
}

cat("\n✓ Diagnostic complete - review files in processed/ directory\n")