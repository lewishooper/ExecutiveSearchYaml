# =============================================================================
# PILOT BATCH TEST - 2-3 HOSPITALS
# Tests multiple hospitals to validate pipeline consistency
# =============================================================================

# Load all functions
source("E:/ExecutiveSearchYaml/code/screenshot_capture_function_v2.R")
source("E:/ExecutiveSearchYaml/code/api_extraction_function.R")
source("E:/ExecutiveSearchYaml/code/validation_function.R")

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║        PILOT BATCH TEST - MULTIPLE HOSPITALS       ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# =============================================================================
# DEFINE TEST HOSPITALS
# =============================================================================

# Select 2-3 hospitals from your manual_entry_required list
# These should be JavaScript-blocked or otherwise problematic hospitals
test_hospitals <- data.frame(
  FAC = c("927", "966", "974"),
  name = c(
    "Toronto Mount Sinai",
    "Sarnia Bluewater Health", 
    "North Bay Regional Health Centre"
  ),
  url = c(
    "https://www.sinaihealth.ca/about/leadership/",
    "https://www.bluewaterhealth.ca/about/leadership",
    "https://www.nbrhc.on.ca/about-us/leadership-team"
  ),
  expected_count = c(12, 8, 10),  # Approximate expected counts
  stringsAsFactors = FALSE
)

cat("Testing", nrow(test_hospitals), "hospitals:\n")
for (i in 1:nrow(test_hospitals)) {
  cat(sprintf("  %d. FAC-%s: %s\n", i, test_hospitals$FAC[i], test_hospitals$name[i]))
}
cat("\n")

# =============================================================================
# PROCESS EACH HOSPITAL
# =============================================================================

all_results <- list()
start_time <- Sys.time()

for (i in 1:nrow(test_hospitals)) {
  
  hospital <- test_hospitals[i, ]
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat(sprintf("HOSPITAL %d of %d: FAC-%s\n", i, nrow(test_hospitals), hospital$FAC))
  cat(sprintf("Name: %s\n", hospital$name))
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  result <- list(
    fac = hospital$FAC,
    name = hospital$name,
    url = hospital$url,
    expected_count = hospital$expected_count
  )
  
  # ─────────────────────────────────────────────────────────────────────
  # STEP 1: SCREENSHOT
  # ─────────────────────────────────────────────────────────────────────
  
  cat("STEP 1: Screenshot Capture\n")
  cat("───────────────────────────────────────────────────────────────────\n")
  
  screenshot_result <- capture_hospital_screenshot(
    url = hospital$url,
    delay = 6,
    verbose = TRUE
  )
  
  result$screenshot_success <- screenshot_result$success
  result$screenshot_file <- screenshot_result$output_file
  result$screenshot_size_kb <- round(screenshot_result$file_size / 1024, 1)
  
  if (!screenshot_result$success) {
    cat("\n✗ Screenshot failed - skipping this hospital\n")
    result$extraction_success <- FALSE
    result$validation_success <- FALSE
    result$error <- screenshot_result$error_message
    all_results[[i]] <- result
    next
  }
  
  cat(sprintf("✓ Screenshot: %s (%.1f KB)\n\n", 
             basename(screenshot_result$output_file),
             result$screenshot_size_kb))
  
  # ─────────────────────────────────────────────────────────────────────
  # STEP 2: API EXTRACTION
  # ─────────────────────────────────────────────────────────────────────
  
  cat("STEP 2: API Extraction\n")
  cat("───────────────────────────────────────────────────────────────────\n")
  
  extraction_result <- extract_executives_from_screenshot(
    screenshot_file = screenshot_result$output_file,
    verbose = TRUE
  )
  
  result$extraction_success <- extraction_result$success
  
  if (!extraction_result$success) {
    cat("\n✗ Extraction failed - skipping validation\n")
    result$validation_success <- FALSE
    result$error <- extraction_result$error_message
    all_results[[i]] <- result
    next
  }
  
  result$executives_extracted <- nrow(extraction_result$executives)
  result$api_cost <- extraction_result$api_cost_estimate
  result$executives_data <- extraction_result$executives
  
  cat(sprintf("✓ Extracted: %d executives\n", result$executives_extracted))
  cat(sprintf("✓ API Cost: $%.4f\n\n", result$api_cost))
  
  cat("Executives Found:\n")
  print(extraction_result$executives)
  cat("\n")
  
  # ─────────────────────────────────────────────────────────────────────
  # STEP 3: VALIDATION
  # ─────────────────────────────────────────────────────────────────────
  
  cat("STEP 3: Validation\n")
  cat("───────────────────────────────────────────────────────────────────\n")
  
  validation_result <- validate_extracted_executives(
    executives_df = extraction_result$executives,
    expected_count = hospital$expected_count,
    hospital_name = hospital$name,
    verbose = TRUE
  )
  
  result$validation_success <- validation_result$valid
  result$quality_score <- validation_result$quality_score
  result$valid_records <- validation_result$summary$valid_records
  result$issues_count <- length(validation_result$issues)
  result$warnings_count <- length(validation_result$warnings)
  result$validation_details <- validation_result
  
  cat("\n")
  
  # Store result
  all_results[[i]] <- result
  
  # Brief pause between hospitals
  if (i < nrow(test_hospitals)) {
    cat("\nPausing 5 seconds before next hospital...\n")
    Sys.sleep(5)
  }
}

