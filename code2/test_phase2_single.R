# Test Phase 2 changes with a single hospital
library(rvest)
library(dplyr)
library(stringr)
library(yaml)

# Load the updated scraper
source("pattern_based_scraper.R")
scraper <- PatternBasedScraper()

# Load config
config <- scraper$load_config("enhanced_hospitals.yaml")

# Test with FAC 969 (Ontario Shores - has known issue)
hospital_969 <- config$hospitals[[which(sapply(config$hospitals, function(h) h$FAC == "969"))]]

cat("\n=== TESTING FAC 969 - Ontario Shores ===\n")
cat("Expected issue: Daniel Mueller title not recognized\n")
cat("Expected solution: Hospital override with additional keywords\n\n")

result <- scraper$scrape_hospital(hospital_969)

cat("\n=== RESULTS ===\n")
print(result)

cat("\n=== CHECKING FOR OVERRIDES ===\n")
fac_key <- "FAC_969"
if (!is.null(config$hospital_overrides[[fac_key]])) {
  cat("Overrides found for FAC 969:\n")
  print(config$hospital_overrides[[fac_key]])
} else {
  cat("No overrides found for FAC 969\n")
}
Run:
  source("test_phase2_single.R")
