# identify_failing_hospitals.R
# Quick script to identify which hospitals are failing
# Save in E:/ExecutiveSearchYaml/code/

setwd("E:/ExecutiveSearchYaml/code/")

library(yaml)
library(dplyr)

# Read the YAML file
config <- yaml::read_yaml("enhanced_hospitals.yaml")

# Check which hospitals have real URLs (not TODO)
configured_hospitals <- data.frame(
  FAC = character(),
  Name = character(),
  URL = character(),
  Pattern = character(),
  Status = character(),
  stringsAsFactors = FALSE
)

for (hospital in config$hospitals) {
  # Skip if URL is TODO or missing
  if (is.null(hospital$url) || grepl("TODO", hospital$url, ignore.case = TRUE)) {
    next
  }
  
  configured_hospitals <- rbind(configured_hospitals, data.frame(
    FAC = hospital$FAC,
    Name = hospital$name,
    URL = hospital$url,
    Pattern = hospital$pattern,
    Status = hospital$status %||% "unknown",
    stringsAsFactors = FALSE
  ))
}

cat("=== CONFIGURED HOSPITALS (with real URLs) ===\n")
cat("Total configured:", nrow(configured_hospitals), "\n\n")

print(configured_hospitals)

# Now check which ones failed in the most recent output
output_files <- list.files("E:/ExecutiveSearchYaml/output", 
                           pattern = "*.csv", 
                           full.names = TRUE)

if (length(output_files) > 0) {
  # Get most recent file
  latest_file <- output_files[which.max(file.mtime(output_files))]
  cat("\n=== CHECKING LATEST RESULTS ===\n")
  cat("File:", basename(latest_file), "\n\n")
  
  results <- read.csv(latest_file, stringsAsFactors = FALSE)
  
  # Identify failures (no executives found)
  failures <- results %>%
    group_by(FAC, hospital_name) %>%
    summarise(
      valid_executives = sum(!is.na(executive_name) & !is.na(executive_title)),
      .groups = "drop"
    ) %>%
    filter(valid_executives == 0)
  
  cat("=== FAILING HOSPITALS (0 executives found) ===\n")
  cat("Total failures:", nrow(failures), "\n\n")
  
  if (nrow(failures) > 0) {
    for (i in 1:nrow(failures)) {
      cat(sprintf("%d. FAC-%s: %s\n", i, failures$FAC[i], failures$hospital_name[i]))
    }
    
    # Return the list
    cat("\n=== FAILED FAC NUMBERS ===\n")
    cat(paste(failures$FAC, collapse = ", "), "\n")
  }
} else {
  cat("\nNo output files found. Run quick_test_batch() first.\n")
}