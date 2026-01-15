# =============================================================================
# STEP 1: BATCH SCREENSHOT CAPTURE
# Hybrid Approach - Screenshot Automation with Manual Review
# =============================================================================
#
# Purpose: Capture screenshots for multiple hospitals, save with FAC/date tags
#          User manually reviews, identifies failures, and adds manual screenshots
#
# Author: Skip (with Claude assistance)
# Date: January 9, 2026
# Version: 1.0
#
# =============================================================================

library(webshot2)
library(dplyr)

# Load screenshot function
source("E:/ExecutiveSearchYaml/code/screenshot_capture_function_v2.R")
source("E:/ExecutiveSearchYaml/code/logging_functions.R")
cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   STEP 1: BATCH SCREENSHOT CAPTURE             ║\n")
cat("║   (Manual Review Workflow)                     ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# =============================================================================
# CONFIGURATION
# =============================================================================
# Input file for Hospitals to be captured
hospitals_to_capture<-readRDS("E:/ExecutiveSearchYaml/temp/hospitals_to_capture.rds")
# Output directory for screenshots
screenshot_dir <- "E:/ExecutiveSearchYaml/temp/screenshots"
date_tag <- format(Sys.Date(), "%Y%m%d")

# Create directory if it doesn't exist
if (!dir.exists(screenshot_dir)) {
  dir.create(screenshot_dir, recursive = TRUE)
  cat("Created directory:", screenshot_dir, "\n")
}

# =============================================================================
# DEFINE HOSPITALS TO CAPTURE
# =============================================================================

# OPTION 1: Load from YAML (recommended for production)
# This would read from your enhanced_hospitals.yaml where pattern = "manual_entry_required"


cat("Hospitals to capture:", nrow(hospitals_to_capture), "\n\n")

# Display list
cat("TARGET HOSPITALS:\n")
cat("═════════════════════════════════════════════════\n")
for (i in 1:nrow(hospitals_to_capture)) {
  cat(sprintf("%2d. FAC-%s: %s\n", i, 
             hospitals_to_capture$FAC[i], 
             hospitals_to_capture$name[i]))
}
cat("\n")

# =============================================================================
# CAPTURE SCREENSHOTS
# =============================================================================

cat("Starting screenshot capture...\n")
cat("═════════════════════════════════════════════════\n\n")

capture_results <- list()
start_time <- Sys.time()

for (i in 1:nrow(hospitals_to_capture)) {
  
  hospital <- hospitals_to_capture[i, ]
  
  cat(sprintf("[%d/%d] FAC-%s: %s\n", 
             i, nrow(hospitals_to_capture),
             hospital$FAC, hospital$name))
  cat("─────────────────────────────────────────────────\n")
  
  # Generate filename with FAC and date
  screenshot_file <- file.path(
    screenshot_dir,
    sprintf("FAC-%s_%s.png", hospital$FAC, date_tag)
  )
  
  # Capture screenshot
  result <- capture_hospital_screenshot(
    url = hospital$url,
    output_file = screenshot_file,
    delay = 6,
    verbose = FALSE  # Minimal output during batch
  )
  
  # Store result
  result$FAC <- hospital$FAC
  result$name <- hospital$name
  result$url <- hospital$url
  capture_results[[i]] <- result
  
  # Report status
  if (result$success) {
    cat(sprintf("✓ SUCCESS: %s (%.1f KB)\n", 
               basename(result$output_file),
               result$file_size / 1024))
  } else {
    cat(sprintf("✗ FAILED: %s\n", result$error_message))
  }
  
  cat("\n")
  
  # Brief pause between hospitals
  if (i < nrow(hospitals_to_capture)) {
    Sys.sleep(2)
  }
}

end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# =============================================================================
# GENERATE SUMMARY REPORT
# =============================================================================

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║           SCREENSHOT CAPTURE SUMMARY           ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# Create summary data frame
summary_df <- do.call(rbind, lapply(capture_results, function(r) {
  data.frame(
    FAC = r$FAC,
    Hospital = substr(r$name, 1, 35),
    Status = ifelse(r$success, "✓", "✗"),
    File_KB = ifelse(r$success, round(r$file_size / 1024, 1), NA),
    Filename = ifelse(r$success, basename(r$output_file), "FAILED"),
    Error = ifelse(!r$success, substr(r$error_message, 1, 40), ""),
    stringsAsFactors = FALSE
  )
}))

print(summary_df, row.names = FALSE)

cat("\n")
cat("STATISTICS\n")
cat("═════════════════════════════════════════════════\n")

successful <- sum(sapply(capture_results, function(r) r$success))
failed <- sum(!sapply(capture_results, function(r) r$success))

cat(sprintf("Total Attempted:       %d\n", nrow(hospitals_to_capture)))
cat(sprintf("Successful Captures:   %d (%.0f%%)\n", 
           successful, successful / nrow(hospitals_to_capture) * 100))
cat(sprintf("Failed Captures:       %d (%.0f%%)\n",
           failed, failed / nrow(hospitals_to_capture) * 100))
cat(sprintf("Total Time:            %.1f seconds\n", total_time))
cat(sprintf("Avg Time per Hospital: %.1f seconds\n", 
           total_time / nrow(hospitals_to_capture)))

cat("\n")

# List failed hospitals
if (failed > 0) {
  cat("FAILED CAPTURES (Require Manual Review)\n")
  cat("═════════════════════════════════════════════════\n")
  for (r in capture_results) {
    if (!r$success) {
      cat(sprintf("✗ FAC-%s (%s)\n", r$FAC, r$name))
      cat(sprintf("  URL: %s\n", r$url))
      cat(sprintf("  Error: %s\n", r$error_message))
      cat(sprintf("  Action: Manually capture screenshot and save as: FAC-%s_%s.png\n", 
                 r$FAC, date_tag))
      cat("\n")
    }
  }
}

# =============================================================================
# SAVE CAPTURE LOG
# =============================================================================

# Save detailed log
log_file <- file.path(screenshot_dir, sprintf("capture_log_%s.csv", date_tag))
write.csv(summary_df, log_file, row.names = FALSE)
cat(sprintf("Capture log saved: %s\n\n", log_file))

# =============================================================================
# MANUAL REVIEW INSTRUCTIONS
# =============================================================================

cat("╔════════════════════════════════════════════════╗\n")
cat("║         NEXT STEP: MANUAL REVIEW               ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("INSTRUCTIONS:\n")
cat("═════════════════════════════════════════════════\n")
cat("1. Open screenshot folder:\n")
cat(sprintf("   %s\n\n", screenshot_dir))

cat("2. Review EACH screenshot:\n")
cat("   ✓ Page loaded completely?\n")
cat("   ✓ Executive names visible?\n")
cat("   ✓ Titles visible?\n")
cat("   ✓ No popups/banners blocking content?\n\n")

cat("3. For FAILED captures:\n")
cat("   - Open URL in browser\n")
cat("   - Take manual screenshot (Windows: Win+Shift+S)\n")
cat("   - Save as: FAC-XXX_YYYYMMDD.png\n")
cat("   - Place in screenshots folder\n\n")

cat("4. For POOR QUALITY captures:\n")
cat("   - Delete the file\n")
cat("   - Take manual screenshot\n")
cat("   - Save with same filename format\n\n")

cat("5. When all screenshots reviewed and complete:\n")
cat("   - Run STEP 2 script for API extraction\n")
cat("   - Script will process ALL .png files in folder\n\n")

# =============================================================================
# CREATE REVIEW CHECKLIST
# =============================================================================

checklist_file <- file.path(screenshot_dir, sprintf("review_checklist_%s.txt", date_tag))

checklist_content <- sprintf("
SCREENSHOT REVIEW CHECKLIST - %s
═══════════════════════════════════════════════════════════════

Total Screenshots: %d
Successful Captures: %d
Failed Captures: %d

REVIEW EACH FILE:
─────────────────────────────────────────────────────────────────
", date_tag, nrow(hospitals_to_capture), successful, failed)
for (r in capture_results) {
  checklist_content <- paste0(checklist_content, sprintf("
[ ] FAC-%s: %s
    URL: %s
    File: FAC-%s_%s.png
    Status: %s
    %s
    Notes: _____________________________________________
", r$FAC, r$name, r$url, r$FAC, date_tag, 
                                                         ifelse(r$success, "AUTO-CAPTURED", "NEEDS MANUAL CAPTURE"),
                                                         ifelse(r$success, 
                                                                sprintf("Size: %.1f KB", r$file_size / 1024),
                                                                sprintf("Error: %s", r$error_message))))
}

checklist_content <- paste0(checklist_content, "
─────────────────────────────────────────────────────────────────

COMPLETION CHECKLIST:
[ ] All screenshots reviewed
[ ] All failed captures replaced with manual screenshots
[ ] All poor quality screenshots replaced
[ ] All files follow naming convention: FAC-XXX_YYYYMMDD.png
[ ] Ready to run STEP 2: API extraction

Date Reviewed: _______________
Reviewed By: _______________
")

writeLines(checklist_content, checklist_file)
cat(sprintf("Review checklist saved: %s\n\n", checklist_file))

# =============================================================================
# OPEN FOLDER FOR REVIEW
# =============================================================================

cat("Opening screenshot folder for review...\n")
shell.exec(screenshot_dir)

cat("\n✓ Screenshot capture complete!\n")
cat("✓ Review screenshots and run Step 2 when ready.\n\n")

# Return results for further analysis
invisible(capture_results)
