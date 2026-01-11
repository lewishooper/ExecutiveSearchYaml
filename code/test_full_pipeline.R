# =============================================================================
# FULL PIPELINE TEST
# Tests all three functions together: Screenshot → API → Validation
# =============================================================================

# Load all three functions
source("E:/ExecutiveSearchYaml/code/screenshot_capture_function_v2.R")
source("E:/ExecutiveSearchYaml/code/api_extraction_function.R")
source("E:/ExecutiveSearchYaml/code/validation_function.R")

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   FULL PIPELINE TEST: SCREENSHOT → API → VALIDATE   ║\n")
cat("╚════════════════════════════════════════════════╝\n")

# Test hospital: Toronto Mount Sinai
test_url <-  " https://www.pemreghos.org/slt"
test_hospital <- "Kenora"
test_fac <- "826"

cat("\nTest Hospital:", test_hospital, "\n")
cat("FAC:", test_fac, "\n")
cat("URL:", test_url, "\n\n")

# ===========================================================================
# STEP 1: CAPTURE SCREENSHOT
# ===========================================================================

cat("═══════════════════════════════════════════════\n")
cat("STEP 1: SCREENSHOT CAPTURE\n")
cat("═══════════════════════════════════════════════\n\n")

screenshot_result <- capture_hospital_screenshot(
  url = test_url,
  delay = 6,
  verbose = TRUE
)

if (!screenshot_result$success) {
  cat("\n✗ PIPELINE FAILED at screenshot capture\n")
  cat("Error:", screenshot_result$error_message, "\n")
  stop("Cannot proceed without screenshot")
}

cat("\n✓ Screenshot capture: SUCCESS\n")
cat("File:", screenshot_result$output_file, "\n")
cat("Size:", round(screenshot_result$file_size / 1024, 1), "KB\n\n")

# ===========================================================================
# STEP 2: API EXTRACTION
# ===========================================================================

cat("═══════════════════════════════════════════════\n")
cat("STEP 2: API EXTRACTION\n")
cat("═══════════════════════════════════════════════\n\n")

extraction_result <- extract_executives_from_screenshot(
  screenshot_file = screenshot_result$output_file,
  verbose = TRUE
)

if (!extraction_result$success) {
  cat("\n✗ PIPELINE FAILED at API extraction\n")
  cat("Error:", extraction_result$error_message, "\n")
  stop("Cannot proceed without extracted data")
}

cat("\n✓ API extraction: SUCCESS\n")
cat("Executives extracted:", nrow(extraction_result$executives), "\n")
cat("API cost:", sprintf("$%.4f", extraction_result$api_cost_estimate), "\n\n")

cat("Extracted Executives:\n")
print(extraction_result$executives)
cat("\n")

# ===========================================================================
# STEP 3: VALIDATION
# ===========================================================================

cat("═══════════════════════════════════════════════\n")
cat("STEP 3: VALIDATION\n")
cat("═══════════════════════════════════════════════\n\n")

validation_result <- validate_extracted_executives(
  executives_df = extraction_result$executives,
  expected_count = 12,  # Adjust based on hospital
  hospital_name = test_hospital,
  verbose = TRUE
)

# ===========================================================================
# FINAL SUMMARY
# ===========================================================================

cat("\n")
cat("╔════════════════════════════════════════════════╗\n")
cat("║              PIPELINE SUMMARY                  ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("Step 1 - Screenshot:  ", ifelse(screenshot_result$success, "✓ PASS", "✗ FAIL"), "\n")
cat("Step 2 - Extraction:  ", ifelse(extraction_result$success, "✓ PASS", "✗ FAIL"), "\n")
cat("Step 3 - Validation:  ", ifelse(validation_result$valid, "✓ PASS", "⚠ ISSUES"), "\n\n")

cat("Results:\n")
cat("  Executives Extracted:  ", nrow(extraction_result$executives), "\n")
cat("  Valid Records:         ", validation_result$summary$valid_records, "\n")
cat("  Quality Score:         ", sprintf("%.0f / 100", validation_result$quality_score), "\n")
cat("  Critical Issues:       ", length(validation_result$issues), "\n")
cat("  Warnings:              ", length(validation_result$warnings), "\n\n")

cat("Costs:\n")
cat("  API Cost:              ", sprintf("$%.4f", extraction_result$api_cost_estimate), "\n")
cat("  Time Elapsed:          ", sprintf("%.1f seconds", 
    as.numeric(difftime(Sys.time(), screenshot_result$timestamp, units = "secs"))), "\n\n")

# Overall assessment
overall_success <- screenshot_result$success && 
                  extraction_result$success && 
                  validation_result$quality_score >= 70

if (overall_success) {
  cat("╔════════════════════════════════════════════════╗\n")
  cat("║         ✓ PIPELINE TEST SUCCESSFUL!           ║\n")
  cat("║                                                ║\n")
  cat("║   All three functions working correctly.      ║\n")
  cat("║   Ready for pilot testing on 3 hospitals!     ║\n")
  cat("╚════════════════════════════════════════════════╝\n\n")
} else {
  cat("╔════════════════════════════════════════════════╗\n")
  cat("║         ⚠ PIPELINE HAS ISSUES                 ║\n")
  cat("║                                                ║\n")
  cat("║   Review validation results above.            ║\n")
  cat("║   May need prompt refinement or debugging.    ║\n")
  cat("╚════════════════════════════════════════════════╝\n\n")
}

# Print detailed validation report
cat("\n")
print_validation_report(validation_result)

# Return results for further analysis
invisible(list(
  screenshot = screenshot_result,
  extraction = extraction_result,
  validation = validation_result,
  overall_success = overall_success
))
