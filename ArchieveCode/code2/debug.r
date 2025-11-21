# Full Phase 2 test
source("pattern_based_scraper.R")
scraper <- PatternBasedScraper()
config <- scraper$load_config("enhanced_hospitals.yaml")

# Run on all hospitals
cat("Running Phase 2 scraper on all hospitals...\n")
results <- scraper$scrape_batch(
  config$hospitals,
  output_folder = "E:/ExecutiveSearchYaml/output"
)

# Compare with baseline
baseline <- read.csv("E:/ExecutiveSearchYaml/output/BaseLineNov62025.csv")
new_results <- results

# Quick comparison
cat("\n=== QUICK COMPARISON ===\n")
cat("Baseline records:", nrow(baseline), "\n")
cat("New records:", nrow(new_results), "\n")
cat("Difference:", nrow(new_results) - nrow(baseline), "\n")

# Check missing people improvements
baseline_na <- sum(is.na(baseline$executive_name))
new_na <- sum(is.na(new_results$executive_name))
cat("\nBaseline missing names:", baseline_na, "\n")
cat("New missing names:", new_na, "\n")
cat("Improvement:", baseline_na - new_na, "\n")
