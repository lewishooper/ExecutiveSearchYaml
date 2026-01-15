# ==============================================================================
# ENVIRONMENT VALIDATION
# ==============================================================================

#' Validate that the working environment is properly configured
#' 
#' @param log_file Path to log file (optional)
#' @param auto_create If TRUE, automatically create missing directories
#' @return TRUE if validation passes, FALSE or stops on error
validate_environment <- function(log_file = NULL, auto_create = TRUE) {
  
  log_section("ENVIRONMENT VALIDATION", log_file)
  
  all_valid <- TRUE
  
  # Base directory
  BASE_DIR <- "E:/ExecutiveSearchYaml"
  
  # Required directories
  required_dirs <- c(
    code = file.path(BASE_DIR, "code"),
    output = file.path(BASE_DIR, "output"),
    processed = file.path(BASE_DIR, "processed"),
    tracking = file.path(BASE_DIR, "tracking"),
    temp = file.path(BASE_DIR, "temp"),
    temp_screenshots = file.path(BASE_DIR, "temp", "screenshots")
  )
  
  # Check and create directories
  log_message("Checking directories...", log_file)
  for (dir_name in names(required_dirs)) {
    dir_path <- required_dirs[[dir_name]]
    
    if (!dir.exists(dir_path)) {
      if (auto_create) {
        dir.create(dir_path, recursive = TRUE)
        log_message(sprintf("  Created: %s", dir_name), log_file)
      } else {
        log_error(sprintf("  Missing: %s (%s)", dir_name, dir_path), log_file, FALSE)
        all_valid <- FALSE
      }
    } else {
      log_message(sprintf("  ✓ %s", dir_name), log_file)
    }
  }
  
  # Required files
  required_files <- c(
    yaml = file.path(BASE_DIR, "code", "enhanced_hospitals.yaml"),
    scraper = file.path(BASE_DIR, "code", "pattern_based_scraper.R"),
    processor = file.path(BASE_DIR, "code", "process_hospital_data.R"),
    step1_screenshot = file.path(BASE_DIR, "code", "step1_screenshot_capture.R"),
    step2_api = file.path(BASE_DIR, "code", "step2_api_extraction.R"),
    append_raw = file.path(BASE_DIR, "code", "append_raw_data.R")
  )
  
  # Check files
  log_message("", log_file)
  log_message("Checking required files...", log_file)
  for (file_name in names(required_files)) {
    file_path <- required_files[[file_name]]
    
    if (!file.exists(file_path)) {
      log_error(sprintf("  Missing: %s (%s)", file_name, file_path), log_file, FALSE)
      all_valid <- FALSE
    } else {
      log_message(sprintf("  ✓ %s", file_name), log_file)
    }
  }
  
  # Check R packages
  required_packages <- c("rvest", "yaml", "dplyr", "httr", "xml2", "stringr")
  
  log_message("", log_file)
  log_message("Checking required packages...", log_file)
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      log_warning(sprintf("  Package not installed: %s", pkg), log_file)
      all_valid <- FALSE
    } else {
      log_message(sprintf("  ✓ %s", pkg), log_file)
    }
  }
  
  # Final status
  log_message("", log_file)
  if (all_valid) {
    log_message("✓ Environment validation PASSED", log_file)
  } else {
    log_error("✗ Environment validation FAILED - see errors above", log_file, TRUE)
  }
  
  return(all_valid)
}