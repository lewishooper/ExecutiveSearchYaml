# =============================================================================
# STEP 2: BATCH API EXTRACTION FROM SCREENSHOTS (REVISED)
# Modified Approach A - Output Standardized Raw Format
# =============================================================================
#
# Purpose: Process screenshots through Claude API and output standardized raw
#          format that matches pattern_based_scraper.R output for easy merging
#
# Author: Skip (with Claude assistance)
# Date: January 13, 2026
# Version: 2.0
#
# Key Changes from v1.0:
#   - Loads YAML to enrich with hospital metadata
#   - Outputs standardized raw format matching pattern scraper
#   - Adds data_source tracking field
#   - Saves to output/ folder (not processed/)
#   - Column names match pattern scraper conventions
#
# =============================================================================

library(httr)
library(jsonlite)
library(base64enc)
library(dplyr)
library(yaml)

# Load functions
source("E:/ExecutiveSearchYaml/code/logging_functions.R")
source("E:/ExecutiveSearchYaml/code/api_extraction_function.R")
source("E:/ExecutiveSearchYaml/code/validation_function.R")

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   STEP 2: BATCH API EXTRACTION (REVISED)       ║\n")
cat("║   (Output Standardized Raw Format)             ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# =============================================================================
# CONFIGURATION
# =============================================================================

# Screenshot directory (from Step 1)
screenshot_dir <- "E:/ExecutiveSearchYaml/temp/screenshots"
date_tag <- format(Sys.Date(), "%Y%m%d")

# YAML configuration file
yaml_file <- "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml"

# Output directory for RAW data (matches pattern scraper)
output_dir <- "E:/ExecutiveSearchYaml/output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Check API key
api_key <- Sys.getenv("ANTHROPIC_API_KEY")
if (api_key == "") {
  stop("ERROR: ANTHROPIC_API_KEY not set. Please set API key and restart R.")
}

cat("✓ API key found\n")
cat("✓ Screenshot directory:", screenshot_dir, "\n")
cat("✓ YAML config:", yaml_file, "\n")
cat("✓ Output directory:", output_dir, "\n\n")

# =============================================================================
# LOAD YAML CONFIGURATION FOR HOSPITAL METADATA
# =============================================================================

cat("Loading hospital configuration...\n")
cat("═════════════════════════════════════════════════\n")

# Read YAML
if (!file.exists(yaml_file)) {
  stop("ERROR: YAML configuration file not found: ", yaml_file)
}

yaml_config <- read_yaml(yaml_file)
hospitals_list <- yaml_config$hospitals

cat(sprintf("✓ Loaded %d hospitals from YAML\n", length(hospitals_list)))

# Create FAC lookup table for metadata enrichment
fac_lookup <- do.call(rbind, lapply(hospitals_list, function(h) {
  data.frame(
    FAC = sprintf("%03d", as.numeric(h$FAC)),
    hospital_name = h$name,
    hospital_type = ifelse(!is.null(h$hospital_type), h$hospital_type, NA),
    source_url = h$url,
    pattern = ifelse(!is.null(h$pattern), h$pattern, "unknown"),
    stringsAsFactors = FALSE
  )
}))

cat(sprintf("✓ Created FAC lookup table with %d hospitals\n\n", nrow(fac_lookup)))

# =============================================================================
# SCAN SCREENSHOT FOLDER
# =============================================================================

cat("Scanning screenshot folder...\n")
cat("═════════════════════════════════════════════════\n")

# Get all PNG files
screenshot_files <- list.files(
  screenshot_dir,
  pattern = "\\.png$",
  full.names = TRUE,
  ignore.case = TRUE
)

if (length(screenshot_files) == 0) {
  stop("ERROR: No PNG files found in screenshot directory")
}

cat(sprintf("Found %d screenshot files\n\n", length(screenshot_files)))

# Parse filenames to extract FAC numbers
parse_screenshot_filename <- function(filepath) {
  filename <- basename(filepath)
  
  # Expected format: FAC-XXX_YYYYMMDD.png
  # Extract FAC number
  fac_match <- regmatches(filename, regexpr("FAC-[0-9]+", filename))
  
  if (length(fac_match) > 0) {
    fac <- sub("FAC-", "", fac_match)
    fac <- sprintf("%03d", as.numeric(fac))  # Standardize to 3 digits
  } else {
    fac <- NA
  }
  
  # Extract date if present
  date_match <- regmatches(filename, regexpr("[0-9]{8}", filename))
  date_captured <- if (length(date_match) > 0) date_match else NA
  
  return(list(
    filepath = filepath,
    filename = filename,
    fac = fac,
    date_captured = date_captured
  ))
}

# Parse all filenames
file_info <- lapply(screenshot_files, parse_screenshot_filename)

# Display files to process
cat("FILES TO PROCESS:\n")
cat("═════════════════════════════════════════════════\n")
for (i in seq_along(file_info)) {
  info <- file_info[[i]]
  hospital_info <- fac_lookup[fac_lookup$FAC == info$fac, ]
  hospital_name <- if (nrow(hospital_info) > 0) hospital_info$hospital_name[1] else "Unknown"
  
  cat(sprintf("%2d. FAC-%s: %s\n", i, info$fac, hospital_name))
  cat(sprintf("    File: %s (%.1f KB)\n", info$filename, file.size(info$filepath) / 1024))
}
cat("\n")

# Confirm before proceeding
cat("═════════════════════════════════════════════════\n")
cat(sprintf("Ready to process %d screenshots via Claude API\n", length(file_info)))
cat(sprintf("Estimated cost: $%.4f\n", length(file_info) * 0.003))
cat("═════════════════════════════════════════════════\n")
cat("\nPress ENTER to continue or Ctrl+C to cancel...\n")
readline()

cat("\n")

# =============================================================================
# PROCESS EACH SCREENSHOT
# =============================================================================

cat("Processing screenshots...\n")
cat("═════════════════════════════════════════════════\n\n")

extraction_results <- list()
all_executives_raw <- list()
start_time <- Sys.time()

for (i in seq_along(file_info)) {
  
  info <- file_info[[i]]
  
  cat(sprintf("[%d/%d] FAC-%s\n", i, length(file_info), info$fac))
  cat("─────────────────────────────────────────────────\n")
  cat(sprintf("File: %s\n", info$filename))
  
  # Look up hospital metadata from YAML
  hospital_meta <- fac_lookup[fac_lookup$FAC == info$fac, ]
  
  if (nrow(hospital_meta) == 0) {
    cat(sprintf("⚠ WARNING: FAC-%s not found in YAML configuration\n", info$fac))
    cat("Skipping this hospital\n\n")
    next
  }
  
  hospital_meta <- hospital_meta[1, ]  # Take first match
  cat(sprintf("Hospital: %s\n", hospital_meta$hospital_name))
  
  # Extract executives via API
  result <- extract_executives_from_screenshot(
    screenshot_file = info$filepath,
    verbose = FALSE,  # Minimal output during batch
    max_retries = 3   # Increased retries
  )
  
  # Store result
  result$fac <- info$fac
  result$filename <- info$filename
  result$date_captured <- info$date_captured
  extraction_results[[i]] <- result
  
  # Report status
  if (result$success) {
    cat(sprintf("✓ Extracted %d people\n", nrow(result$executives)))
    cat(sprintf("  Cost: $%.4f\n", result$api_cost_estimate))
    
    # Enrich with hospital metadata and standardize format
    # Match pattern_based_scraper.R output structure
    raw_records <- data.frame(
      FAC = info$fac,
      hospital_name = hospital_meta$hospital_name,
      hospital_type = hospital_meta$hospital_type,
      executive_name = result$executives$name,
      executive_title = result$executives$title,
      date_gathered = as.Date(info$date_captured, format = "%Y%m%d"),
      source_url = hospital_meta$source_url,
      pattern_used = "api_screenshot",
      data_source = "api_screenshot",
      robots_status = "ok",  # Screenshots bypass robots.txt
      robots_message = NA,
      stringsAsFactors = FALSE
    )
    
    all_executives_raw[[i]] <- raw_records
  } else {
    cat(sprintf("✗ Extraction failed: %s\n", result$error_message))
    
    # Create failure record
    failure_record <- data.frame(
      FAC = info$fac,
      hospital_name = hospital_meta$hospital_name,
      hospital_type = hospital_meta$hospital_type,
      executive_name = NA,
      executive_title = NA,
      date_gathered = as.Date(info$date_captured, format = "%Y%m%d"),
      source_url = hospital_meta$source_url,
      pattern_used = "api_screenshot",
      data_source = "api_screenshot",
      robots_status = "error",
      robots_message = result$error_message,
      stringsAsFactors = FALSE
    )
    
    all_executives_raw[[i]] <- failure_record
  }
  
  cat("\n")
  
  # Pause between API calls to avoid rate limiting
  if (i < length(file_info)) {
    Sys.sleep(3)  # Increased from 2 to 3 seconds
  }
}

end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# =============================================================================
# CONSOLIDATE RESULTS INTO STANDARDIZED RAW FORMAT
# =============================================================================

cat("═════════════════════════════════════════════════\n")
cat("Consolidating results...\n")
cat("═════════════════════════════════════════════════\n\n")

# Combine all records into single data frame
if (length(all_executives_raw) > 0) {
  consolidated_raw <- do.call(rbind, all_executives_raw)
  
  # Ensure consistent column order (match pattern_based_scraper.R)
  consolidated_raw <- consolidated_raw[, c(
    "FAC", "hospital_name", "hospital_type", "executive_name", 
    "executive_title", "date_gathered", "source_url", "pattern_used",
    "data_source", "robots_status", "robots_message"
  )]
  
  cat(sprintf("Total records: %d\n", nrow(consolidated_raw)))
  cat(sprintf("Valid records (with names): %d\n", sum(!is.na(consolidated_raw$executive_name))))
  cat(sprintf("Failed records: %d\n", sum(is.na(consolidated_raw$executive_name))))
  cat(sprintf("Across %d hospitals\n\n", length(unique(consolidated_raw$FAC))))
  
} else {
  consolidated_raw <- data.frame()
  cat("No records extracted\n\n")
}

# =============================================================================
# GENERATE SUMMARY REPORT
# =============================================================================

cat("╔════════════════════════════════════════════════╗\n")
cat("║         API EXTRACTION SUMMARY                 ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# Create summary by hospital
if (nrow(consolidated_raw) > 0) {
  summary_by_hospital <- consolidated_raw %>%
    group_by(FAC, hospital_name) %>%
    summarize(
      records = n(),
      valid = sum(!is.na(executive_name)),
      status = ifelse(any(is.na(executive_name)), "partial/failed", "success"),
      .groups = "drop"
    ) %>%
    as.data.frame()
  
  print(summary_by_hospital, row.names = FALSE)
}

cat("\n")
cat("OVERALL STATISTICS\n")
cat("═════════════════════════════════════════════════\n")

successful <- sum(sapply(extraction_results, function(r) r$success))
failed <- sum(!sapply(extraction_results, function(r) r$success))
total_cost <- sum(sapply(extraction_results, function(r) {
  ifelse(r$success, r$api_cost_estimate, 0)
}))

cat(sprintf("Total Hospitals:       %d\n", length(extraction_results)))
cat(sprintf("Successful:            %d (%.0f%%)\n",
           successful, successful / length(extraction_results) * 100))
cat(sprintf("Failed:                %d (%.0f%%)\n",
           failed, failed / length(extraction_results) * 100))
cat(sprintf("Total Records:         %d\n", nrow(consolidated_raw)))
cat(sprintf("Valid Records:         %d\n", sum(!is.na(consolidated_raw$executive_name))))
cat(sprintf("Avg per Hospital:      %.1f\n", 
           sum(!is.na(consolidated_raw$executive_name)) / successful))
cat(sprintf("Total API Cost:        $%.4f\n", total_cost))
cat(sprintf("Processing Time:       %.1f seconds\n", total_time))

cat("\n")

# =============================================================================
# SAVE RESULTS IN STANDARDIZED RAW FORMAT
# =============================================================================

cat("Saving results...\n")
cat("═════════════════════════════════════════════════\n")

# Save standardized raw data (matches pattern_based_scraper output)
output_file <- file.path(
  output_dir,
  sprintf("api_executives_%s.csv", date_tag)
)
write.csv(consolidated_raw, output_file, row.names = FALSE)
cat(sprintf("✓ Raw data saved: %s\n", basename(output_file)))
cat(sprintf("  Format: Standardized raw (ready to merge with pattern scraper)\n"))
cat(sprintf("  Columns: FAC, hospital_name, hospital_type, executive_name, executive_title,\n"))
cat(sprintf("           date_gathered, source_url, pattern_used, data_source,\n"))
cat(sprintf("           robots_status, robots_message\n"))

# Save extraction summary
summary_file <- file.path(
  output_dir,
  sprintf("api_extraction_summary_%s.csv", date_tag)
)
if (exists("summary_by_hospital") && nrow(summary_by_hospital) > 0) {
  write.csv(summary_by_hospital, summary_file, row.names = FALSE)
  cat(sprintf("✓ Summary saved: %s\n", basename(summary_file)))
}

# Save detailed log (JSON format for debugging)
log_file <- file.path(
  output_dir,
  sprintf("api_extraction_log_%s.json", date_tag)
)

log_data <- lapply(extraction_results, function(r) {
  list(
    fac = r$fac,
    filename = r$filename,
    success = r$success,
    executives_count = ifelse(r$success, nrow(r$executives), NA),
    api_cost = ifelse(r$success, r$api_cost_estimate, NA),
    error = ifelse(!r$success, r$error_message, NA),
    timestamp = as.character(r$timestamp)
  )
})

write(toJSON(log_data, pretty = TRUE, auto_unbox = TRUE), log_file)
cat(sprintf("✓ Detailed log saved: %s\n\n", basename(log_file)))

# =============================================================================
# DISPLAY SAMPLE OF EXTRACTED DATA
# =============================================================================

if (nrow(consolidated_raw) > 0) {
  cat("SAMPLE OF EXTRACTED DATA (First 10 valid records):\n")
  cat("═════════════════════════════════════════════════\n")
  valid_records <- consolidated_raw[!is.na(consolidated_raw$executive_name), ]
  sample_rows <- min(10, nrow(valid_records))
  if (sample_rows > 0) {
    print(head(valid_records[, c("FAC", "hospital_name", "executive_name", "executive_title")], sample_rows))
  }
  cat("\n")
}

# =============================================================================
# FINAL STATUS
# =============================================================================

cat("╔════════════════════════════════════════════════╗\n")
cat("║              EXTRACTION COMPLETE               ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

if (failed == 0) {
  cat("✓ EXCELLENT: All extractions successful!\n")
  cat("✓ Data is in standardized raw format.\n")
  cat("✓ Ready to merge with pattern_based_scraper output.\n")
} else if (failed <= length(extraction_results) * 0.2) {
  cat("✓ GOOD: Most extractions successful.\n")
  cat("⚠ Review failed extractions in log file.\n")
} else {
  cat("⚠ NEEDS REVIEW: Multiple extractions failed.\n")
  cat("⚠ Review detailed logs before merging.\n")
}

cat("\n")
cat("OUTPUT FILES:\n")
cat(sprintf("  - Raw data: %s\n", basename(output_file)))
cat(sprintf("  - Summary: %s\n", basename(summary_file)))
cat(sprintf("  - Log: %s\n", basename(log_file)))

cat("\nNEXT STEP:\n")
cat("  Run append_raw_data.R to merge with pattern_based_scraper output\n")

cat("\n✓ Step 2 complete!\n\n")

# Return consolidated data for further analysis
invisible(list(
  raw_data = consolidated_raw,
  summary = if (exists("summary_by_hospital")) summary_by_hospital else NULL,
  results = extraction_results
))
