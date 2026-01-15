# =============================================================================
# APPEND RAW DATA - Merge Pattern Scraper and API Extraction Outputs
# Modified Approach A - Final Step Before Processing
# =============================================================================
#
# Purpose: Combine raw outputs from pattern_based_scraper.R and 
#          step2_api_extraction.R into single file for processing
#
# Author: Skip (with Claude assistance)
# Date: January 13, 2026
# Version: 1.0
#
# Input Files:
#   - hospital_executives_YYYYMMDD.csv (pattern scraper)
#   - api_executives_YYYYMMDD.csv (API extraction)
#
# Output File:
#   - combined_raw_YYYYMMDD.csv (ready for process_hospital_data.R)
#
# =============================================================================

library(dplyr)
library(readr)
source("E:/ExecutiveSearchYaml/code/logging_functions.R")
cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   APPEND RAW DATA - MERGE SCRAPER OUTPUTS      ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# =============================================================================
# CONFIGURATION
# =============================================================================

# Input/Output directory
data_dir <- "E:/ExecutiveSearchYaml/output"

# Default to today's date, or accept parameter
date_tag <- format(Sys.Date(), "%Y%m%d")

# Expected schema (both files should have these columns)
EXPECTED_COLUMNS <- c(
  "FAC", 
  "hospital_name", 
  "executive_name", 
  "executive_title", 
  "date_gathered", 
  "robots_status", 
  "robots_message"
)

cat("Configuration:\n")
cat("══════════════════════════════════════════════════\n")
cat("  Data directory:", data_dir, "\n")
cat("  Date tag:", date_tag, "\n")
cat("  Expected columns:", length(EXPECTED_COLUMNS), "\n\n")

# =============================================================================
# HELPER FUNCTION: Validate Schema
# =============================================================================

validate_schema <- function(df, filename, expected_cols) {
  actual_cols <- names(df)
  
  # Check if all expected columns are present
  missing_cols <- setdiff(expected_cols, actual_cols)
  extra_cols <- setdiff(actual_cols, expected_cols)
  
  if (length(missing_cols) > 0) {
    stop(sprintf("ERROR: %s is missing columns: %s", 
                 filename, 
                 paste(missing_cols, collapse = ", ")))
  }
  
  if (length(extra_cols) > 0) {
    warning(sprintf("WARNING: %s has extra columns (will be ignored): %s", 
                    filename, 
                    paste(extra_cols, collapse = ", ")))
  }
  
  # Return TRUE if schema is valid
  return(TRUE)
}

# =============================================================================
# HELPER FUNCTION: Summary Statistics
# =============================================================================

print_file_summary <- function(df, source_name) {
  cat(sprintf("\n%s SUMMARY:\n", toupper(source_name)))
  cat("──────────────────────────────────────────────────\n")
  cat(sprintf("  Total records:     %d\n", nrow(df)))
  cat(sprintf("  Valid records:     %d\n", sum(!is.na(df$executive_name))))
  cat(sprintf("  Failed records:    %d\n", sum(is.na(df$executive_name))))
  cat(sprintf("  Unique hospitals:  %d\n", length(unique(df$FAC))))
  cat(sprintf("  Date range:        %s\n", 
              paste(unique(df$date_gathered), collapse = ", ")))
  
  # Status breakdown
  status_table <- table(df$robots_status, useNA = "ifany")
  cat("  Status breakdown:\n")
  for (status in names(status_table)) {
    cat(sprintf("    - %s: %d\n", status, status_table[status]))
  }
}

# =============================================================================
# LOAD INPUT FILES
# =============================================================================

cat("Loading input files...\n")
cat("══════════════════════════════════════════════════\n")

# Pattern scraper file
pattern_file <- file.path(data_dir, sprintf("Hospital_executives_%s.csv", date_tag))
cat(sprintf("Pattern scraper: %s\n", basename(pattern_file)))

if (!file.exists(pattern_file)) {
  stop(sprintf("ERROR: Pattern scraper file not found: %s", pattern_file))
}

pattern_data <- read_csv(pattern_file, show_col_types = FALSE)
cat(sprintf("  ✓ Loaded %d records\n", nrow(pattern_data)))

# API extraction file
api_file <- file.path(data_dir, sprintf("api_executives_%s.csv", date_tag))
cat(sprintf("API extraction:  %s\n", basename(api_file)))

if (!file.exists(api_file)) {
  warning(sprintf("WARNING: API file not found: %s\nProceeding with pattern scraper data only.", api_file))
  api_data <- NULL
} else {
  api_data <- read_csv(api_file, show_col_types = FALSE)
  cat(sprintf("  ✓ Loaded %d records\n", nrow(api_data)))
}

