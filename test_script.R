# ==============================================================================
# TEST SCRIPT: Dec → Jan Comparison
# ==============================================================================
getwd
# Source the functions
source("code/master_reference_functions.R")

# Load December data
dec_employees <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Employees_2025-12-01.csv") %>%
  filter(!(fac_number == 961 & grepl("OfficerVice", title)))
dec_volunteers <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Volunteers_2025-12-01.csv")

# Load January data
jan_employees <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Employees_2026-01-01.csv") %>%
  filter(!(fac_number == 961 & grepl("OfficerVice", title)))

jan_volunteers <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Volunteers_2026-01-01.csv")

cat("Data loaded successfully\n")
cat(sprintf("Dec: %d employees, %d volunteers\n", 
            nrow(dec_employees), nrow(dec_volunteers)))
cat(sprintf("Jan: %d employees, %d volunteers\n", 
            nrow(jan_employees), nrow(jan_volunteers)))

# Step 1: Initialize Personnel Master from December
cat("\n=== STEP 1: Initialize Personnel Master ===\n")
personnel_master <- initialize_personnel_master(
  dec_employees, 
  dec_volunteers, 
  "2025-12-01"
)

# Save December baseline
write.csv(personnel_master, 
          "E:/ExecutiveSearchYaml/processed/PersonnelMaster_2025-12-01.csv", 
          row.names = FALSE)
cat("Saved: PersonnelMaster_2025-12-01.csv\n")

# Step 2: Compare Dec vs Jan
cat("\n=== STEP 2: Compare Dec vs Jan ===\n")
comparison <- compare_all_hospitals(
  dec_employees, dec_volunteers,
  jan_employees, jan_volunteers,
  personnel_master
)

# Step 3: Detect movements
cat("\n=== STEP 3: Detect Movements ===\n")
movements <- detect_simple_movements(
  comparison$departures, 
  comparison$new_arrivals,
  threshold = 0.85
)

# Step 4: Update Personnel Master
cat("\n=== STEP 4: Update Personnel Master ===\n")
personnel_master_updated <- update_personnel_master(
  personnel_master,
  comparison,
  movements,
  "2026-01-01"
)

# Save January master
write.csv(personnel_master_updated, 
          "E:/ExecutiveSearchYaml/processed/PersonnelMaster_2026-01-01.csv", 
          row.names = FALSE)
cat("Saved: PersonnelMaster_2026-01-01.csv\n")

# Step 5: Generate summary
cat("\n=== STEP 5: Summary Report ===\n")
generate_summary_report(
  comparison, 
  movements,
  personnel_master,
  personnel_master_updated
)

# Save detailed results for review
if (nrow(movements) > 0) {
  write.csv(movements, 
            "E:/ExecutiveSearchYaml/processed/PersonnelMovement_2026-01.csv", 
            row.names = FALSE)
  cat("\nSaved: PersonnelMovement_2026-01.csv\n")
}

if (nrow(comparison$hospital_summary) > 0) {
  write.csv(comparison$hospital_summary, 
            "E:/ExecutiveSearchYaml/processed/HospitalComparison_Summary_2026-01.csv", 
            row.names = FALSE)
  cat("Saved: HospitalComparison_Summary_2026-01.csv\n")
}

cat("\n=== COMPLETE ===\n")
       (NEW - hospital summary)