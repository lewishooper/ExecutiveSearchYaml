project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}
#rm(list=ls())
library(dplyr)
library(yaml)

# Load January data
jan_emp <- read.csv("processed/HospitalExecutives_Employees_2026-01-07.csv")
jan_vol <- read.csv("processed/HospitalExecutives_Volunteers_2026-01-07.csv")
jan_all <- bind_rows(
  jan_emp %>% mutate(person_type = "Employee"),
  jan_vol %>% mutate(person_type = "Volunteer")
)

# Load YAML
hospitals <- read_yaml("code/enhanced_hospitals.yaml")$hospitals

cat("\n")
cat(strrep("=", 70), "\n")
cat("JANUARY 2026 DATA QUALITY DIAGNOSTIC\n")
cat(strrep("=", 70), "\n\n")

# Analyze by data_status
status_summary <- jan_all %>%
  group_by(data_status) %>%
  summarize(
    hospitals = n_distinct(fac_number),
    records = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(hospitals))

cat("Status breakdown:\n")
print(status_summary)

# Problem categories
cat("\n")
cat(strrep("-", 70), "\n")
cat("PROBLEM HOSPITALS:\n")
cat(strrep("-", 70), "\n\n")

# Category 1: Failed
failed <- jan_all %>%
  filter(data_status == "failed") %>%
  distinct(fac_number, hospital_name, data_status)

if (nrow(failed) > 0) {
  cat(sprintf("❌ FAILED (%d hospitals):\n", nrow(failed)))
  for (i in 1:nrow(failed)) {
    cat(sprintf("  FAC %s: %s\n", failed$fac_number[i], failed$hospital_name[i]))
  }
  cat("\n")
}

# Category 2: Manual Entry with no data or NA
manual_na <- jan_all %>%
  filter(data_status == "manual_entry" & (is.na(person_name) | person_name == "")) %>%
  distinct(fac_number, hospital_name)

if (nrow(manual_na) > 0) {
  cat(sprintf("⚠️  MANUAL ENTRY - NO DATA (%d hospitals):\n", nrow(manual_na)))
  for (i in 1:nrow(manual_na)) {
    cat(sprintf("  FAC %s: %s\n", manual_na$fac_number[i], manual_na$hospital_name[i]))
  }
  cat("\n")
}

# Category 3: Robotstxt blocked
blocked <- jan_all %>%
  filter(data_status == "robotstxt_blocked") %>%
  distinct(fac_number, hospital_name)

if (nrow(blocked) > 0) {
  cat(sprintf("🚫 ROBOTSTXT BLOCKED (%d hospitals):\n", nrow(blocked)))
  for (i in 1:nrow(blocked)) {
    cat(sprintf("  FAC %s: %s\n", blocked$fac_number[i], blocked$hospital_name[i]))
  }
  cat("\n")
}

# Category 4: Any other NA entries
other_na <- jan_all %>%
  filter(!data_status %in% c("failed", "manual_entry", "robotstxt_blocked") &
           (is.na(person_name) | person_name == "")) %>%
  distinct(fac_number, hospital_name, data_status)

if (nrow(other_na) > 0) {
  cat(sprintf("❓ OTHER NA ENTRIES (%d hospitals):\n", nrow(other_na)))
  for (i in 1:nrow(other_na)) {
    cat(sprintf("  FAC %s: %s (status: %s)\n", 
                other_na$fac_number[i], other_na$hospital_name[i], other_na$data_status[i]))
  }
  cat("\n")
}

cat(strrep("=", 70), "\n")
cat(sprintf("SUMMARY: %d hospitals need attention\n", 
            nrow(failed) + nrow(manual_na) + nrow(blocked) + nrow(other_na)))
cat(strrep("=", 70), "\n")

