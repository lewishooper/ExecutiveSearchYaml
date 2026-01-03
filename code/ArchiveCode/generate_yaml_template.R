# generate_yaml_template.R - Generate YAML template for next batch
# Save this in E:/ExecutiveSearchYaml/code/

library(readxl)
library(dplyr)
library(yaml)

# Configuration
master_list_file <- "E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx"
config_file <- "enhanced_hospitals.yaml"
batch_size <- 30
output_file <- "E:/ExecutiveSearchYaml/next_batch_template2.yaml"

cat("=== GENERATING YAML TEMPLATE FOR NEXT BATCH ===\n\n")

# Read master hospital list
cat("Reading master list...\n")
master_list <- read_excel(master_list_file)

# Read current configuration
cat("Reading current configuration...\n")
config <- yaml::read_yaml(config_file)

# Get configured FAC numbers
configured_facs <- sapply(config$hospitals, function(h) h$FAC)
cat("Found", length(configured_facs), "configured hospitals\n\n")

# FIXED: Use exact column names from your Excel file
fac_col <- "FAC"
name_col <- "Hospital"
url_col <- "url"
done_col <- "done"  # Using 'done' as status indicator

cat("Using columns:\n")
cat("  FAC:", fac_col, "\n")
cat("  Name:", name_col, "\n")
cat("  URL:", url_col, "\n")
cat("  Status:", done_col, "\n")
cat("\n")

# Format and filter
master_list$FAC_formatted <- sprintf("%03d", as.numeric(master_list[[fac_col]]))

# Get unconfigured hospitals (where done != 'y')
unconfigured <- master_list %>%
  filter(!FAC_formatted %in% configured_facs)

# Separate by done status
if (done_col %in% names(master_list)) {
  # Hospitals marked as done='y' but not in config might be closed/merged
  done_but_not_configured <- unconfigured %>%
    filter(tolower(.data[[done_col]]) == "y")
  
  # Active hospitals that need configuration
  active_hospitals <- unconfigured %>%
    filter(is.na(.data[[done_col]]) | tolower(.data[[done_col]]) != "y")
  
  if (nrow(done_but_not_configured) > 0) {
    cat("Found", nrow(done_but_not_configured), "hospitals marked 'done' but not configured (possibly closed)\n")
  }
} else {
  active_hospitals <- unconfigured
  done_but_not_configured <- data.frame()
}

cat("Active hospitals to configure:", nrow(active_hospitals), "\n")

# Get next batch
next_batch <- active_hospitals %>%
  head(batch_size) %>%
  arrange(FAC_formatted)

cat("Generating template for", nrow(next_batch), "hospitals\n\n")

# Generate YAML template
yaml_lines <- c(
  "# NEXT BATCH TEMPLATE - Generated on", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  "# Instructions:",
  "#   1. Fill in the 'url' field with the leadership page URL (or verify existing URL)",
  "#   2. Update 'pattern' to match the HTML structure (see pattern guide)",
  "#   3. Set 'expected_executives' based on website inspection",
  "#   4. Update 'status' from 'needs_url' to 'needs_testing' once URL is added",
  "#   5. Add any notes about the hospital's structure",
  "#   6. For closed hospitals, see separate section at bottom",
  "",
  "# Common patterns:",
  "#   - h2_name_h3_title (names in h2, titles in h3)",
  "#   - combined_h2 (name and title together with separator)",
  "#   - div_classes (CSS class-based)",
  "#   - table_rows (table structure)",
  "#   - list_items (list with separators)",
  "",
  "hospitals:"
)

# Add each hospital
for (i in 1:nrow(next_batch)) {
  fac <- next_batch$FAC_formatted[i]
  name <- next_batch[[name_col]][i]
  
  # Check if URL exists in master list
  existing_url <- ""
  if (!is.null(url_col) && url_col %in% names(next_batch) && !is.na(next_batch[[url_col]][i])) {
    existing_url <- next_batch[[url_col]][i]
  }
  
  yaml_lines <- c(yaml_lines,
                  "",
                  paste0(" - FAC: \"", fac, "\""),
                  paste0("   name: \"", name, "\""),
                  if (nchar(existing_url) > 0 && existing_url != "NA") {
                    paste0("   url: \"", existing_url, "\"  # ← VERIFY: Check this URL is correct")
                  } else {
                    "   url: \"TODO_ADD_LEADERSHIP_URL\"  # ← REQUIRED: Add leadership page URL"
                  },
                  "   pattern: \"h2_name_h3_title\"  # ← UPDATE: Change to match actual pattern",
                  "   expected_executives: 5  # ← UPDATE: Change based on website",
                  "   html_structure:",
                  "     name_element: \"h2\"  # ← UPDATE if using different pattern",
                  "     title_element: \"h3\"  # ← UPDATE if using different pattern",
                  "     notes: \"\"  # ← OPTIONAL: Add any special notes",
                  "   status: \"needs_url\"  # ← UPDATE: Change to 'needs_testing' once URL added"
  )
}

