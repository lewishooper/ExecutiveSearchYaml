# monthly_executive_collection.R
# Summary and validation for Ontario Hospital Executive Data Collection
# Run AFTER completing all manual collection steps
# 
# Version: 2.0 - Manual Workflow Support
# Updated: January 2026
# Location: E:/ExecutiveSearchYaml/code/
#
# Usage:
#   source("E:/ExecutiveSearchYaml/code/monthly_executive_collection.R")
#   summary <- summarize_monthly_collection()
#
# ==============================================================================

# Source utilities
source("E:/ExecutiveSearchYaml/code/logging_functions.R")
source("E:/ExecutiveSearchYaml/code/validation_functions.R")

# ==============================================================================
# CONFIGURATION
# ==============================================================================

BASE_DIR <- "E:/ExecutiveSearchYaml"
OUTPUT_DIR <- file.path(BASE_DIR, "output")
PROCESSED_DIR <- file.path(BASE_DIR, "processed")
LOG_DIR <- file.path(BASE_DIR, "tracking")

# ==============================================================================
# SUMMARY AND VALIDATION FUNCTION
# ==============================================================================

summarize_monthly_collection <- function(collection_date = Sys.Date()) {
  
  # Format dates
  date_string <- format(as.Date(collection_date), "%Y-%m-%d")
  date_yyyymmdd <- format(as.Date(collection_date), "%Y%m%d")
  
  # Create log file
  log_file <- create_log_file(collection_date, "monthly_summary")
  
  # Header
  log_section("MONTHLY COLLECTION SUMMARY", log_file)
  log_message(paste("Collection Date:", date_string), log_file)
  log_message(paste("Run Time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), log_file)
  log_message("", log_file)
  
  # Track validation status
  all_valid <- TRUE
  issues <- character()
  
  # ========================================================================
  # STEP 1: VALIDATE EXPECTED FILES EXIST
  # ========================================================================
  
  log_section("FILE VALIDATION", log_file)
  
  expected_files <- list(
    pattern_output = file.path(OUTPUT_DIR, paste0("hospital_executives_", date_yyyymmdd, ".csv")),
    api_output = file.path(OUTPUT_DIR, paste0("api_executives_", date_yyyymmdd, ".csv")),
    combined_output = file.path(OUTPUT_DIR, paste0("combined_raw_", date_yyyymmdd, ".csv")),
    employees_output = file.path(PROCESSED_DIR, paste0("HospitalExecutives_Employees_", date_string, ".csv")),
    volunteers_output = file.path(PROCESSED_DIR, paste0("HospitalExecutives_Volunteers_", date_string, ".csv"))
  )
  
  for (name in names(expected_files)) {
    file_path <- expected_files[[name]]
    
    if (file.exists(file_path)) {
      file_size <- file.size(file_path)
      log_message(sprintf("  ✓ %s (%.1f KB)", basename(file_path), file_size / 1024), log_file)
    } else {
      log_warning(sprintf("  ✗ MISSING: %s", basename(file_path)), log_file)
      all_valid <- FALSE
      issues <- c(issues, paste("Missing file:", name))
    }
  }
  
  # ========================================================================
  # STEP 2: VALIDATE RECORD COUNTS
  # ========================================================================
  
  log_message("", log_file)
  log_section("RECORD COUNT VALIDATION", log_file)
  
  counts <- list()
  
  # Read files if they exist
  tryCatch({
    if (file.exists(expected_files$pattern_output)) {
      pattern_data <- read.csv(expected_files$pattern_output, stringsAsFactors = FALSE)
      counts$pattern <- nrow(pattern_data)
      log_message(sprintf("  Pattern scraper: %d records", counts$pattern), log_file)
    }
    
    if (file.exists(expected_files$api_output)) {
      api_data <- read.csv(expected_files$api_output, stringsAsFactors = FALSE)
      counts$api <- nrow(api_data)
      log_message(sprintf("  API extraction: %d records", counts$api), log_file)
    }
    
    if (file.exists(expected_files$combined_output)) {
      combined_data <- read.csv(expected_files$combined_output, stringsAsFactors = FALSE)
      counts$combined <- nrow(combined_data)
      log_message(sprintf("  Combined raw: %d records", counts$combined), log_file)
    }
    
    if (file.exists(expected_files$employees_output)) {
      employees_data <- read.csv(expected_files$employees_output, stringsAsFactors = FALSE)
      counts$employees <- nrow(employees_data)
      log_message(sprintf("  Employees: %d records", counts$employees), log_file)
    }
    
    if (file.exists(expected_files$volunteers_output)) {
      volunteers_data <- read.csv(expected_files$volunteers_output, stringsAsFactors = FALSE)
      counts$volunteers <- nrow(volunteers_data)
      log_message(sprintf("  Volunteers: %d records", counts$volunteers), log_file)
    }
    
  }, error = function(e) {
    log_error(paste("Error reading files:", e$message), log_file, FALSE)
    all_valid <- FALSE
    issues <- c(issues, paste("File reading error:", e$message))
  })
  
  # ========================================================================
  # STEP 3: VALIDATE RECORD COUNT MATH
  # ========================================================================
  
  log_message("", log_file)
  log_section("RECORD COUNT VERIFICATION", log_file)
  
  # Check: pattern + api = combined
  if (!is.null(counts$pattern) && !is.null(counts$api) && !is.null(counts$combined)) {
    expected_combined <- counts$pattern + counts$api
    
    if (counts$combined == expected_combined) {
      log_message(sprintf("  ✓ Combined total correct: %d + %d = %d", 
                          counts$pattern, counts$api, counts$combined), log_file)
    } else {
      log_warning(sprintf("  ✗ Combined total MISMATCH: %d + %d = %d, but got %d", 
                          counts$pattern, counts$api, expected_combined, counts$combined), log_file)
      all_valid <- FALSE
      issues <- c(issues, sprintf("Combined count mismatch: expected %d, got %d", 
                                  expected_combined, counts$combined))
    }
  }
  
  # Check: employees + volunteers = combined
  if (!is.null(counts$employees) && !is.null(counts$volunteers) && !is.null(counts$combined)) {
    processed_total <- counts$employees + counts$volunteers
    
    if (processed_total == counts$combined) {
      log_message(sprintf("  ✓ Processed total correct: %d + %d = %d", 
                          counts$employees, counts$volunteers, processed_total), log_file)
    } else {
      log_warning(sprintf("  ✗ Processed total MISMATCH: %d + %d = %d, but combined was %d", 
                          counts$employees, counts$volunteers, processed_total, counts$combined), log_file)
      all_valid <- FALSE
      issues <- c(issues, sprintf("Processed count mismatch: expected %d, got %d", 
                                  counts$combined, processed_total))
    }
  }
  
  # ========================================================================
  # STEP 4: FINAL SUMMARY
  # ========================================================================
  
  log_message("", log_file)
  log_section("COLLECTION SUMMARY", log_file)
  
  if (all_valid && length(issues) == 0) {
    log_message("✓ ALL VALIDATIONS PASSED", log_file)
    log_message("", log_file)
    log_message("Monthly collection completed successfully!", log_file)
  } else {
    log_warning("⚠ VALIDATION ISSUES FOUND", log_file)
    log_message("", log_file)
    log_message("Issues detected:", log_file)
    for (issue in issues) {
      log_message(paste("  -", issue), log_file)
    }
  }
  
  log_message("", log_file)
  log_message("FINAL RECORD COUNTS:", log_file)
  log_record_counts(counts, log_file)
  
  log_message("", log_file)
  log_message("OUTPUT FILES:", log_file)
  for (name in names(expected_files)) {
    if (file.exists(expected_files[[name]])) {
      log_message(sprintf("  %s", expected_files[[name]]), log_file)
    }
  }
  
  log_message("", log_file)
  log_message(paste("Summary log saved:", log_file), log_file)
  
  # Return summary object
  return(list(
    collection_date = date_string,
    validation_passed = all_valid,
    issues = issues,
    record_counts = counts,
    output_files = expected_files[sapply(expected_files, file.exists)],
    log_file = log_file
  ))
}
