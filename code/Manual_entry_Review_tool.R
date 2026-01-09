project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}

library(yaml)
library(dplyr)

# Load YAML
hospitals <- read_yaml("code/enhanced_hospitals.yaml")$hospitals

cat("\n")
cat(strrep("=", 70), "\n")
cat("MANUAL ENTRY HOSPITAL REVIEW TOOL\n")
cat(strrep("=", 70), "\n\n")

# Find all manual entry hospitals
manual_hospitals <- list()
for (i in seq_along(hospitals)) {
  h <- hospitals[[i]]
  
  # Check if it's a manual entry hospital
  is_manual <- FALSE
  if (!is.null(h$pattern) && h$pattern == "manual_entry_required") {
    is_manual <- TRUE
  }
  if (!is.null(h$status) && grepl("manual|MER|blocked", h$status, ignore.case = TRUE)) {
    is_manual <- TRUE
  }
  
  if (is_manual) {
    manual_hospitals[[length(manual_hospitals) + 1]] <- list(
      index = i,
      fac = h$FAC,
      name = h$name,
      url = h$url,
      status = ifelse(is.null(h$status), "not specified", h$status),
      notes = ifelse(is.null(h$notes), "none", h$notes),
      exec_count = ifelse(is.null(h$known_executives), 0, length(h$known_executives)),
      has_data = !is.null(h$known_executives) && length(h$known_executives) > 0
    )
  }
}

cat(sprintf("Found %d manual entry hospitals\n\n", length(manual_hospitals)))

# Summary
has_data <- sum(sapply(manual_hospitals, function(h) h$has_data))
no_data <- length(manual_hospitals) - has_data

cat("SUMMARY:\n")
cat(sprintf("  ✓ With manual data: %d\n", has_data))
cat(sprintf("  ✗ Without data: %d\n", no_data))
cat("\n")

# Create detailed report
cat(strrep("=", 70), "\n")
cat("DETAILED HOSPITAL LIST\n")
cat(strrep("=", 70), "\n\n")

for (i in seq_along(manual_hospitals)) {
  h <- manual_hospitals[[i]]
  
  cat(sprintf("HOSPITAL %d/%d\n", i, length(manual_hospitals)))
  cat(strrep("-", 70), "\n")
  cat(sprintf("FAC: %s\n", h$fac))
  cat(sprintf("Name: %s\n", h$name))
  cat(sprintf("Status: %s\n", h$status))
  cat(sprintf("Current manual entries: %d\n", h$exec_count))
  cat(sprintf("Notes: %s\n", h$notes))
  cat(sprintf("URL: %s\n", h$url))
  
  if (h$has_data) {
    cat("✓ Has manual data\n")
  } else {
    cat("⚠️  NO MANUAL DATA - Needs attention\n")
  }
  
  cat("\n")
}

# Export CSV for easy tracking
report_df <- data.frame(
  FAC = sapply(manual_hospitals, function(h) h$fac),
  Hospital_Name = sapply(manual_hospitals, function(h) h$name),
  Status = sapply(manual_hospitals, function(h) h$status),
  Current_Entries = sapply(manual_hospitals, function(h) h$exec_count),
  Has_Data = sapply(manual_hospitals, function(h) ifelse(h$has_data, "YES", "NO")),
  URL = sapply(manual_hospitals, function(h) h$url),
  Notes = sapply(manual_hospitals, function(h) h$notes),
  stringsAsFactors = FALSE
)

output_file <- "processed/MANUAL_ENTRY_REVIEW_LIST.csv"
write.csv(report_df, output_file, row.names = FALSE)

cat(strrep("=", 70), "\n")
cat(sprintf("✓ Report saved to: %s\n", output_file))
cat(strrep("=", 70), "\n\n")

cat("NEXT STEPS:\n")
cat("1. Open the CSV file to see all manual hospitals\n")
cat("2. For each hospital without data or needing update:\n")
cat("   a. Visit the URL\n")
cat("   b. Take a screenshot of the leadership page\n")
cat("   c. Use AI to parse names and titles\n")
cat("   d. Update YAML with known_executives\n")
cat("3. Re-run collection after updates\n")
cat("\n")