# ============================================================================
# create_baseline_dataframe.R
# Creates a baseline dataframe with hospital executive data including pattern and type
# ============================================================================

library(rvest)
library(dplyr)
library(stringr)
library(yaml)

# Source the scraper
source("pattern_based_scraper.R")
scraper <- PatternBasedScraper()

# ============================================================================
# FUNCTION: Create Baseline Dataframe
# ============================================================================
create_baseline_dataframe <- function(sample_size = NULL, output_csv = FALSE) {
  
  cat("=== Creating Baseline Dataframe ===\n\n")
  
  # Capture baseline date at start
  baseline_date <- Sys.Date()
  
  # Load configuration
  config <- scraper$load_config("enhanced_hospitals.yaml")
  hospitals <- config$hospitals
  
  # Filter to sample if requested
  if (!is.null(sample_size)) {
    cat("Using sample of", sample_size, "hospitals\n\n")
    hospitals <- hospitals[1:min(sample_size, length(hospitals))]
  } else {
    cat("Processing all", length(hospitals), "hospitals\n\n")
  }
  
  # Initialize results list
  all_results <- list()
  
  # Process each hospital
  for (i in seq_along(hospitals)) {
    hospital <- hospitals[[i]]
    
    cat(sprintf("[%d/%d] Processing FAC %s - %s\n", 
                i, length(hospitals), hospital$FAC, hospital$name))
    
    tryCatch({
      # Scrape the hospital
      result <- scraper$scrape_hospital(hospital, "enhanced_hospitals.yaml")
      
      # Add pattern_used, hospital_type, and baseline_date to each row
      if (nrow(result) > 0) {
        result$pattern_used <- hospital$pattern %||% NA
        result$hospital_type <- hospital$hospital_type %||% NA
        result$baseline_date <- baseline_date
        
        # Remove the old date_gathered column from scraper output
        result <- result %>% select(-date_gathered)
        
        all_results[[i]] <- result
      }
      
      # Small delay to be polite
      Sys.sleep(1)
      
    }, error = function(e) {
      cat("  ERROR:", e$message, "\n")
      
      # Create error row
      error_row <- data.frame(
        FAC = sprintf("%03d", as.numeric(hospital$FAC)),
        hospital_name = hospital$name,
        executive_name = NA,
        executive_title = NA,
        robots_status = "error",
        robots_message = e$message,
        pattern_used = hospital$pattern %||% NA,
        hospital_type = hospital$hospital_type %||% NA,
        baseline_date = baseline_date,
        stringsAsFactors = FALSE
      )
      
      all_results[[i]] <- error_row
    })
  }
  
  # Combine all results into single dataframe
  baseline_df <- bind_rows(all_results)
  
  # Reorder columns to match your requirements
  baseline_df <- baseline_df %>%
    select(
      FAC,
      hospital_name,
      hospital_type,
      executive_name,
      executive_title,
      robots_status,
      pattern_used,
      baseline_date,
      everything()  # Include any other columns (like robots_message)
    )
  
  # Print summary
  cat("\n=== BASELINE SUMMARY ===\n")
  cat("Baseline Date:", as.character(baseline_date), "\n")
  cat("Total hospitals processed:", length(hospitals), "\n")
  cat("Total executive records:", nrow(baseline_df), "\n")
  cat("Valid records:", sum(!is.na(baseline_df$executive_name)), "\n")
  cat("Hospitals with data:", length(unique(baseline_df$hospital_name[!is.na(baseline_df$executive_name)])), "\n")
  
  # Pattern distribution
  cat("\n=== PATTERN DISTRIBUTION ===\n")
  pattern_counts <- baseline_df %>%
    filter(!is.na(executive_name)) %>%
    group_by(pattern_used) %>%
    summarise(count = n(), .groups = 'drop') %>%
    arrange(desc(count))
  print(pattern_counts)
  
  # Hospital type distribution
  cat("\n=== HOSPITAL TYPE DISTRIBUTION ===\n")
  type_counts <- baseline_df %>%
    filter(!is.na(executive_name)) %>%
    group_by(hospital_type) %>%
    summarise(count = n(), .groups = 'drop') %>%
    arrange(desc(count))
  print(type_counts)
  
  # Optionally save to CSV
  if (output_csv) {
    timestamp <- format(baseline_date, "%Y%m%d")
    output_file <- file.path("E:/ExecutiveSearchYaml/output", 
                             paste0("baseline_", timestamp, ".csv"))
    write.csv(baseline_df, output_file, row.names = FALSE)
    cat("\n✓ CSV saved to:", output_file, "\n")
  }
  
  return(baseline_df)
}

