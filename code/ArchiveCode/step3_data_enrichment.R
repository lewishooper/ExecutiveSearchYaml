# =============================================================================
# STEP 3: DATA ENRICHMENT AND MERGER PREPARATION
# Hybrid Approach - Enrich API Data with YAML Metadata
# =============================================================================
#
# Purpose: Merge API-extracted executives with hospital metadata from YAML
#          Prepare data for integration into master database
#          Identify duplicates and conflicts
#
# Author: Skip (with Claude assistance)
# Date: January 9, 2026
# Version: 1.0
#rm(list=ls())
# =============================================================================

library(yaml)
library(dplyr)

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║   STEP 3: DATA ENRICHMENT & MERGER PREP        ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# =============================================================================
# CONFIGURATION
# =============================================================================

# Input from Step 2
processed_dir <- "E:/ExecutiveSearchYaml/processed"
date_tag <- format(Sys.Date(), "%Y%m%d")

# YAML file location
yaml_file <- "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml"

# Output directory (for final enriched data)
output_dir <- "E:/ExecutiveSearchYaml/output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# =============================================================================
# LOAD DATA
# =============================================================================

cat("Loading data...\n")
cat("═════════════════════════════════════════════════\n")

# Load extracted executives from Step 2
executives_file <- file.path(
  processed_dir,
  sprintf("executives_extracted_%s.csv", date_tag)
)

if (!file.exists(executives_file)) {
  stop(sprintf("ERROR: Cannot find executives file: %s\nDid you run Step 2?", 
              executives_file))
}

executives <- read.csv(executives_file, stringsAsFactors = FALSE)

cat(sprintf("✓ Loaded %d executives from Step 2\n", nrow(executives)))

# Load YAML hospital metadata
if (!file.exists(yaml_file)) {
  stop(sprintf("ERROR: Cannot find YAML file: %s", yaml_file))
}

yaml_data <- read_yaml(yaml_file)
cat(sprintf("✓ Loaded YAML with %d hospitals\n", length(yaml_data$hospitals)))

cat("\n")

# =============================================================================
# EXTRACT HOSPITAL METADATA FROM YAML
# =============================================================================

cat("Extracting hospital metadata...\n")
cat("═════════════════════════════════════════════════\n")

# Convert YAML hospitals to data frame
hospital_metadata <- do.call(rbind, lapply(yaml_data$hospitals, function(h) {
  data.frame(
    FAC = h$FAC,
    hospital_name = ifelse(is.null(h$name), NA, h$name),
    hospital_type = ifelse(is.null(h$hospital_type), NA, h$hospital_type),
    source_url = ifelse(is.null(h$url), NA, h$url),
    pattern = ifelse(is.null(h$pattern), NA, h$pattern),
    data_status = ifelse(is.null(h$data_status), NA, h$data_status),
    stringsAsFactors = FALSE
  )
}))

cat(sprintf("✓ Extracted metadata for %d hospitals\n", nrow(hospital_metadata)))
cat("\n")

# =============================================================================
# MERGE EXECUTIVES WITH HOSPITAL METADATA
# =============================================================================

cat("Merging executives with hospital metadata...\n")
cat("═════════════════════════════════════════════════\n")

# Merge on FAC
enriched_executives <- merge(
  executives,
  hospital_metadata,
  by = "FAC",
  all.x = TRUE  # Keep all executives even if metadata missing
)

# Reorder columns for readability
enriched_executives <- enriched_executives %>%
  select(FAC,hospital_name,hospital_type,name,title,date_captured,source_file,source_url,pattern,data_status)

# Check for missing metadata
missing_metadata <- enriched_executives[is.na(enriched_executives$hospital_name), ]

if (nrow(missing_metadata) > 0) {
  cat(sprintf("⚠ WARNING: %d executives missing hospital metadata\n", 
             nrow(missing_metadata)))
  cat("  FACs with missing metadata:\n")
  for (fac in unique(missing_metadata$FAC)) {
    cat(sprintf("    - FAC-%s\n", fac))
  }
} else {
  cat("✓ All executives matched with hospital metadata\n")
}

cat(sprintf("✓ Enriched data: %d records\n", nrow(enriched_executives)))
cat("\n")

# =============================================================================
# ADD DATA SOURCE FLAG
# =============================================================================

cat("Adding data source tracking...\n")
cat("═════════════════════════════════════════════════\n")

# Add column to indicate this data came from API extraction
enriched_executives$extraction_method <- "api_screenshot"
enriched_executives$extraction_date <- Sys.Date()
enriched_executives$extraction_run <- date_tag

cat("✓ Added extraction method tracking\n\n")

# =============================================================================
# LOAD EXISTING DATABASE (IF EXISTS) FOR COMPARISON
# =============================================================================

cat("Checking for existing database...\n")
cat("═════════════════════════════════════════════════\n")

