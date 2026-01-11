# =============================================================================
# FULL PRODUCTION RUN - REMAINING HOSPITALS
# Process All Remaining Manual Entry Hospitals
# =============================================================================

# This script is configured to process the remaining manual_entry_required
# hospitals that were NOT included in today's test run.

# =============================================================================
# HOSPITALS ALREADY COMPLETED
# =============================================================================

# These hospitals were completed in today's test:
completed_facs <- c("927", "966", "974")  # Add the other 3 FACs from your test

# =============================================================================
# REMAINING HOSPITALS TO PROCESS
# =============================================================================

# Based on the manual_entry_required list, here are the REMAINING hospitals
# Adjust this list based on which hospitals you actually completed today

remaining_hospitals <- data.frame(
  FAC = c(
    "933",  # Windsor Regional
    "826",  # Kenora Lake of the Woods
    "809",  # Smooth Rock Falls
    "714",  # London St Josephs
    "763",  # Pembroke Regional
    "981",  # Chatham-Kent Health Alliance
    "947",  # Toronto University Health Network
    "850",  # Toronto Runnymede HC
    "927"   # Windsor Hotel Dieu Grace (different from Sinai FAC-927)
  ),
  name = c(
    "Windsor Regional Hospital",
    "Kenora Lake of the Woods",
    "Smooth Rock Falls",
    "London St Josephs",
    "Pembroke Regional",
    "Chatham-Kent Health Alliance",
    "Toronto University Health Network",
    "Toronto Runnymede HC",
    "Windsor Hotel Dieu Grace"
  ),
  url = c(
    "https://www.wrh.on.ca/AboutUs_Leadership.aspx",
    "https://lwdh.on.ca/about-us/leadership-team/",
    "https://www.srhc.on.ca/",
    "https://www.sjhc.london.on.ca/about-us/leadership",
    "https://www.prh.email/about/leadership-team/",
    "https://www.ckha.on.ca/about-ckha/leadership-team",
    "https://www.uhn.ca/corporate/AboutUHN/Leadership",
    "https://www.runnymedehc.ca/about-us/leadership-team/",
    "https://www.hdgh.org/about/leadership-team"
  ),
  expected_count = c(
    8,   # Windsor Regional
    6,   # Kenora
    4,   # Smooth Rock Falls
    12,  # London St Josephs
    6,   # Pembroke
    8,   # Chatham-Kent
    20,  # UHN (very large)
    7,   # Runnymede
    8    # Hotel Dieu Grace
  ),
  stringsAsFactors = FALSE
)

# =============================================================================
# SPECIAL NOTES
# =============================================================================

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   FULL PRODUCTION RUN - REMAINING HOSPITALS    ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("CONFIGURATION:\n")
cat("═════════════════════════════════════════════════\n")
cat("Hospitals already completed:", length(completed_facs), "\n")
cat("Hospitals to process now:", nrow(remaining_hospitals), "\n")
cat("\n")

cat("HOSPITALS TO PROCESS:\n")
cat("═════════════════════════════════════════════════\n")
for (i in 1:nrow(remaining_hospitals)) {
  cat(sprintf("%2d. FAC-%s: %s\n", i, 
             remaining_hospitals$FAC[i],
             remaining_hospitals$name[i]))
}

cat("\n")
cat("SPECIAL NOTES:\n")
cat("═════════════════════════════════════════════════\n")
cat("• FAC-809 (Smooth Rock Falls): URL may need verification\n")
cat("• FAC-947 (UHN): Very large (20+ executives) - may take longer\n")
cat("• FAC-927 appears twice: Mount Sinai vs Hotel Dieu Grace\n")
cat("  (Different hospitals, may share FAC prefix)\n")
cat("\n")

cat("ESTIMATED COSTS:\n")
cat("═════════════════════════════════════════════════\n")
cat(sprintf("Hospitals: %d\n", nrow(remaining_hospitals)))
cat(sprintf("Cost per hospital: $0.003\n"))
cat(sprintf("Estimated total: $%.4f\n", nrow(remaining_hospitals) * 0.003))
cat("\n")

cat("READY TO PROCEED?\n")
cat("═════════════════════════════════════════════════\n")
cat("This will run the FULL production workflow:\n")
cat("1. Step 1: Screenshot capture\n")
cat("2. Manual review (you will do this)\n")
cat("3. Step 2: API extraction\n")
cat("4. Step 3: Data enrichment\n")
cat("\n")

response <- readline("Type 'yes' to proceed or anything else to cancel: ")

if (tolower(trimws(response)) != "yes") {
  cat("\nProduction run cancelled.\n")
  cat("Review hospital list and run again when ready.\n\n")
  stop("User cancelled")
}

# =============================================================================
# RUN STEP 1: SCREENSHOT CAPTURE
# =============================================================================

