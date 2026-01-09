project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}

library(dplyr)

cat("\n")
cat(strrep("=", 70), "\n")
cat("COMPARING OLD VS NEW JANUARY DATA\n")
cat(strrep("=", 70), "\n\n")

# Load old (failed) and new (fixed) January data
jan_old_emp <- read.csv("processed/BACKUP_HospitalExecutives_Employees_2026-01-01.csv")
jan_old_vol <- read.csv("processed/BACKUP_HospitalExecutives_Volunteers_2026-01-01.csv")

jan_new_emp <- read.csv("processed/HospitalExecutives_Employees_2026-01-01.csv")
jan_new_vol <- read.csv("processed/HospitalExecutives_Volunteers_2026-01-01.csv")

# Combine employees and volunteers
jan_old <- bind_rows(
  jan_old_emp %>% mutate(person_type = "Employee"),
  jan_old_vol %>% mutate(person_type = "Volunteer")
)

jan_new <- bind_rows(
  jan_new_emp %>% mutate(person_type = "Employee"),
  jan_new_vol %>% mutate(person_type = "Volunteer")
)

# Compare counts for the 3 problem hospitals
problem_facs <- c(707, 624, 777)
hospital_names <- c("Ross Memorial", "Campbellford Memorial", "Queensway Carleton")

cat("PROBLEM HOSPITALS - OLD VS NEW:\n")
cat(strrep("-", 70), "\n")

comparison <- data.frame(
  FAC = problem_facs,
  Hospital = hospital_names,
  Old_Count = sapply(problem_facs, function(f) sum(jan_old$fac_number == f, na.rm = TRUE)),
  New_Count = sapply(problem_facs, function(f) sum(jan_new$fac_number == f, na.rm = TRUE)),
  Recovered = sapply(problem_facs, function(f) {
    sum(jan_new$fac_number == f, na.rm = TRUE) - sum(jan_old$fac_number == f, na.rm = TRUE)
  })
)

print(comparison)

cat("\n")
cat(strrep("-", 70), "\n")
cat("OVERALL TOTALS:\n")
cat(strrep("-", 70), "\n")
cat(sprintf("Old January total: %d people\n", nrow(jan_old)))
cat(sprintf("New January total: %d people\n", nrow(jan_new)))
cat(sprintf("People recovered: %+d\n", nrow(jan_new) - nrow(jan_old)))

# Check if we recovered the expected amounts
cat("\n")
cat(strrep("-", 70), "\n")
cat("DATA QUALITY CHECK:\n")
cat(strrep("-", 70), "\n")

total_recovered <- sum(comparison$Recovered)
cat(sprintf("Total people recovered from 3 hospitals: %d\n", total_recovered))

if (total_recovered == 21) {
  cat("✓ PERFECT - Recovered exactly 21 people as expected!\n")
} else if (total_recovered > 15) {
  cat("✓ GOOD - Recovered substantial number of people\n")
} else {
  cat("⚠ WARNING - Recovered fewer people than expected\n")
}

# Check for NA entries in new data
na_in_new <- jan_new %>% 
  filter(is.na(person_name) | person_name == "")

if (nrow(na_in_new) > 0) {
  cat(sprintf("\n⚠ Note: Still found %d NA entries in new data\n", nrow(na_in_new)))
  cat("Hospitals with NA entries:\n")
  print(unique(na_in_new[, c("fac_number", "hospital_name")]))
} else {
  cat("\n✓ No NA entries in new January data\n")
}

cat("\n")
cat(strrep("=", 70), "\n")
cat("✓ COMPARISON COMPLETE\n")
cat(strrep("=", 70), "\n")