# Check for most recent master file
existing_files <- list.files(
  output_dir,
  pattern = "^master_executives_.*\\.csv$",
  full.names = TRUE
)

if (length(existing_files) > 0) {
  # Get most recent file
  most_recent <- existing_files[order(file.mtime(existing_files), decreasing = TRUE)][1]
  
  cat(sprintf("✓ Found existing database: %s\n", basename(most_recent)))
  
  existing_db <- read.csv(most_recent, stringsAsFactors = FALSE)
  cat(sprintf("  Records in existing DB: %d\n", nrow(existing_db)))
  
  # Filter existing DB to only hospitals we just processed
  processed_facs <- unique(enriched_executives$FAC)
  existing_for_comparison <- existing_db[existing_db$FAC %in% processed_facs, ]
  
  cat(sprintf("  Records for processed hospitals: %d\n", nrow(existing_for_comparison)))
  
  # Identify changes
  cat("\n")
  cat("Analyzing changes...\n")
  cat("─────────────────────────────────────────────────\n")
  
  # New executives (in current but not in existing)
  new_executives <- anti_join(
    enriched_executives[, c("FAC", "name", "title")],
    existing_for_comparison[, c("FAC", "name", "title")],
    by = c("FAC", "name")
  )
  
  # Departed executives (in existing but not in current)
  departed_executives <- anti_join(
    existing_for_comparison[, c("FAC", "name", "title")],
    enriched_executives[, c("FAC", "name", "title")],
    by = c("FAC", "name")
  )
  
  # Changed titles (same name, different title)
  title_changes <- inner_join(
    existing_for_comparison[, c("FAC", "name", "title")],
    enriched_executives[, c("FAC", "name", "title")],
    by = c("FAC", "name"),
    suffix = c("_old", "_new")
  )
  title_changes <- title_changes[title_changes$title_old != title_changes$title_new, ]
  
  cat(sprintf("New executives:     %d\n", nrow(new_executives)))
  cat(sprintf("Departed:           %d\n", nrow(departed_executives)))
  cat(sprintf("Title changes:      %d\n", nrow(title_changes)))
  
  # Save change summary
  changes <- list(
    new_executives = new_executives,
    departed_executives = departed_executives,
    title_changes = title_changes
  )
  
} else {
  cat("✓ No existing database found (first run)\n")
  cat("  All executives will be treated as new\n")
  changes <- NULL
}

cat("\n")

# =============================================================================
# DETECT INTERNAL DUPLICATES
# =============================================================================

cat("Checking for duplicates...\n")
cat("═════════════════════════════════════════════════\n")

# Check for duplicate names within same hospital
duplicates_same_hospital <- enriched_executives %>%
  group_by(FAC, name) %>%
  filter(n() > 1) %>%
  ungroup()

if (nrow(duplicates_same_hospital) > 0) {
  cat(sprintf("⚠ WARNING: %d duplicate entries within same hospital\n", 
             nrow(duplicates_same_hospital)))
  cat("\nDuplicates:\n")
  print(duplicates_same_hospital[, c("FAC", "hospital_name", "name", "title")])
  cat("\n")
} else {
  cat("✓ No duplicate entries within hospitals\n")
}

# Check for same person at multiple hospitals
duplicates_across_hospitals <- enriched_executives %>%
  group_by(name) %>%
  filter(n() > 1) %>%
  arrange(name, FAC) %>%
  ungroup()

if (nrow(duplicates_across_hospitals) > 0) {
  cat(sprintf("\n⚠ NOTE: %d people appear at multiple hospitals\n",
             length(unique(duplicates_across_hospitals$name))))
  cat("  (This may be legitimate - same person, multiple roles)\n")
  cat("\nPeople at multiple hospitals:\n")
  for (person_name in unique(duplicates_across_hospitals$name)) {
    person_records <- duplicates_across_hospitals[duplicates_across_hospitals$name == person_name, ]
    cat(sprintf("\n  %s:\n", person_name))
    for (i in 1:nrow(person_records)) {
      cat(sprintf("    - FAC-%s (%s): %s\n", 
                 person_records$FAC[i],
                 person_records$hospital_name[i],
                 person_records$title[i]))
    }
  }
}

cat("\n")

# =============================================================================
# SAVE ENRICHED DATA
# =============================================================================

cat("Saving enriched data...\n")
cat("═════════════════════════════════════════════════\n")

# Save enriched executives (ready for merger)
output_file <- file.path(
  output_dir,
  sprintf("enriched_executives_%s.csv", date_tag)
)
write.csv(enriched_executives, output_file, row.names = FALSE)
cat(sprintf("✓ Enriched data saved: %s\n", output_file))

