# monthly_executive_collection.R
# Master automation script for Ontario Hospital Executive Data Collection
# This script orchestrates the complete monthly data collection process:
#   1. Scrapes all hospital websites using pattern_based_scraper.R
#   2. Processes raw data using process_hospital_data.R
#   3. Creates final employee and volunteer datasets
# 
# Version: 1.0
# Created: December 2025
# Location: E:/ExecutiveSearchYaml/code/
#
# Usage:
#   source("E:/ExecutiveSearchYaml/code/monthly_executive_collection.R")
#   result <- run_monthly_collection()
#
# ==============================================================================

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Base directory
BASE_DIR <- "E:/ExecutiveSearchYaml"

# File paths
CODE_DIR <- file.path(BASE_DIR, "code")
OUTPUT_DIR <- file.path(BASE_DIR, "output")
PROCESSED_DIR <- file.path(BASE_DIR, "processed")
LOG_DIR <- file.path(BASE_DIR, "tracking")

# Script paths
SCRAPER_SCRIPT <- file.path(CODE_DIR, "pattern_based_scraper.R")
PROCESSOR_SCRIPT <- file.path(CODE_DIR, "process_hospital_data.R")
CONFIG_FILE <- file.path(CODE_DIR, "enhanced_hospitals.yaml")

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

log_message <- function(message, log_file = NULL) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0("[", timestamp, "] ", message)
  
  # Console output
  cat(log_entry, "\n")
  
  # File output if specified
  if (!is.null(log_file)) {
    cat(log_entry, "\n", file = log_file, append = TRUE)
  }
}

log_error <- function(message, log_file = NULL, stop_execution = TRUE) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0("[", timestamp, "] ERROR: ", message)
  
  # Console output
  cat(log_entry, "\n")
  
  # File output if specified
  if (!is.null(log_file)) {
    cat(log_entry, "\n", file = log_file, append = TRUE)
  }
  
  if (stop_execution) {
    stop(message, call. = FALSE)
  }
}

# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================

validate_environment <- function(log_file = NULL) {
  log_message("=== VALIDATING ENVIRONMENT ===", log_file)
  
  # Check if required directories exist
  required_dirs <- c(BASE_DIR, CODE_DIR, OUTPUT_DIR, PROCESSED_DIR, LOG_DIR)
  
  for (dir in required_dirs) {
    if (!dir.exists(dir)) {
      # Try to create it
      tryCatch({
        dir.create(dir, recursive = TRUE)
        log_message(paste("Created directory:", dir), log_file)
      }, error = function(e) {
        log_error(paste("Cannot create directory:", dir, "-", e$message), 
                  log_file, stop_execution = TRUE)
      })
    } else {
      log_message(paste("Found directory:", basename(dir)), log_file)
    }
  }
  
  # Check if required scripts exist
  required_files <- c(SCRAPER_SCRIPT, PROCESSOR_SCRIPT, CONFIG_FILE)
  
  for (file in required_files) {
    if (!file.exists(file)) {
      log_error(paste("Required file not found:", file), 
                log_file, stop_execution = TRUE)
    } else {
      log_message(paste("Found file:", basename(file)), log_file)
    }
  }
  
  log_message("Environment validation complete", log_file)
  return(TRUE)
}

# ==============================================================================
# MAIN COLLECTION FUNCTION
# ==============================================================================

