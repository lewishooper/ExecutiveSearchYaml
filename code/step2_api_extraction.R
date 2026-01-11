# =============================================================================
# STEP 2: BATCH API EXTRACTION FROM SCREENSHOTS
# Hybrid Approach - Extract Executives from Verified Screenshots
# =============================================================================
#
# Purpose: Process all screenshots in folder through Claude API
#          Extract executive names and titles, return consolidated data frame
#
# Author: Skip (with Claude assistance)
# Date: January 9, 2026
# Version: 1.0
#
# =============================================================================

library(httr)
library(jsonlite)
library(base64enc)
library(dplyr)

# Load functions
source("E:/ExecutiveSearchYaml/code/api_extraction_function.R")
source("E:/ExecutiveSearchYaml/code/validation_function.R")

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   STEP 2: BATCH API EXTRACTION                 ║\n")
cat("║   (Process Verified Screenshots)               ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# =============================================================================
# CONFIGURATION
# =============================================================================

# Screenshot directory (from Step 1)
screenshot_dir <- "E:/ExecutiveSearchYaml/temp/screenshots"
date_tag <- format(Sys.Date(), "%Y%m%d")

# Output directory for results
output_dir <- "E:/ExecutiveSearchYaml/processed"
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
cat("✓ Output directory:", output_dir, "\n\n")

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
  cat(sprintf("%2d. FAC-%s: %s (%.1f KB)\n",
             i, info$fac, info$filename,
             file.size(info$filepath) / 1024))
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
all_executives <- list()
start_time <- Sys.time()

for (i in seq_along(file_info)) {
  
  info <- file_info[[i]]
  
  cat(sprintf("[%d/%d] FAC-%s\n", i, length(file_info), info$fac))
  cat("─────────────────────────────────────────────────\n")
  cat(sprintf("File: %s\n", info$filename))
  
  # Extract executives via API
  result <- extract_executives_from_screenshot(
    screenshot_file = info$filepath,
    verbose = FALSE  # Minimal output during batch
  )
  
  # Store result
  result$fac <- info$fac
  result$filename <- info$filename
  result$date_captured <- info$date_captured
  extraction_results[[i]] <- result
  
  # Report status
  if (result$success) {
    cat(sprintf("✓ Extracted %d executives\n", nrow(result$executives)))
    cat(sprintf("  Cost: $%.4f\n", result$api_cost_estimate))
    
    # Add FAC to executives data
    result$executives$FAC <- info$fac
    result$executives$date_captured <- info$date_captured
    result$executives$source_file <- info$filename
    
    all_executives[[i]] <- result$executives
  } else {
    cat(sprintf("✗ Extraction failed: %s\n", result$error_message))
  }
  
  cat("\n")
  
  # Brief pause between API calls
  if (i < length(file_info)) {
    Sys.sleep(2)
  }
}

end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# =============================================================================
# CONSOLIDATE RESULTS
# =============================================================================

cat("═════════════════════════════════════════════════\n")
cat("Consolidating results...\n")
cat("═════════════════════════════════════════════════\n\n")

# Combine all executives into single data frame
if (length(all_executives) > 0) {
  consolidated_executives <- do.call(rbind, all_executives)
  
  # Reorder columns
  consolidated_executives <- consolidated_executives[, c(
    "FAC", "name", "title", "date_captured", "source_file"
  )]
  
  cat(sprintf("Total executives extracted: %d\n", nrow(consolidated_executives)))
  cat(sprintf("Across %d hospitals\n\n", length(unique(consolidated_executives$FAC))))
  
} else {
  consolidated_executives <- data.frame()
  cat("No executives extracted\n\n")
}

# =============================================================================
# GENERATE SUMMARY REPORT
# =============================================================================

cat("╔════════════════════════════════════════════════╗\n")
cat("║         API EXTRACTION SUMMARY                 ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# Create summary by hospital
summary_by_hospital <- do.call(rbind, lapply(extraction_results, function(r) {
  data.frame(
    FAC = r$fac,
    Status = ifelse(r$success, "✓", "✗"),
    Executives = ifelse(r$success, nrow(r$executives), NA),
    Cost = ifelse(r$success, sprintf("$%.4f", r$api_cost_estimate), NA),
    Error = ifelse(!r$success, substr(r$error_message, 1, 40), ""),
    stringsAsFactors = FALSE
  )
}))

print(summary_by_hospital, row.names = FALSE)

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
cat(sprintf("Total Executives:      %d\n", nrow(consolidated_executives)))
cat(sprintf("Avg per Hospital:      %.1f\n", 
           nrow(consolidated_executives) / successful))
cat(sprintf("Total API Cost:        $%.4f\n", total_cost))
cat(sprintf("Processing Time:       %.1f seconds\n", total_time))

cat("\n")

# =============================================================================
# SAVE RESULTS
# =============================================================================

cat("Saving results...\n")
cat("═════════════════════════════════════════════════\n")

# Save consolidated executives
output_file <- file.path(
  output_dir,
  sprintf("executives_extracted_%s.csv", date_tag)
)
write.csv(consolidated_executives, output_file, row.names = FALSE)
cat(sprintf("✓ Executives saved: %s\n", output_file))

# Save extraction summary
summary_file <- file.path(
  output_dir,
  sprintf("extraction_summary_%s.csv", date_tag)
)
write.csv(summary_by_hospital, summary_file, row.names = FALSE)
cat(sprintf("✓ Summary saved: %s\n", summary_file))

# Save detailed log (JSON format for debugging)
log_file <- file.path(
  output_dir,
  sprintf("extraction_log_%s.json", date_tag)
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
cat(sprintf("✓ Detailed log saved: %s\n\n", log_file))

# =============================================================================
# DISPLAY SAMPLE OF EXTRACTED DATA
# =============================================================================

if (nrow(consolidated_executives) > 0) {
  cat("SAMPLE OF EXTRACTED EXECUTIVES (First 10):\n")
  cat("═════════════════════════════════════════════════\n")
  sample_rows <- min(10, nrow(consolidated_executives))
  print(head(consolidated_executives, sample_rows))
  cat("\n")
}

# =============================================================================
# VALIDATION SUMMARY (Optional)
# =============================================================================

if (nrow(consolidated_executives) > 0) {
  cat("QUALITY VALIDATION SUMMARY:\n")
  cat("═════════════════════════════════════════════════\n")
  
  # Run validation on each hospital's data
  validation_summary <- list()
  
  for (fac in unique(consolidated_executives$FAC)) {
    hospital_execs <- consolidated_executives[consolidated_executives$FAC == fac, ]
    
    validation <- validate_extracted_executives(
      executives_df = hospital_execs[, c("name", "title")],
      hospital_name = paste("FAC", fac),
      verbose = FALSE
    )
    
    validation_summary[[fac]] <- list(
      fac = fac,
      count = nrow(hospital_execs),
      quality_score = validation$quality_score,
      valid_records = validation$summary$valid_records,
      issues = length(validation$issues),
      warnings = length(validation$warnings)
    )
  }
  
  # Create validation summary table
  validation_df <- do.call(rbind, lapply(validation_summary, function(v) {
    data.frame(
      FAC = v$fac,
      Count = v$count,
      Valid = v$valid_records,
      Quality = sprintf("%.0f", v$quality_score),
      Issues = v$issues,
      Warnings = v$warnings,
      stringsAsFactors = FALSE
    )
  }))
  
  print(validation_df, row.names = FALSE)
  
  avg_quality <- mean(sapply(validation_summary, function(v) v$quality_score))
  cat(sprintf("\nAverage Quality Score: %.0f / 100\n", avg_quality))
  
  # Save validation summary
  validation_file <- file.path(
    output_dir,
    sprintf("validation_summary_%s.csv", date_tag)
  )
  write.csv(validation_df, validation_file, row.names = FALSE)
  cat(sprintf("✓ Validation summary saved: %s\n", validation_file))
  
  # Save detailed validation reasons for flagged records
  flagged_records <- list()
  for (fac in names(validation_summary)) {
    v <- validation_summary[[fac]]
    if (v$issues > 0 || v$warnings > 0) {
      # Get the validation details for this hospital
      hospital_execs <- consolidated_executives[consolidated_executives$FAC == fac, ]
      hospital_validation <- validate_extracted_executives(
        executives_df = hospital_execs[, c("name", "title")],
        hospital_name = paste("FAC", fac),
        verbose = FALSE
      )
      
      # Extract records with issues
      details <- hospital_validation$validation_details
      flagged <- details[!details$name_valid | !details$title_valid | 
                        !details$has_executive_keyword | details$has_exclude_pattern, ]
      
      if (nrow(flagged) > 0) {
        flagged$FAC <- fac
        flagged_records[[fac]] <- flagged
      }
    }
  }
  
  if (length(flagged_records) > 0) {
    flagged_df <- do.call(rbind, flagged_records)
    flagged_file <- file.path(
      output_dir,
      sprintf("validation_flagged_records_%s.csv", date_tag)
    )
    write.csv(flagged_df, flagged_file, row.names = FALSE)
    cat(sprintf("✓ Flagged records saved: %s\n", flagged_file))
  }
}

cat("\n")

# =============================================================================
# FINAL STATUS
# =============================================================================

cat("╔════════════════════════════════════════════════╗\n")
cat("║              EXTRACTION COMPLETE               ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

if (failed == 0 && avg_quality >= 80) {
  cat("✓ EXCELLENT: All extractions successful with high quality!\n")
  cat("✓ Data is ready for integration into your system.\n")
} else if (failed <= length(extraction_results) * 0.2 && avg_quality >= 70) {
  cat("✓ GOOD: Most extractions successful.\n")
  cat("⚠ Review failed extractions and quality issues.\n")
} else {
  cat("⚠ NEEDS REVIEW: Some extractions had issues.\n")
  cat("⚠ Review detailed logs before using data.\n")
}

cat("\n")
cat("OUTPUT FILES:\n")
cat(sprintf("  - Executives: %s\n", basename(output_file)))
cat(sprintf("  - Summary: %s\n", basename(summary_file)))
cat(sprintf("  - Validation: %s\n", basename(validation_file)))
cat(sprintf("  - Detailed log: %s\n", basename(log_file)))

cat("\n✓ Step 2 complete!\n\n")

# Return consolidated data for further analysis
invisible(list(
  executives = consolidated_executives,
  summary = summary_by_hospital,
  validation = validation_df,
  results = extraction_results
))