# Save change summary if it exists
if (!is.null(changes)) {
  # New executives
  if (nrow(changes$new_executives) > 0) {
    new_file <- file.path(
      output_dir,
      sprintf("new_executives_%s.csv", date_tag)
    )
    write.csv(changes$new_executives, new_file, row.names = FALSE)
    cat(sprintf("✓ New executives saved: %s\n", new_file))
  }
  
  # Departed executives
  if (nrow(changes$departed_executives) > 0) {
    departed_file <- file.path(
      output_dir,
      sprintf("departed_executives_%s.csv", date_tag)
    )
    write.csv(changes$departed_executives, departed_file, row.names = FALSE)
    cat(sprintf("✓ Departed executives saved: %s\n", departed_file))
  }
  
  # Title changes
  if (nrow(changes$title_changes) > 0) {
    changes_file <- file.path(
      output_dir,
      sprintf("title_changes_%s.csv", date_tag)
    )
    write.csv(changes$title_changes, changes_file, row.names = FALSE)
    cat(sprintf("✓ Title changes saved: %s\n", changes_file))
  }
}

# Save duplicate reports if any
if (nrow(duplicates_same_hospital) > 0) {
  dup_file <- file.path(
    output_dir,
    sprintf("duplicates_same_hospital_%s.csv", date_tag)
  )
  write.csv(duplicates_same_hospital, dup_file, row.names = FALSE)
  cat(sprintf("✓ Duplicate report saved: %s\n", dup_file))
}

cat("\n")

# =============================================================================
# GENERATE INTEGRATION SUMMARY
# =============================================================================

cat("╔════════════════════════════════════════════════╗\n")
cat("║         DATA ENRICHMENT SUMMARY                ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("INPUT:\n")
cat(sprintf("  Executives from Step 2:  %d\n", nrow(executives)))
cat(sprintf("  Hospitals processed:     %d\n", length(unique(executives$FAC))))
cat("\n")

cat("OUTPUT:\n")
cat(sprintf("  Enriched records:        %d\n", nrow(enriched_executives)))
cat(sprintf("  Missing metadata:        %d\n", nrow(missing_metadata)))
cat(sprintf("  Duplicate same hospital: %d\n", nrow(duplicates_same_hospital)))
cat(sprintf("  Duplicate across:        %d\n", 
           length(unique(duplicates_across_hospitals$name))))
cat("\n")

if (!is.null(changes)) {
  cat("CHANGES FROM PREVIOUS RUN:\n")
  cat(sprintf("  New executives:          %d\n", nrow(changes$new_executives)))
  cat(sprintf("  Departed:                %d\n", nrow(changes$departed_executives)))
  cat(sprintf("  Title changes:           %d\n", nrow(changes$title_changes)))
  cat("\n")
}

cat("FILES CREATED:\n")
cat(sprintf("  - %s\n", basename(output_file)))
if (!is.null(changes)) {
  if (nrow(changes$new_executives) > 0) {
    cat(sprintf("  - new_executives_%s.csv\n", date_tag))
  }
  if (nrow(changes$departed_executives) > 0) {
    cat(sprintf("  - departed_executives_%s.csv\n", date_tag))
  }
  if (nrow(changes$title_changes) > 0) {
    cat(sprintf("  - title_changes_%s.csv\n", date_tag))
  }
}

cat("\n")

# =============================================================================
# NEXT STEPS GUIDANCE
# =============================================================================

cat("╔════════════════════════════════════════════════╗\n")
cat("║              NEXT STEPS                        ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

cat("READY FOR INTEGRATION:\n")
cat("═════════════════════════════════════════════════\n")
cat("1. Review enriched data:\n")
cat(sprintf("   %s\n\n", output_file))

cat("2. Check for issues:\n")
if (nrow(missing_metadata) > 0) {
  cat("   ⚠ Some records missing metadata - update YAML\n")
}
if (nrow(duplicates_same_hospital) > 0) {
  cat("   ⚠ Duplicates detected - review and resolve\n")
}
if (nrow(missing_metadata) == 0 && nrow(duplicates_same_hospital) == 0) {
  cat("   ✓ No issues detected\n")
}
cat("\n")

cat("3. Integrate into your master database:\n")
cat("   - Load enriched_executives CSV\n")
cat("   - Merge with existing data\n")
cat("   - Update monthly tracking\n\n")

if (!is.null(changes)) {
  cat("4. Review changes:\n")
  if (nrow(changes$new_executives) > 0) {
    cat(sprintf("   - %d new executives to add\n", nrow(changes$new_executives)))
  }
  if (nrow(changes$departed_executives) > 0) {
    cat(sprintf("   - %d departures to mark\n", nrow(changes$departed_executives)))
  }
  if (nrow(changes$title_changes) > 0) {
    cat(sprintf("   - %d title changes to update\n", nrow(changes$title_changes)))
  }
  cat("\n")
}

cat("✓ Step 3 complete!\n\n")

# Return results for further analysis
invisible(list(
  enriched_executives = enriched_executives,
  hospital_metadata = hospital_metadata,
  changes = changes,
  duplicates_same_hospital = duplicates_same_hospital,
  duplicates_across_hospitals = duplicates_across_hospitals
))