end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# =============================================================================
# GENERATE COMPARISON REPORT
# =============================================================================

cat("\n\n")
cat("╔═══════════════════════════════════════════════════════════════════╗\n")
cat("║                    PILOT BATCH TEST RESULTS                       ║\n")
cat("╚═══════════════════════════════════════════════════════════════════╝\n\n")

# Summary table
summary_df <- do.call(rbind, lapply(all_results, function(r) {
  data.frame(
    FAC = r$fac,
    Hospital = substr(r$name, 1, 30),
    Screenshot = ifelse(r$screenshot_success, "✓", "✗"),
    Extraction = ifelse(r$extraction_success, "✓", "✗"),
    Validation = ifelse(r$validation_success, "✓", "✗"),
    Execs = ifelse(r$extraction_success, r$executives_extracted, NA),
    Expected = r$expected_count,
    Quality = ifelse(r$validation_success, sprintf("%.0f", r$quality_score), "N/A"),
    stringsAsFactors = FALSE
  )
}))

cat("SUMMARY TABLE\n")
cat("═══════════════════════════════════════════════════════════════════\n")
print(summary_df, row.names = FALSE)
cat("\n")

# Overall statistics
successful_screenshots <- sum(sapply(all_results, function(r) r$screenshot_success))
successful_extractions <- sum(sapply(all_results, function(r) r$extraction_success))
successful_validations <- sum(sapply(all_results, function(r) r$validation_success))

