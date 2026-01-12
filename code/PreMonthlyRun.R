project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}
# =============================================================================
# PRE-MONTHLY RUN VALIDATION SCRIPT
# Checks YAML for hospitals requiring manual verification
# and outputs a "Hospitals_to_be_captured.rds file for consumption by
# the step1_screenshot_capture.R
# =============================================================================

library(yaml)
library(dplyr)
library(tibble)

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("              PRE-MONTHLY RUN VALIDATION CHECK                 \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Load YAML
yaml_path <- "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml"
config <- yaml::read_yaml(yaml_path)

# Initialize tracking lists
missing_people_hospitals <- list()
manual_entry_hospitals <- list()
api_screenshot_hospitals <- list()

# Scan all hospitals
for (i in seq_along(config$hospitals)) {
  h <- config$hospitals[[i]]
  
  # Check for missing people status
  if (!is.null(h$data_status) && 
      h$data_status == "pattern_based_scraper_missing_people") {
    
    # Extract missing people details
    missing_people <- list()
    if (!is.null(h$html_structure$missing_people)) {
      for (person in h$html_structure$missing_people) {
        missing_people[[length(missing_people) + 1]] <- list(
          name = person$name,
          title = person$title,
          reason = person$reason %||% "Not specified"
        )
      }
    }
    
    missing_people_hospitals[[length(missing_people_hospitals) + 1]] <- list(
      FAC = h$FAC,
      name = h$name,
      url = h$url,
      missing_count = length(missing_people),
      missing_people = missing_people
    )
  }
  
  # Check for manual entry required
  if (!is.null(h$data_status) && h$data_status == "manual_entry_required") {
    exec_count <- 0
    if (!is.null(h$known_executives)) {
      exec_count <- length(h$known_executives)
    }
    
    manual_entry_hospitals[[length(manual_entry_hospitals) + 1]] <- list(
      FAC = h$FAC,
      name = h$name,
      url = h$url,
      known_exec_count = exec_count
    )
  }
  
  # Check for API screenshot
  if (!is.null(h$data_status) && h$data_status == "api_screenshot") {
    api_screenshot_hospitals[[length(api_screenshot_hospitals) + 1]] <- list(
      FAC = h$FAC,
      name = h$name,
      url = h$url,
      expected = h$expected_executives %||% "Not specified"
    )
  }
}

# ============================================================================
# REPORT 1: HOSPITALS WITH MISSING PEOPLE
# ============================================================================

cat("\n")
cat("───────────────────────────────────────────────────────────────\n")
cat("REPORT 1: PATTERN-BASED SCRAPERS WITH MISSING PEOPLE\n")
cat("───────────────────────────────────────────────────────────────\n\n")

if (length(missing_people_hospitals) == 0) {
  cat("✓ No hospitals have missing_people status\n\n")
} else {
  cat(sprintf("⚠ Found %d hospitals with missing people that need monthly verification\n\n",
              length(missing_people_hospitals)))
  
  for (i in seq_along(missing_people_hospitals)) {
    h <- missing_people_hospitals[[i]]
    cat(sprintf("[%d] FAC-%s: %s\n", i, h$FAC, h$name))
    cat(sprintf("    URL: %s\n", h$url))
    cat(sprintf("    Missing: %d person(s)\n", h$missing_count))
    
    if (h$missing_count > 0) {
      cat("    Names to verify:\n")
      for (person in h$missing_people) {
        cat(sprintf("      • %s - %s\n", person$name, person$title))
        cat(sprintf("        Reason: %s\n", person$reason))
      }
    }
    cat("\n")
  }
  
  cat("ACTION REQUIRED:\n")
  cat("  1. Visit each URL above\n")
  cat("  2. Verify if the missing people are still listed\n")
  cat("  3. Check if their titles have changed\n")
  cat("  4. Note any departures or new arrivals\n")
  cat("  5. Update master reference file manually\n\n")
}

# ============================================================================
# REPORT 2: MANUAL ENTRY REQUIRED HOSPITALS
# ============================================================================

cat("\n")
cat("───────────────────────────────────────────────────────────────\n")
cat("REPORT 2: HOSPITALS REQUIRING FULL MANUAL ENTRY\n")
cat("───────────────────────────────────────────────────────────────\n\n")

if (length(manual_entry_hospitals) == 0) {
  cat("✓ No hospitals require manual entry\n\n")
} else {
  cat(sprintf("⚠ Found %d hospitals requiring manual data entry\n\n",
              length(manual_entry_hospitals)))
  
  for (i in seq_along(manual_entry_hospitals)) {
    h <- manual_entry_hospitals[[i]]
    cat(sprintf("[%d] FAC-%s: %s\n", i, h$FAC, h$name))
    cat(sprintf("    URL: %s\n", h$url))
    cat(sprintf("    Known executives: %d\n\n", h$known_exec_count))
  }
  
  cat("ACTION REQUIRED:\n")
  cat("  These hospitals will NOT be processed by automated scraper\n")
  cat("  Manual entry will be needed during monthly collection\n\n")
}

# ============================================================================
# REPORT 3: API SCREENSHOT HOSPITALS
# ============================================================================

cat("\n")
cat("───────────────────────────────────────────────────────────────\n")
cat("REPORT 3: API SCREENSHOT EXTRACTION HOSPITALS\n")
cat("───────────────────────────────────────────────────────────────\n\n")

if (length(api_screenshot_hospitals) == 0) {
  cat("✓ No hospitals configured for API screenshot extraction\n\n")
} else {
  cat(sprintf("ℹ Found %d hospitals using API screenshot method\n\n",
              length(api_screenshot_hospitals)))
  
  for (i in seq_along(api_screenshot_hospitals)) {
    h <- api_screenshot_hospitals[[i]]
    cat(sprintf("[%d] FAC-%s: %s\n", i, h$FAC, h$name))
    cat(sprintf("    URL: %s\n", h$url))
    cat(sprintf("    Expected executives: %s\n\n", h$expected))
  }
  
  cat("INFO:\n")
  cat("  These hospitals will be processed via screenshot + Claude API\n")
  cat("  Ensure API credentials are configured before monthly run\n\n")
}

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("                         SUMMARY                                \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

total_hospitals <- length(config$hospitals)
needs_attention <- length(missing_people_hospitals) + length(manual_entry_hospitals)

cat(sprintf("Total hospitals configured: %d\n", total_hospitals))
cat(sprintf("  • Pattern-based (automatic): %d\n", 
            total_hospitals - needs_attention - length(api_screenshot_hospitals)))
cat(sprintf("  • Pattern-based (missing people): %d ⚠\n", 
            length(missing_people_hospitals)))
cat(sprintf("  • API screenshot: %d\n", length(api_screenshot_hospitals)))
cat(sprintf("  • Manual entry required: %d ⚠\n", length(manual_entry_hospitals)))
cat(sprintf("\nTotal requiring manual attention: %d\n", needs_attention))

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("                  PRE-RUN CHECK COMPLETE                        \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Return summary invisibly
invisible(list(
  total = total_hospitals,
  missing_people = length(missing_people_hospitals),
  manual_entry = length(manual_entry_hospitals),
  api_screenshot = length(api_screenshot_hospitals),
  missing_people_list = missing_people_hospitals,
  manual_entry_list = manual_entry_hospitals,
  api_screenshot_list = api_screenshot_hospitals
))
library(tidyverse)
library(purrr)
str(api_screenshot_hospitals)
hospital_tbl <- purrr::map_dfr(api_screenshot_hospitals, tibble::as_tibble) %>%
  select(FAC,name,url)
saveRDS(hospital_tbl,"E:/ExecutiveSearchYaml/temp/hospitals_to_capture.rds")
purrr::map(api_screenshot_hospitals, ~ class(.x$expected))
