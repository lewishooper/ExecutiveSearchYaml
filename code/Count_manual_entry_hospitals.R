#


# Count and list all hospitals with manual_entry_required pattern
# Run this from your R console in the project directory
rm(list=ls())
library(yaml)
library(dplyr)
library(tibble)

# Load the enhanced_hospitals.yaml file
yaml_path <- "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml"
config <- yaml::read_yaml(yaml_path)

# Extract manual entry hospitals
manual_hospitals <- list()

for (i in seq_along(config$hospitals)) {
  hospital <- config$hospitals[[i]]
  
  # Check if pattern is manual_entry_required
  if (!is.null(hospital$pattern) && hospital$pattern == "manual_entry_required") {
    manual_hospitals[[length(manual_hospitals) + 1]] <- list(
      FAC = hospital$FAC,
      name = hospital$name,
      url = ifelse(is.null(hospital$url), "No URL", hospital$url),
      status = ifelse(is.null(hospital$status), "No status", hospital$status),
      notes = ifelse(is.null(hospital$notes), "", hospital$notes),
      expected_executives = ifelse(is.null(hospital$expected_executives), NA, hospital$expected_executives),
      has_missing_people = !is.null(hospital$html_structure$missing_people),
      missing_people_count = ifelse(!is.null(hospital$html_structure$missing_people), 
                                    length(hospital$html_structure$missing_people), 
                                    0)
    )
  }
}

# Convert to data frame for easy viewing
manual_df <- bind_rows(manual_hospitals)

# Print summary
cat("\n===========================================\n")
cat("MANUAL ENTRY REQUIRED HOSPITALS\n")
cat("===========================================\n\n")
cat("Total Count:", nrow(manual_df), "\n\n")

# Print detailed list
cat("DETAILED LIST:\n")
cat("-------------------------------------------\n\n")

for (i in 1:nrow(manual_df)) {
  cat(sprintf("FAC-%s: %s\n", manual_df$FAC[i], manual_df$name[i]))
  cat(sprintf("  URL: %s\n", manual_df$url[i]))
  cat(sprintf("  Status: %s\n", manual_df$status[i]))
  cat(sprintf("  Expected Executives: %s\n", 
              ifelse(is.na(manual_df$expected_executives[i]), "Not specified", 
                     manual_df$expected_executives[i])))
  cat(sprintf("  Has missing_people entries: %s\n", 
              ifelse(manual_df$has_missing_people[i], 
                     sprintf("YES (%d entries)", manual_df$missing_people_count[i]), 
                     "NO")))
  if (manual_df$notes[i] != "") {
    cat(sprintf("  Notes: %s\n", manual_df$notes[i]))
  }
  cat("\n")
}

# Also check for any hospitals with missing_people entries but NOT marked as manual_entry_required
cat("\n===========================================\n")
cat("HOSPITALS WITH missing_people BUT OTHER PATTERNS\n")
cat("===========================================\n\n")

other_missing_people <- list()

for (i in seq_along(config$hospitals)) {
  hospital <- config$hospitals[[i]]
  
  # Check if has missing_people but pattern is NOT manual_entry_required
  if (!is.null(hospital$html_structure$missing_people) && 
      (!is.null(hospital$pattern) && hospital$pattern != "manual_entry_required")) {
    other_missing_people[[length(other_missing_people) + 1]] <- list(
      FAC = hospital$FAC,
      name = hospital$name,
      pattern = hospital$pattern,
      missing_people_count = length(hospital$html_structure$missing_people),
      status = ifelse(is.null(hospital$status), "No status", hospital$status)
    )
  }
}

if (length(other_missing_people) > 0) {
  other_df <- bind_rows(other_missing_people)
  cat("Count:", nrow(other_df), "\n\n")
  
  for (i in 1:nrow(other_df)) {
    cat(sprintf("FAC-%s: %s\n", other_df$FAC[i], other_df$name[i]))
    cat(sprintf("  Pattern: %s\n", other_df$pattern[i]))
    cat(sprintf("  Missing people count: %d\n", other_df$missing_people_count[i]))
    cat(sprintf("  Status: %s\n", other_df$status[i]))
    cat("\n")
  }
} else {
  cat("None found.\n\n")
}

# Summary statistics
cat("\n===========================================\n")
cat("SUMMARY STATISTICS\n")
cat("===========================================\n\n")
cat(sprintf("Total hospitals in YAML: %d\n", length(config$hospitals)))
cat(sprintf("Manual entry required: %d (%.1f%%)\n", 
            nrow(manual_df), 
            nrow(manual_df) / length(config$hospitals) * 100))
if (length(other_missing_people) > 0) {
  cat(sprintf("Other patterns with missing_people: %d (%.1f%%)\n", 
              nrow(other_df), 
              nrow(other_df) / length(config$hospitals) * 100))
}

# Return the data frame for further analysis
cat("\nData frame 'manual_df' is available for further analysis.\n")
cat("Data frame 'other_df' contains hospitals with missing_people but other patterns.\n\n")

# Optionally save to CSV
cat("Save to CSV? (y/n): ")
save_choice <- readline()
if (tolower(save_choice) == "y") {
  output_file <- sprintf("E:/ExecutiveSearchYaml/tracking/manual_entry_hospitals_%s.csv", 
                         format(Sys.Date(), "%Y%m%d"))
  write.csv(manual_df, output_file, row.names = FALSE)
  cat(sprintf("\nSaved to: %s\n", output_file))
}