# ============================================================================
# USAGE EXAMPLES
# ============================================================================

# Example 1: Create baseline with 10 hospital sample (for testing)
cat("\n=== TESTING WITH 10 HOSPITALS ===\n")
baseline_sample <- create_baseline_dataframe(sample_size = 10, output_csv = FALSE)

# View the results
cat("\n=== SAMPLE RESULTS (first 20 rows) ===\n")
print(head(baseline_sample, 20))

# Check structure
cat("\n=== DATAFRAME STRUCTURE ===\n")
str(baseline_sample)

# Example 2: Once tested, run on all hospitals and save CSV
# Uncomment below when ready to process all hospitals:
#
# cat("\n=== PROCESSING ALL HOSPITALS ===\n")
# baseline_full <- create_baseline_dataframe(sample_size = NULL, output_csv = TRUE)
# 
# # Save the dataframe as RDS for later use
# saveRDS(baseline_full, "E:/ExecutiveSearchYaml/output/baseline_dataframe.rds")
# cat("✓ RDS saved to: E:/ExecutiveSearchYaml/output/baseline_dataframe.rds\n")

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Function to compare two baselines
compare_baselines <- function(baseline1, baseline2) {
  cat("=== BASELINE COMPARISON ===\n\n")
  
  cat("Baseline 1:\n")
  cat("  Date:", as.character(unique(baseline1$baseline_date)[1]), "\n")
  cat("  Hospitals:", length(unique(baseline1$FAC)), "\n")
  cat("  Executives:", sum(!is.na(baseline1$executive_name)), "\n\n")
  
  cat("Baseline 2:\n")
  cat("  Date:", as.character(unique(baseline2$baseline_date)[1]), "\n")
  cat("  Hospitals:", length(unique(baseline2$FAC)), "\n")
  cat("  Executives:", sum(!is.na(baseline2$executive_name)), "\n\n")
  
  # Find differences
  key_cols <- c("FAC", "executive_name")
  
  baseline1_keys <- baseline1 %>%
    filter(!is.na(executive_name)) %>%
    select(all_of(key_cols)) %>%
    mutate(key = paste(FAC, executive_name, sep = "_"))
  
  baseline2_keys <- baseline2 %>%
    filter(!is.na(executive_name)) %>%
    select(all_of(key_cols)) %>%
    mutate(key = paste(FAC, executive_name, sep = "_"))
  
  only_in_1 <- setdiff(baseline1_keys$key, baseline2_keys$key)
  only_in_2 <- setdiff(baseline2_keys$key, baseline1_keys$key)
  
  cat("Executives only in Baseline 1:", length(only_in_1), "\n")
  if (length(only_in_1) > 0) {
    cat("Examples:\n")
    print(head(baseline1_keys[baseline1_keys$key %in% only_in_1, ], 5))
  }
  
  cat("\nExecutives only in Baseline 2:", length(only_in_2), "\n")
  if (length(only_in_2) > 0) {
    cat("Examples:\n")
    print(head(baseline2_keys[baseline2_keys$key %in% only_in_2, ], 5))
  }
}

# Function to load and compare with previous baseline
load_and_compare <- function(new_baseline, previous_rds_path) {
  if (file.exists(previous_rds_path)) {
    previous_baseline <- readRDS(previous_rds_path)
    compare_baselines(previous_baseline, new_baseline)
  } else {
    cat("No previous baseline found at:", previous_rds_path, "\n")
  }
}

cat("\n✓ Script loaded successfully!\n")
cat("Run: baseline_sample <- create_baseline_dataframe(sample_size = 10)\n")
cat("Or: baseline_full <- create_baseline_dataframe(sample_size = NULL, output_csv = TRUE)\n")