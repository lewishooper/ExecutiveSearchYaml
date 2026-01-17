library(dplyr)
library(stringr)

# Load functions
source("E:/ExecutiveSearchYaml/code/master_reference_functions.R")

# Load all data at once
data <- load_phase3_data()

# Extract individual pieces
dec_employees <- data$dec_employees
dec_volunteers <- data$dec_volunteers
jan_employees <- data$jan_employees
jan_volunteers <- data$jan_volunteers
personnel_master <- data$personnel_master

# Run comparison
comparison_results <- compare_all_hospitals(
  dec_employees = dec_employees,
  dec_volunteers = dec_volunteers,
  jan_employees = jan_employees,
  jan_volunteers = jan_volunteers,
  personnel_master = personnel_master
)

# Review results
View(comparison_results$hospital_summary)
View(comparison_results$retained)
View(comparison_results$new_arrivals)
View(comparison_results$departures)


#Run movement detection**

movements <- detect_simple_movements(
  departures = comparison_results$departures,
  new_arrivals = comparison_results$new_arrivals,
  threshold = 0.85
)

### 2.5 Update Personnel Master

# [ ] **Run master update function**
updated_master <- update_personnel_master(
  personnel_master = personnel_master,
  comparison_results = comparison_results,
  movements = movements,
  run_date = "2026-01-01"
)


#summary Report
generate_summary_report(
  comparison_results = comparison_results,
  movements = movements,
  personnel_master_before = personnel_master,
  personnel_master_after = updated_master
)

write.csv(updated_master,
          "E:/ExecutiveSearchYaml/processed/PersonnelMaster_2026-01-01.csv",
          row.names = FALSE)
view(movements)
# Create output directory if needed
dir.create("E:/ExecutiveSearchYaml/output/temp", recursive = TRUE, showWarnings = FALSE)

# Export comparison results
write.csv(comparison_results$retained,
          "E:/ExecutiveSearchYaml/output/temp/Retained_2026-01.csv",
          row.names = FALSE)

write.csv(comparison_results$new_arrivals,
          "E:/ExecutiveSearchYaml/output/temp/NewArrivals_2026-01.csv",
          row.names = FALSE)

write.csv(comparison_results$departures,
          "E:/ExecutiveSearchYaml/output/temp/Departures_2026-01.csv",
          row.names = FALSE)

write.csv(movements,
          "E:/ExecutiveSearchYaml/output/temp/Movements_2026-01.csv",
          row.names = FALSE)

write.csv(comparison_results$hospital_summary,
          "E:/ExecutiveSearchYaml/output/temp/HospitalSummary_2026-01.csv",
          row.names = FALSE)


title_changes <- comparison_results$retained %>%
  filter(title_changed == TRUE) %>%
  select(person_id, person_name, hospital_name, title_dec, title_jan)

write.csv(title_changes,
          "E:/ExecutiveSearchYaml/output/temp/TitleChanges_2026-01.csv",
          row.names = FALSE)
list.files("E:/ExecutiveSearchYaml/output/temp", pattern = "2026-01", full.names = TRUE)
