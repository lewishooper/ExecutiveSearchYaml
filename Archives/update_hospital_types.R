
# update_hospital_types.R
# Add hospital_type field to YAML files from Excel Type column
# Run from: E:/ExecutiveSearchYaml/code/

library(readxl)
library(yaml)
library(dplyr)

cat("═══════════════════════════════════════════════════════════════\n")
cat("UPDATING HOSPITAL TYPES IN YAML FILES\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Configuration
excel_file <- "E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx"
enhanced_yaml <- "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml"
next_batch_yaml <- "E:/ExecutiveSearchYaml/code/next_batch_template.yaml"

# Read Excel file
cat("Reading hospital types from Excel...\n")
hospital_data <- read_excel(excel_file, sheet = "LookupTypeFAC")

# Format FAC numbers consistently
hospital_data$FAC_formatted <- sprintf("%03d", as.numeric(hospital_data$FAC))

# Create lookup table
type_lookup <- setNames(hospital_data$Type, hospital_data$FAC_formatted)

cat("  Found", length(type_lookup), "hospitals with types\n")
cat("\nType distribution:\n")
type_counts <- table(hospital_data$Type)
for (type in names(sort(type_counts, decreasing = TRUE))) {
  cat(sprintf("  %-35s: %2d\n", type, type_counts[type]))
}

# Function to add type to hospital entry
add_hospital_type <- function(hospital, type_lookup) {
  fac <- hospital$FAC
  if (fac %in% names(type_lookup)) {
    # Insert hospital_type right after name
    new_hospital <- list(
      FAC = hospital$FAC,
      name = hospital$name,
      hospital_type = type_lookup[fac]
    )
    # Add all other fields
    other_fields <- setdiff(names(hospital), c("FAC", "name"))
    for (field in other_fields) {
      new_hospital[[field]] <- hospital[[field]]
    }
    return(new_hospital)
  } else {
    cat(sprintf("  ⚠️  Warning: No type found for FAC %s (%s)\n", 
                fac, hospital$name))
    return(hospital)
  }
}

# Update enhanced_hospitals.yaml
cat("\n═══════════════════════════════════════════════════════════════\n")
cat("UPDATING enhanced_hospitals.yaml\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

if (file.exists(enhanced_yaml)) {
  # Read current config
  config <- yaml::read_yaml(enhanced_yaml)
  
  cat("Processing", length(config$hospitals), "hospitals...\n\n")
  
  # Update each hospital
  config$hospitals <- lapply(config$hospitals, function(h) {
    add_hospital_type(h, type_lookup)
  })
  
  # Write back to file
  yaml_text <- yaml::as.yaml(config, indent.mapping.sequence = TRUE)
  writeLines(yaml_text, enhanced_yaml)
  
  cat("✅ Updated enhanced_hospitals.yaml\n")
  
  # Count types added
  types_added <- sum(sapply(config$hospitals, function(h) "hospital_type" %in% names(h)))
  cat("   Added hospital_type to", types_added, "hospitals\n")
  
} else {
  cat("⚠️  File not found:", enhanced_yaml, "\n")
}

# Update next_batch_template.yaml
cat("\n═══════════════════════════════════════════════════════════════\n")
cat("UPDATING next_batch_template.yaml\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

if (file.exists(next_batch_yaml)) {
  # Read current config
  config <- yaml::read_yaml(next_batch_yaml)
  
  if (!is.null(config$hospitals)) {
    cat("Processing", length(config$hospitals), "hospitals...\n\n")
    
    # Update each hospital
    config$hospitals <- lapply(config$hospitals, function(h) {
      add_hospital_type(h, type_lookup)
    })
    
    # Write back to file
    yaml_text <- yaml::as.yaml(config, indent.mapping.sequence = TRUE)
    writeLines(yaml_text, next_batch_yaml)
    
    cat("✅ Updated next_batch_template.yaml\n")
    
    # Count types added
    types_added <- sum(sapply(config$hospitals, function(h) "hospital_type" %in% names(h)))
    cat("   Added hospital_type to", types_added, "hospitals\n")
  } else {
    cat("⚠️  No hospitals found in next_batch_template.yaml\n")
  }
  
} else {
  cat("⚠️  File not found:", next_batch_yaml, "\n")
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("SUMMARY OF MOHLTC HOSPITAL TYPES\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("The following hospital types from MOHLTC have been added:\n\n")
cat("1. Teaching Hospital (15)\n")
cat("   - Major academic medical centers\n\n")
cat("2. Large Community Hospital (49)\n")
cat("   - Large community-based hospitals\n\n")
cat("3. Small Hospital (64)\n")
cat("   - Smaller community hospitals\n\n")
cat("4. Chronic/Rehab Hospital (10)\n")
cat("   - Long-term and rehabilitation facilities\n\n")
cat("5. Specialty Mental Health Hospital (5)\n")
cat("   - Dedicated mental health facilities\n\n")
cat("6. Specialty Children Hospital (2)\n")
cat("   - Dedicated pediatric facilities\n\n")
cat("7. Other Hospital (3)\n")
cat("   - Special purpose facilities\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("✅ UPDATE COMPLETE\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("\nNext steps:\n")
cat("1. Review the updated YAML files\n")
cat("2. Verify hospital_type field appears after name field\n")
cat("3. Test that scrapers still work with new field\n")
cat("4. Use hospital_type for filtering or analysis as needed\n")

