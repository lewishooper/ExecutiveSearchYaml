# PatternSummary.R
# Creates a dataframe of successfully configured hospitals with their YAML structure details
# for use in building an accurate Pattern Quick Reference guide

library(yaml)
library(dplyr)
library(tibble)

# Load the good hospitals list
good_hospitals <- GoodHospitals
cat("Loaded", nrow(good_hospitals), "successfully configured hospitals\n")

# Load the YAML configuration
yaml_data <- yaml::read_yaml("enhanced_hospitals.yaml")
hospitals_yaml <- yaml_data$hospitals  # Extract the hospitals list

cat("Loaded", length(hospitals_yaml), "hospitals from YAML\n\n")

# Initialize list to store results
results_list <- list()

# Process each hospital in the good_hospitals list
for(i in 1:nrow(good_hospitals)) {
  fac_num <- good_hospitals$FAC[i]
  
  # Find matching hospital in YAML
  yaml_hospital <- NULL
  for(h in hospitals_yaml) {
    if(!is.null(h$FAC)) {
      yaml_fac <- as.character(h$FAC)
      
      # Remove "FAC-" prefix if present
      yaml_fac_clean <- gsub("^FAC-", "", yaml_fac)
      fac_num_clean <- gsub("^FAC-", "", as.character(fac_num))
      
      # Try matching
      if(yaml_fac_clean == fac_num_clean) {
        yaml_hospital <- h
        break
      }
    }
  }
  
  if(is.null(yaml_hospital)) {
    cat("Warning: FAC", fac_num, "not found in YAML\n")
    next
  }
  
  # Extract basic info
  row_data <- list(
    FAC = gsub("^FAC-", "", as.character(yaml_hospital$FAC)),
    Name = yaml_hospital$name %||% NA_character_,
    Hospital_type = good_hospitals$Hospital_type[i],
    pattern = yaml_hospital$pattern %||% NA_character_
  )
  
  # Extract html_structure items
  if(!is.null(yaml_hospital$html_structure)) {
    struct <- yaml_hospital$html_structure
    struct_names <- names(struct)
    
    # Add up to 4 HTML structure items
    for(j in 1:4) {
      if(j <= length(struct_names)) {
        item_name <- struct_names[j]
        item_value <- struct[[item_name]]
        
        # Convert lists/vectors to string
        if(is.list(item_value) || length(item_value) > 1) {
          item_value <- paste(item_value, collapse = ", ")
        }
        
        row_data[[paste0("HTMLItem", j)]] <- as.character(item_name)
        row_data[[paste0("HTMLItemElement", j)]] <- as.character(item_value)
      } else {
        row_data[[paste0("HTMLItem", j)]] <- NA_character_
        row_data[[paste0("HTMLItemElement", j)]] <- NA_character_
      }
    }
  } else {
    # No html_structure, set all to NA_character_
    for(j in 1:4) {
      row_data[[paste0("HTMLItem", j)]] <- NA_character_
      row_data[[paste0("HTMLItemElement", j)]] <- NA_character_
    }
  }
  
  results_list[[length(results_list) + 1]] <- row_data
}

# Convert list to dataframe
pattern_summary <- bind_rows(results_list)

# Display summary
cat("\n=== Pattern Summary Created ===\n")
cat("Total hospitals:", nrow(pattern_summary), "\n")
cat("Patterns represented:\n")
print(table(pattern_summary$pattern))

# Show first few rows
cat("\nFirst few rows:\n")
print(head(pattern_summary, 3))

# Save the dataframe
saveRDS(pattern_summary, "pattern_summary.rds")
write.csv(pattern_summary, "pattern_summary.csv", row.names = FALSE)

cat("\nSaved to:\n")
cat("  - pattern_summary.rds\n")
cat("  - pattern_summary.csv\n")

# Return the dataframe
pattern_summary