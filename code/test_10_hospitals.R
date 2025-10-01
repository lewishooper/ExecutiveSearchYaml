# test_10_hospitals.R - Test script for initial 10 hospitals
# Save this in E:/ExecutiveSearchYaml/code/

setwd("E:/ExecutiveSearchYaml/code/")

# Load all required libraries and functions
library(yaml)
library(dplyr)
source("pattern_based_scraper.R")
source("hospital_configuration_helper.R")

cat("=== TESTING 10 INITIAL HOSPITALS ===\n\n")

# Function to test all hospitals in YAML file
test_all_hospitals_from_yaml <- function(yaml_file = "enhanced_hospitals.yaml") {
  
  # Read the YAML configuration
  if (!file.exists(yaml_file)) {
    cat("ERROR: YAML file not found:", yaml_file, "\n")
    cat("Make sure you have created your enhanced_hospitals.yaml file\n")
    return(NULL)
  }
  
  config <- yaml::read_yaml(yaml_file)
  
  if (is.null(config$hospitals) || length(config$hospitals) == 0) {
    cat("ERROR: No hospitals found in YAML file\n")
    return(NULL)
  }
  
  hospitals <- config$hospitals
  cat("Found", length(hospitals), "hospitals in", yaml_file, "\n\n")
  
  # Initialize scraper
  scraper <- PatternBasedScraper()
  
  # Test each hospital
  all_results <- list()
  successful_hospitals <- 0
  
  for (i in seq_along(hospitals)) {
    hospital <- hospitals[[i]]
    
    cat("=== [", i, "/", length(hospitals), "] FAC-", hospital$FAC, ": ", hospital$name, " ===\n")
    cat("Pattern:", hospital$pattern, "\n")
    cat("URL:", hospital$url, "\n")
    
    # Test the hospital
    tryCatch({
      result <- scraper$scrape_hospital(hospital)
      all_results[[i]] <- result
      
      # Show results for this hospital
      valid_executives <- sum(!is.na(result$executive_name) & !is.na(result$executive_title))
      
      if (valid_executives > 0) {
        successful_hospitals <- successful_hospitals + 1
        cat("✓ SUCCESS:", valid_executives, "executives found\n")
        
        for (j in 1:nrow(result)) {
          if (!is.na(result$executive_name[j]) && !is.na(result$executive_title[j])) {
            cat(sprintf("  %d. %s → %s\n", j, result$executive_name[j], result$executive_title[j]))
          }
        }
      } else {
        cat("✗ FAILED: No executives found\n")
        if (!is.null(result$error_message)) {
          cat("  Error:", result$error_message[1], "\n")
        }
      }
      
      cat(rep("-", 70), "\n\n")
      
    }, error = function(e) {
      cat("✗ ERROR:", e$message, "\n")
      cat(rep("-", 70), "\n\n")
      
      # Create error result
      all_results[[i]] <- data.frame(
        FAC = hospital$FAC,
        hospital_name = hospital$name,
        executive_name = NA,
        executive_title = NA,
        date_gathered = Sys.Date(),
        error_message = e$message,
        stringsAsFactors = FALSE
      )
    })
    
    Sys.sleep(1)  # Be polite to servers
  }
  
  # Combine all results
  final_results <- bind_rows(all_results)
  
  # Save results to output folder
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  output_file <- file.path("E:/ExecutiveSearchYaml/output", 
                           paste0("test_10_hospitals_", timestamp, ".csv"))
  
  # Create output directory if it doesn't exist
  output_dir <- "E:/ExecutiveSearchYaml/output"
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    cat("Created output directory:", output_dir, "\n")
  }
  
  write.csv(final_results, output_file, row.names = FALSE)
  
  # Summary report
  cat("=== SUMMARY REPORT ===\n")
  total_hospitals <- length(hospitals)
  total_records <- nrow(final_results)
  valid_records <- sum(!is.na(final_results$executive_name) & !is.na(final_results$executive_title))
  
  cat("Total hospitals tested:", total_hospitals, "\n")
  cat("Hospitals with results:", successful_hospitals, "/", total_hospitals, 
      "(", round(successful_hospitals/total_hospitals*100, 1), "%)\n")
  cat("Total executive records:", total_records, "\n")
  cat("Valid executive records:", valid_records, "\n")
  cat("Overall success rate:", round(valid_records/total_records*100, 1), "%\n\n")
  
  # Pattern effectiveness
  cat("PATTERN EFFECTIVENESS:\n")
  pattern_summary <- final_results %>%
    filter(!is.na(executive_name)) %>%
    count(hospital_name) %>%
    inner_join(
      data.frame(
        hospital_name = sapply(hospitals, function(h) h$name),
        pattern = sapply(hospitals, function(h) h$pattern),
        stringsAsFactors = FALSE
      ), 
      by = "hospital_name"
    ) %>%
    group_by(pattern) %>%
    summarise(
      hospitals = n(),
      total_executives = sum(n),
      avg_per_hospital = round(mean(n), 1),
      .groups = "drop"
    ) %>%
    arrange(desc(total_executives))
  
  print(pattern_summary)
  
  cat("\nRESULTS SAVED TO:", basename(output_file), "\n")
  
  # Show hospitals that failed
  failed_hospitals <- final_results %>%
    group_by(FAC, hospital_name) %>%
    summarise(valid_execs = sum(!is.na(executive_name) & !is.na(executive_title)), .groups = "drop") %>%
    filter(valid_execs == 0)
  
  if (nrow(failed_hospitals) > 0) {
    cat("\nHOSPITALS NEEDING ATTENTION:\n")
    for (i in 1:nrow(failed_hospitals)) {
      cat("  FAC-", failed_hospitals$FAC[i], ": ", failed_hospitals$hospital_name[i], "\n")
    }
    cat("\nUse helper$analyze_hospital_structure() to debug these hospitals\n")
  }
  
  return(final_results)
}

# Quick test function for specific hospitals
test_specific_hospitals <- function(fac_numbers) {
  config <- yaml::read_yaml("enhanced_hospitals.yaml")
  hospitals <- config$hospitals
  
  selected_hospitals <- list()
  for (fac in fac_numbers) {
    fac_formatted <- sprintf("%03d", as.numeric(fac))
    for (hospital in hospitals) {
      if (hospital$FAC == fac_formatted) {
        selected_hospitals <- c(selected_hospitals, list(hospital))
        break
      }
    }
  }
  
  if (length(selected_hospitals) == 0) {
    cat("No hospitals found for FAC numbers:", paste(fac_numbers, collapse = ", "), "\n")
    return(NULL)
  }
  
  scraper <- PatternBasedScraper()
  results <- scraper$scrape_batch(selected_hospitals)
  
  return(results)
}

# Usage instructions
cat("TESTING FUNCTIONS LOADED:\n")
cat("1. test_all_hospitals_from_yaml() - Test all hospitals in YAML file\n")
cat("2. test_specific_hospitals(c(707, 935, 941)) - Test specific FAC numbers\n\n")

cat("TO RUN THE 10 HOSPITAL TEST:\n")
cat("results <- test_all_hospitals_from_yaml()\n\n")

cat("TO TEST JUST A FEW HOSPITALS:\n")
cat("results <- test_specific_hospitals(c(707, 935, 941))\n\n")

cat("The results will be automatically saved to E:/ExecutiveSearchYaml/output/\n\n")

# Uncomment the line below to run automatically
# results <- test_all_hospitals_from_yaml()