# Add "done but not configured" section if any exist (likely closed hospitals)
if (nrow(done_but_not_configured) > 0) {
  yaml_lines <- c(yaml_lines,
                  "",
                  "",
                  "# ============================================================================",
                  "# HOSPITALS MARKED 'DONE' BUT NOT IN CONFIG",
                  "# These hospitals are marked as 'done=y' in the master list but are not",
                  "# in the configuration. They may be:",
                  "#   - Closed/merged hospitals",
                  "#   - Hospitals configured elsewhere",
                  "#   - Hospitals that need manual review",
                  "# ============================================================================",
                  ""
  )
  
  for (i in 1:min(10, nrow(done_but_not_configured))) {
    fac <- done_but_not_configured$FAC_formatted[i]
    name <- done_but_not_configured[[name_col]][i]
    
    yaml_lines <- c(yaml_lines,
                    paste0(" - FAC: \"", fac, "\""),
                    paste0("   name: \"", name, "\""),
                    "   status: \"needs_review\"  # Marked 'done' in master list but not configured",
                    ""
    )
  }
  
  if (nrow(done_but_not_configured) > 10) {
    yaml_lines <- c(yaml_lines,
                    paste0("# ... and ", nrow(done_but_not_configured) - 10, " more hospitals needing review"),
                    ""
    )
  }
}

# Add summary footer
yaml_lines <- c(yaml_lines,
                "",
                "# ============================================================================",
                "# BATCH SUMMARY",
                "# ============================================================================",
                paste0("# Total active hospitals in this batch: ", nrow(next_batch)),
                if (nrow(done_but_not_configured) > 0) {
                  paste0("# Hospitals marked 'done' but not configured: ", nrow(done_but_not_configured))
                } else NULL,
                paste0("# Remaining after this batch: ", nrow(active_hospitals) - nrow(next_batch)),
                "#",
                "# WORKFLOW:",
                "# 1. For each hospital, verify/find the leadership page URL",
                "# 2. Use: helper$analyze_hospital_structure(FAC, 'Name', 'URL')",
                "# 3. Update pattern, expected_executives, and html_structure",
                "# 4. Change status to 'needs_testing'",
                "# 5. Test with: quick_test(FAC)",
                "# 6. If successful, change status to 'configured' or 'ok'",
                "# 7. Copy completed entries to enhanced_hospitals.yaml",
                "# 8. Mark as done='y' in the master Excel file",
                "#",
                "# PATTERN REFERENCE:",
                "# See PATTERN_REGISTRY.md for detailed examples of all 11 patterns",
                "# ============================================================================"
)

# Write to file
writeLines(yaml_lines, output_file)

cat("✓ Template generated successfully!\n\n")
cat("Output file:", output_file, "\n\n")

cat("NEXT STEPS:\n")
cat("1. Open", output_file, "\n")
cat("2. For each hospital:\n")
cat("   a. Verify/find the leadership page URL\n")
cat("   b. Run: helper$analyze_hospital_structure(FAC, 'Name', 'URL')\n")
cat("   c. Update the pattern and html_structure based on analysis\n")
cat("   d. Test with: quick_test(FAC)\n")
cat("3. Once tested, copy working entries to enhanced_hospitals.yaml\n")
cat("4. Mark as done='y' in the master Excel file\n\n")

cat("HOSPITALS IN THIS BATCH:\n")
for (i in 1:nrow(next_batch)) {
  has_url <- !is.na(next_batch[[url_col]][i]) && nchar(next_batch[[url_col]][i]) > 0
  cat(sprintf("  [%2d] FAC-%s: %-50s %s\n", 
              i, 
              next_batch$FAC_formatted[i], 
              next_batch[[name_col]][i],
              if(has_url) "✓ Has URL" else "⚠ Needs URL"))
}

if (nrow(done_but_not_configured) > 0) {
  cat("\nHOSPITALS MARKED 'DONE' BUT NOT CONFIGURED (review these):\n")
  for (i in 1:min(5, nrow(done_but_not_configured))) {
    cat(sprintf("  FAC-%s: %s\n", 
                done_but_not_configured$FAC_formatted[i],
                done_but_not_configured[[name_col]][i]))
  }
  if (nrow(done_but_not_configured) > 5) {
    cat(sprintf("  ... and %d more\n", nrow(done_but_not_configured) - 5))
  }
}

cat("\n")
