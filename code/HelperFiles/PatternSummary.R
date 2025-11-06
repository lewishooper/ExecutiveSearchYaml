# PatternSummary.R - FIXED VERSION
library(yaml)
library(dplyr)
library(tibble)

cat("\n=== Starting Pattern Summary Creation ===\n\n")

# Load the good hospitals list
good_hospitals <- readRDS("GoodHospitals.rds")
cat("Loaded", nrow(good_hospitals), "successfully configured hospitals\n")

# Load the YAML configuration
yaml_data <- yaml::read_yaml("enhanced_hospitals.yaml")
hospitals_yaml <- yaml_data$hospitals
cat("Loaded", length(hospitals_yaml), "hospitals from YAML\n\n")

# Initialize list to store results
results_list <- list()
matched_count <- 0
not_found_count <- 0

# Process each hospital in the good_hospitals list
for(i in 1:nrow(good_hospitals)) {
  fac_num <- as.character(good_hospitals$FAC[i])
  fac_num <- trimws(fac_num)
  
  # Find matching hospital in YAML
  yaml_hospital <- NULL
  for(j in 1:length(hospitals_yaml)) {
    h <- hospitals_yaml[[j]]
    if(!is.null(h$FAC)) {
      yaml_fac <- trimws(as.character(h$FAC))
      
      if(yaml_fac == fac_num) {
        yaml_hospital <- h
        matched_count <- matched_count + 1
        break
      }
    }
  }
  
  if(is.null(yaml_hospital)) {
    cat("Warning: FAC", fac_num, "not found in YAML\n")
    not_found_count <- not_found_count + 1
    next
  }
  
  # Extract basic info
  row_data <- list(
    FAC = fac_num,
    Name = yaml_hospital$name %||% NA_character_,
    Hospital_type = good_hospitals$Hospital_type[i],
    pattern = yaml_hospital$pattern %||% NA_character_
  )
  
  # Extract html_structure items
  if(!is.null(yaml_hospital$html_structure)) {
    struct <- yaml_hospital$html_structure
    struct_names <- names(struct)
    
    # Add up to 4 HTML structure items
    for(k in 1:4) {
      if(k <= length(struct_names)) {
        item_name <- struct_names[k]
        item_value <- struct[[item_name]]
        
        # CRITICAL FIX: Handle NULL values properly
        if(is.null(item_value)) {
          item_value_str <- NA_character_
        } else if(is.list(item_value) || length(item_value) > 1) {
          item_value_str <- paste(item_value, collapse = ", ")
        } else if(length(item_value) == 0) {
          # Handle character(0) or empty vectors
          item_value_str <- NA_character_
        } else {
          item_value_str <- as.character(item_value)
        }
        
        row_data[[paste0("HTMLItem", k)]] <- as.character(item_name)
        row_data[[paste0("HTMLItemElement", k)]] <- item_value_str
      } else {
        row_data[[paste0("HTMLItem", k)]] <- NA_character_
        row_data[[paste0("HTMLItemElement", k)]] <- NA_character_
      }
    }
  } else {
    # No html_structure, set all to NA_character_
    for(k in 1:4) {
      row_data[[paste0("HTMLItem", k)]] <- NA_character_
      row_data[[paste0("HTMLItemElement", k)]] <- NA_character_
    }
  }
  
  results_list[[length(results_list) + 1]] <- row_data
}

cat("\n=== Matching Summary ===\n")
cat("Matched:", matched_count, "\n")
cat("Not found:", not_found_count, "\n")
cat("results_list length:", length(results_list), "\n\n")

# Convert list to dataframe
if(length(results_list) > 0) {
  pattern_summary <- bind_rows(results_list)
  
  cat("=== Pattern Summary Created ===\n")
  cat("Total hospitals:", nrow(pattern_summary), "\n")
  cat("Patterns represented:\n")
  print(table(pattern_summary$pattern))
  
  cat("\nFirst few rows:\n")
  print(head(pattern_summary, 3))
  
  saveRDS(pattern_summary, "pattern_summary.rds")
  write.csv(pattern_summary, "pattern_summary.csv", row.names = FALSE)
  
  cat("\nSaved to:\n")
  cat("  - pattern_summary.rds\n")
  cat("  - pattern_summary.csv\n")
} else {
  cat("ERROR: No hospitals matched!\n")
  pattern_summary <- NULL
}

pattern_summary