cat("\n")
cat("╔════════════════════════════════════════════════╗\n")
cat("║   STEP 1: SCREENSHOT CAPTURE                   ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# Load screenshot function
source("E:/ExecutiveSearchYaml/code/screenshot_capture_function_v2.R")

# Output directory
screenshot_dir <- "E:/ExecutiveSearchYaml/temp/screenshots"
date_tag <- format(Sys.Date(), "%Y%m%d")

if (!dir.exists(screenshot_dir)) {
  dir.create(screenshot_dir, recursive = TRUE)
}

# Capture screenshots
cat("Starting screenshot capture...\n")
cat("═════════════════════════════════════════════════\n\n")

capture_results <- list()

for (i in 1:nrow(remaining_hospitals)) {
  hospital <- remaining_hospitals[i, ]
  
  cat(sprintf("[%d/%d] FAC-%s: %s\n", 
             i, nrow(remaining_hospitals),
             hospital$FAC, hospital$name))
  cat("─────────────────────────────────────────────────\n")
  
  screenshot_file <- file.path(
    screenshot_dir,
    sprintf("FAC-%s_%s.png", hospital$FAC, date_tag)
  )
  
  result <- capture_hospital_screenshot(
    url = hospital$url,
    output_file = screenshot_file,
    delay = 6,
    verbose = FALSE
  )
  
  result$FAC <- hospital$FAC
  result$name <- hospital$name
  result$url <- hospital$url
  capture_results[[i]] <- result
  
  if (result$success) {
    cat(sprintf("✓ SUCCESS: %s (%.1f KB)\n", 
               basename(result$output_file),
               result$file_size / 1024))
  } else {
    cat(sprintf("✗ FAILED: %s\n", result$error_message))
  }
  
  cat("\n")
  Sys.sleep(2)
}

# Summary
successful <- sum(sapply(capture_results, function(r) r$success))
failed <- sum(!sapply(capture_results, function(r) r$success))

cat("╔════════════════════════════════════════════════╗\n")
cat("║   SCREENSHOT CAPTURE COMPLETE                  ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat(sprintf("Successful: %d / %d (%.0f%%)\n", 
           successful, nrow(remaining_hospitals),
           successful / nrow(remaining_hospitals) * 100))
cat(sprintf("Failed: %d\n\n", failed))

if (failed > 0) {
  cat("FAILED CAPTURES (Require Manual Screenshots):\n")
  cat("═════════════════════════════════════════════════\n")
  for (r in capture_results) {
    if (!r$success) {
      cat(sprintf("✗ FAC-%s (%s)\n", r$FAC, r$name))
      cat(sprintf("  Save as: FAC-%s_%s.png\n", r$FAC, date_tag))
    }
  }
  cat("\n")
}

# Open folder for review
cat("Opening screenshot folder for manual review...\n")
shell.exec(screenshot_dir)

cat("\n")
cat("═════════════════════════════════════════════════\n")
cat("NEXT STEPS:\n")
cat("═════════════════════════════════════════════════\n")
cat("1. Review ALL screenshots in the opened folder\n")
cat("2. Replace any failed or poor quality screenshots\n")
cat("3. When all screenshots are verified, return here\n")
cat("4. We will proceed to Step 2 (API extraction)\n")
cat("\n")

readline("Press ENTER when manual review is complete...")

# =============================================================================
# RUN STEP 2: API EXTRACTION
# =============================================================================

cat("\n")
cat("╔════════════════════════════════════════════════╗\n")
cat("║   STEP 2: API EXTRACTION                       ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("Proceeding with API extraction...\n")
cat("This will process ALL .png files in the screenshot folder.\n\n")

response2 <- readline("Type 'yes' to proceed: ")

if (tolower(trimws(response2)) != "yes") {
  cat("\nStopped before API extraction.\n")
  cat("Run Step 2 manually when ready:\n")
  cat("  source('E:/ExecutiveSearchYaml/code/step2_api_extraction.R')\n\n")
  stop("User stopped before API extraction")
}

# Run Step 2
source("E:/ExecutiveSearchYaml/code/step2_api_extraction.R")

# =============================================================================
# RUN STEP 3: DATA ENRICHMENT
# =============================================================================

cat("\n")
cat("Proceeding to Step 3...\n")
readline("Press ENTER to continue to data enrichment...")

# Run Step 3
source("E:/ExecutiveSearchYaml/code/step3_data_enrichment.R")

# =============================================================================
# PRODUCTION RUN COMPLETE
# =============================================================================

cat("\n")
cat("╔════════════════════════════════════════════════╗\n")
cat("║   FULL PRODUCTION RUN COMPLETE!                ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("OUTPUTS CREATED:\n")
cat("═════════════════════════════════════════════════\n")
cat("Processed data:\n")
cat("  E:/ExecutiveSearchYaml/processed/\n")
cat("    - executives_extracted_YYYYMMDD.csv\n")
cat("    - extraction_summary_YYYYMMDD.csv\n")
cat("    - validation_summary_YYYYMMDD.csv\n")
cat("\n")
cat("Enriched data:\n")
cat("  E:/ExecutiveSearchYaml/output/\n")
cat("    - enriched_executives_YYYYMMDD.csv\n")
cat("    - new_executives_YYYYMMDD.csv (if any)\n")
cat("    - departed_executives_YYYYMMDD.csv (if any)\n")
cat("\n")

cat("NEXT STEPS:\n")
cat("═════════════════════════════════════════════════\n")
cat("1. Review all output files\n")
cat("2. Verify quality scores are acceptable\n")
cat("3. Update YAML file (see: yaml_update_guide.md)\n")
cat("4. Integrate enriched data into master database\n")
cat("5. Archive this month's run\n")
cat("\n")

cat("✓ Production run complete!\n\n")