cat("OVERALL STATISTICS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat(sprintf("Total Hospitals Tested:      %d\n", length(all_results)))
cat(sprintf("Screenshot Success Rate:     %d / %d (%.0f%%)\n", 
           successful_screenshots, length(all_results),
           successful_screenshots / length(all_results) * 100))
cat(sprintf("Extraction Success Rate:     %d / %d (%.0f%%)\n",
           successful_extractions, length(all_results),
           successful_extractions / length(all_results) * 100))
cat(sprintf("Validation Success Rate:     %d / %d (%.0f%%)\n",
           successful_validations, length(all_results),
           successful_validations / length(all_results) * 100))

# Calculate averages for successful extractions
if (successful_extractions > 0) {
  avg_execs <- mean(sapply(all_results, function(r) {
    if (r$extraction_success) r$executives_extracted else NA
  }), na.rm = TRUE)
  
  avg_quality <- mean(sapply(all_results, function(r) {
    if (r$validation_success) r$quality_score else NA
  }), na.rm = TRUE)
  
  total_cost <- sum(sapply(all_results, function(r) {
    if (r$extraction_success) r$api_cost else 0
  }))
  
  cat(sprintf("\nAverage Executives Found:    %.1f\n", avg_execs))
  cat(sprintf("Average Quality Score:       %.0f / 100\n", avg_quality))
  cat(sprintf("Total API Cost:              $%.4f\n", total_cost))
}

cat(sprintf("Total Processing Time:       %.1f seconds\n", total_time))
cat(sprintf("Average Time per Hospital:   %.1f seconds\n", total_time / length(all_results)))

cat("\n")

# Detailed issues summary
cat("ISSUES & WARNINGS SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════════\n")

has_issues <- FALSE
for (i in 1:length(all_results)) {
  r <- all_results[[i]]
  if (!is.null(r$validation_details)) {
    if (r$issues_count > 0 || r$warnings_count > 0) {
      has_issues <- TRUE
      cat(sprintf("\nFAC-%s (%s):\n", r$fac, r$name))
      cat(sprintf("  Quality Score: %.0f / 100\n", r$quality_score))
      cat(sprintf("  Issues: %d | Warnings: %d\n", r$issues_count, r$warnings_count))
      
      if (r$issues_count > 0) {
        cat("  Critical Issues:\n")
        for (issue in r$validation_details$issues) {
          cat(sprintf("    ✗ %s\n", issue))
        }
      }
      
      if (r$warnings_count > 0 && r$warnings_count <= 3) {
        cat("  Warnings:\n")
        for (warning in r$validation_details$warnings) {
          cat(sprintf("    ⚠ %s\n", warning))
        }
      }
    }
  }
}

if (!has_issues) {
  cat("✓ No significant issues or warnings across all hospitals!\n")
}

cat("\n")

# Quality distribution
if (successful_validations > 0) {
  cat("QUALITY SCORE DISTRIBUTION\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  
  excellent <- sum(sapply(all_results, function(r) {
    if (r$validation_success && r$quality_score >= 90) 1 else 0
  }))
  
  good <- sum(sapply(all_results, function(r) {
    if (r$validation_success && r$quality_score >= 75 && r$quality_score < 90) 1 else 0
  }))
  
  fair <- sum(sapply(all_results, function(r) {
    if (r$validation_success && r$quality_score >= 60 && r$quality_score < 75) 1 else 0
  }))
  
  poor <- sum(sapply(all_results, function(r) {
    if (r$validation_success && r$quality_score < 60) 1 else 0
  }))
  
  cat(sprintf("Excellent (90-100): %d\n", excellent))
  cat(sprintf("Good (75-89):       %d\n", good))
  cat(sprintf("Fair (60-74):       %d\n", fair))
  cat(sprintf("Poor (<60):         %d\n", poor))
  cat("\n")
}

# Final assessment
cat("═══════════════════════════════════════════════════════════════════\n")
cat("PILOT TEST ASSESSMENT\n")
cat("═══════════════════════════════════════════════════════════════════\n")

if (successful_extractions == length(all_results) && avg_quality >= 80) {
  cat("✓ EXCELLENT: All hospitals processed successfully with high quality.\n")
  cat("✓ Pipeline is ready for full deployment to remaining hospitals.\n")
} else if (successful_extractions >= length(all_results) * 0.8 && avg_quality >= 70) {
  cat("✓ GOOD: Most hospitals processed successfully.\n")
  cat("⚠ Review issues above before full deployment.\n")
} else if (successful_extractions >= length(all_results) * 0.6) {
  cat("⚠ FAIR: Some hospitals had issues.\n")
  cat("⚠ Investigate failures and refine approach before proceeding.\n")
} else {
  cat("✗ POOR: Significant issues detected.\n")
  cat("✗ Debug and resolve issues before continuing.\n")
}

cat("\n")

# Return results for further analysis
invisible(all_results)