run_monthly_collection <- function(collection_date = Sys.Date()) {
  
  # Format date for filenames (ISO format: YYYY-MM-DD)
  date_string <- format(collection_date, "%Y-%m-%d")
  
  # Create log file
  log_filename <- paste0("monthly_collection_", date_string, ".log")
  log_file <- file.path(LOG_DIR, log_filename)
  
  # Initialize log
  cat("", file = log_file)  # Create empty log file
  
  log_message("", log_file)
  log_message("================================================================================", log_file)
  log_message("  ONTARIO HOSPITAL EXECUTIVE DATA COLLECTION", log_file)
  log_message(paste("  Run Date:", date_string), log_file)
  log_message("================================================================================", log_file)
  log_message("", log_file)
  
  start_time <- Sys.time()
  
  # Track results
  results <- list(
    success = FALSE,
    collection_date = date_string,
    start_time = start_time,
    end_time = NULL,
    duration_seconds = NULL,
    scraper_output = NULL,
    processed_files = NULL,
    record_counts = list(),
    log_file = log_file,
    errors = character()
  )
  
  tryCatch({
    
    # ========================================================================
    # STEP 1: VALIDATE ENVIRONMENT
    # ========================================================================
    
    validate_environment(log_file)
    log_message("", log_file)
    
    # ========================================================================
    # STEP 2: RUN PATTERN-BASED SCRAPER
    # ========================================================================
    
    log_message("=== STEP 1: RUNNING PATTERN-BASED SCRAPER ===", log_file)
    log_message(paste("Loading scraper from:", SCRAPER_SCRIPT), log_file)
    
    # Source the scraper (this loads the PatternBasedScraper function)
    source(SCRAPER_SCRIPT, local = TRUE)
    
    # Initialize the scraper to get the actual functions
    log_message("Initializing scraper functions...", log_file)
    scraper <- PatternBasedScraper()
    
    # Load the YAML config to get hospitals list
    log_message("Loading hospital configuration...", log_file)
    config <- yaml::read_yaml(CONFIG_FILE)
    hospitals_list <- config$hospitals
    log_message(paste("Found", length(hospitals_list), "hospitals to process"), log_file)
    
    # Start web scraping
    log_message("Starting web scraping process...", log_file)
    
    scraper_start <- Sys.time()
    
    # Call the scraper's batch function
    scraper_result <- scraper$scrape_batch(hospitals_list, CONFIG_FILE, OUTPUT_DIR)
    
    scraper_duration <- as.numeric(difftime(Sys.time(), scraper_start, units = "secs"))
    
    log_message(paste("Scraping completed in", round(scraper_duration, 1), "seconds"), log_file)
    
    # The scraper creates a file - find it
    # Pattern-based scraper typically creates: hospital_executives_YYYYMMDD.csv
    scraper_files <- list.files(OUTPUT_DIR, pattern = "^hospital_executives_.*\\.csv$", full.names = TRUE)
    
    if (length(scraper_files) == 0) {
      log_error("Scraper did not produce output file", log_file, stop_execution = TRUE)
    }
    
    # Get the most recent file
    scraper_output <- scraper_files[which.max(file.mtime(scraper_files))]
    
    log_message(paste("Scraper output:", basename(scraper_output)), log_file)
    
    # Rename to standard format
    standard_filename <- paste0("Hospital_executives_", date_string, ".csv")
    standard_path <- file.path(OUTPUT_DIR, standard_filename)
    
    file.rename(scraper_output, standard_path)
    log_message(paste("Renamed to:", standard_filename), log_file)
    
    results$scraper_output <- standard_path
    
    # Get record count from scraper output
    raw_data <- read.csv(standard_path, stringsAsFactors = FALSE)
    results$record_counts$raw_records <- nrow(raw_data)
    log_message(paste("Raw records collected:", results$record_counts$raw_records), log_file)
    log_message("", log_file)
    
    # ========================================================================
    # STEP 3: RUN POST-PROCESSOR
    # ========================================================================
    
    log_message("=== STEP 2: RUNNING POST-PROCESSOR ===", log_file)
    log_message(paste("Loading processor from:", PROCESSOR_SCRIPT), log_file)
    
    # Source the processor
    source(PROCESSOR_SCRIPT, local = TRUE)
    
    log_message("Starting data processing...", log_file)
    
    processor_start <- Sys.time()
    
    # Call the processor
    processed_result <- process_hospital_data(
      input_file = standard_path,
      config_file = CONFIG_FILE,
      output_folder = PROCESSED_DIR,
      output_date = collection_date
    )
    
    processor_duration <- as.numeric(difftime(Sys.time(), processor_start, units = "secs"))
    
    log_message(paste("Processing completed in", round(processor_duration, 1), "seconds"), log_file)
    
    # Store results
    results$processed_files <- processed_result$files
    results$record_counts$employees <- nrow(processed_result$employees)
    results$record_counts$volunteers <- nrow(processed_result$volunteers)
    results$record_counts$total_processed <- results$record_counts$employees + 
      results$record_counts$volunteers
    
    log_message("", log_file)
    
    # ========================================================================
    # STEP 4: VERIFY OUTPUTS
    # ========================================================================
    
    log_message("=== STEP 3: VERIFYING OUTPUTS ===", log_file)
    
    # Check that output files exist
    if (!file.exists(results$processed_files$employees_file)) {
      log_error("Employee output file not created", log_file, stop_execution = TRUE)
    }
    
    if (!file.exists(results$processed_files$volunteers_file)) {
      log_error("Volunteer output file not created", log_file, stop_execution = TRUE)
    }
    
    log_message("Employee file: OK", log_file)
    log_message("Volunteer file: OK", log_file)
    log_message("", log_file)
    
    # ========================================================================
    # SUCCESS
    # ========================================================================
    
    results$success <- TRUE
    results$end_time <- Sys.time()
    results$duration_seconds <- as.numeric(difftime(results$end_time, results$start_time, units = "secs"))
    
    log_message("================================================================================", log_file)
    log_message("  COLLECTION COMPLETE - SUCCESS", log_file)
    log_message("================================================================================", log_file)
    log_message(paste("Total duration:", round(results$duration_seconds, 1), "seconds"), log_file)
    log_message(paste("Raw records:", results$record_counts$raw_records), log_file)
    log_message(paste("Employees:", results$record_counts$employees), log_file)
    log_message(paste("Volunteers:", results$record_counts$volunteers), log_file)
    log_message(paste("Total processed:", results$record_counts$total_processed), log_file)
    log_message("", log_file)
    log_message("Output files:", log_file)
    log_message(paste("  -", basename(results$processed_files$employees_file)), log_file)
    log_message(paste("  -", basename(results$processed_files$volunteers_file)), log_file)
    log_message("", log_file)
    log_message(paste("Log file:", log_filename), log_file)
    log_message("================================================================================", log_file)
    
  }, error = function(e) {
    
    # ========================================================================
    # ERROR HANDLING
    # ========================================================================
    
    results$success <- FALSE
    results$end_time <- Sys.time()
    results$duration_seconds <- as.numeric(difftime(results$end_time, results$start_time, units = "secs"))
    results$errors <- c(results$errors, as.character(e$message))
    
    log_message("", log_file)
    log_message("================================================================================", log_file)
    log_message("  COLLECTION FAILED - ERROR", log_file)
    log_message("================================================================================", log_file)
    log_message(paste("Error:", e$message), log_file)
    log_message(paste("Duration before failure:", round(results$duration_seconds, 1), "seconds"), log_file)
    log_message("", log_file)
    log_message(paste("Log file:", log_filename), log_file)
    log_message("================================================================================", log_file)
    
  })
  
  return(results)
}

# ==============================================================================
# CONVENIENCE WRAPPER
# ==============================================================================

# For easy one-line execution
run_collection <- function() {
  return(run_monthly_collection())
}

# ==============================================================================
# SCRIPT LOADED MESSAGE
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("  Monthly Executive Collection Script Loaded\n")
cat("================================================================================\n")
cat("Usage:\n")
cat("  source('E:/ExecutiveSearchYaml/code/monthly_executive_collection.R')\n")
cat("  result <- run_monthly_collection()\n")
cat("\n")
cat("Or simply:\n")
cat("  result <- run_collection()\n")
cat("================================================================================\n")
cat("\n")
run_collection()