# =============================================================================
# VALIDATE SCHEMAS
# =============================================================================

cat("\nValidating schemas...\n")
cat("══════════════════════════════════════════════════\n")

# Validate pattern scraper data
validate_schema(pattern_data, basename(pattern_file), EXPECTED_COLUMNS)
cat(sprintf("  ✓ Pattern scraper schema valid\n"))

# Validate API data if present
if (!is.null(api_data)) {
  validate_schema(api_data, basename(api_file), EXPECTED_COLUMNS)
  cat(sprintf("  ✓ API extraction schema valid\n"))
}

# =============================================================================
# CHECK FOR DUPLICATE FAC NUMBERS
# =============================================================================

if (!is.null(api_data)) {
  cat("\nChecking for duplicate hospitals...\n")
  cat("══════════════════════════════════════════════════\n")
  
  pattern_facs <- unique(pattern_data$FAC[!is.na(pattern_data$executive_name)])
  api_facs <- unique(api_data$FAC[!is.na(api_data$executive_name)])
  
  duplicate_facs <- intersect(pattern_facs, api_facs)
  
  if (length(duplicate_facs) > 0) {
    cat(sprintf("  ⚠ WARNING: %d hospitals appear in BOTH files:\n", length(duplicate_facs)))
    for (fac in duplicate_facs) {
      pattern_name <- pattern_data$hospital_name[pattern_data$FAC == fac][1]
      api_name <- api_data$hospital_name[api_data$FAC == fac][1]
      cat(sprintf("    - FAC-%s: %s\n", fac, pattern_name))
      
      # Count records from each source
      pattern_count <- sum(pattern_data$FAC == fac & !is.na(pattern_data$executive_name))
      api_count <- sum(api_data$FAC == fac & !is.na(api_data$executive_name))
      cat(sprintf("      Pattern: %d records, API: %d records\n", pattern_count, api_count))
    }
    
    cat("\n  This suggests the same hospital was processed by both methods.\n")
    cat("  The combined file will contain records from BOTH sources.\n")
    cat("  You may want to investigate and choose which to keep.\n")
  } else {
    cat("  ✓ No duplicate hospitals found (mutually exclusive as expected)\n")
  }
}

# =============================================================================
# DISPLAY SUMMARIES
# =============================================================================

print_file_summary(pattern_data, "Pattern Scraper")

if (!is.null(api_data)) {
  print_file_summary(api_data, "API Extraction")
}

# =============================================================================
# COMBINE DATA
# =============================================================================

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   COMBINING DATA                               ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

if (!is.null(api_data)) {
  # Ensure both data frames have exactly the same columns in same order
  pattern_data <- pattern_data[, EXPECTED_COLUMNS]
  api_data <- api_data[, EXPECTED_COLUMNS]
  
  # Combine
  combined_data <- bind_rows(pattern_data, api_data)
  
  cat(sprintf("Combined %d + %d = %d total records\n", 
              nrow(pattern_data), 
              nrow(api_data), 
              nrow(combined_data)))
} else {
  # Only pattern scraper data
  combined_data <- pattern_data[, EXPECTED_COLUMNS]
  cat(sprintf("Using pattern scraper data only: %d records\n", nrow(combined_data)))
}

# =============================================================================
# FINAL SUMMARY
# =============================================================================

print_file_summary(combined_data, "Combined Data")

# =============================================================================
# SAVE COMBINED FILE
# =============================================================================

cat("\nSaving combined file...\n")
cat("══════════════════════════════════════════════════\n")

output_file <- file.path(data_dir, sprintf("combined_raw_%s.csv", date_tag))
write_csv(combined_data, output_file)

cat(sprintf("  ✓ Saved: %s\n", basename(output_file)))
cat(sprintf("  Location: %s\n", output_file))
cat(sprintf("  Size: %.1f KB\n", file.size(output_file) / 1024))

# =============================================================================
# FINAL STATUS
# =============================================================================

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║              APPEND COMPLETE                   ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("NEXT STEP:\n")
cat("  Run process_hospital_data.R on the combined file:\n\n")
cat("  process_hospital_data(\n")
cat(sprintf("    input_file = \"%s\",\n", output_file))
cat("    config_file = \"enhanced_hospitals.yaml\",\n")
cat("    output_folder = \"E:/ExecutiveSearchYaml/processed\"\n")
cat("  )\n\n")

cat("This will:\n")
cat("  - Extract credentials from names\n")
cat("  - Classify employees vs volunteers\n")
cat("  - Add hospital_type, source_url, pattern_used from YAML\n")
cat("  - Flag priority positions\n")
cat("  - Generate final Employees and Volunteers files\n\n")

cat("✓ Append complete!\n\n")

# Return combined data invisibly
invisible(combined_data)