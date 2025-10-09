# test_all_configured_hospitals.R - Comprehensive testing of all configured hospitals
# Save this in E:/ExecutiveSearchYaml/code/

setwd("E:/ExecutiveSearchYaml/code/")

library(yaml)
library(dplyr)
library(knitr)
source("pattern_based_scraper.R")

# ============================================================================
# COMPREHENSIVE HOSPITAL TESTING SUITE
# ============================================================================

test_all_configured_hospitals <- function(config_file = "enhanced_hospitals.yaml",
                                          output_folder = "E:/ExecutiveSearchYaml/output") {
  
  cat("╔════════════════════════════════════════════════════════════════════╗\n")
  cat("║       COMPREHENSIVE HOSPITAL CONFIGURATION TEST SUITE             ║\n")
  cat("╚════════════════════════════════════════════════════════════════════╝\n\n")
  
  # Read configuration
  if (!file.exists(config_file)) {
    cat("ERROR: Configuration file not found:", config_file, "\n")
    return(NULL)
  }
  
  config <- yaml::read_yaml(config_file)
  hospitals <- config$hospitals
  
  cat("Found", length(hospitals), "hospitals in configuration\n")
  cat("Starting comprehensive test...\n\n")
  
  # Initialize results tracking
  test_results <- data.frame(
    FAC = character(),
    Hospital = character(),
    Pattern = character(),
    Expected = integer(),
    Found = integer(),
    Status = character(),
    Success_Rate = numeric(),
    Issues = character(),
    stringsAsFactors = FALSE
  )
  
  all_scraped_data <- list()
  
  # Initialize scraper
  scraper <- PatternBasedScraper()
  
  # Test each hospital
  for (i in seq_along(hospitals)) {
    hospital <- hospitals[[i]]
    
    cat("═══════════════════════════════════════════════════════════════════\n")
    cat(sprintf("[%d/%d] Testing FAC-%s: %s\n", i, length(hospitals), 
                hospital$FAC, hospital$name))
    cat("───────────────────────────────────────────────────────────────────\n")
    cat("Pattern:", hospital$pattern, "\n")
    cat("URL:", hospital$url, "\n")
    
    expected <- hospital$expected_executives %||% NA
    if (!is.na(expected)) {
      cat("Expected executives:", expected, "\n")
    }
    
    # Test the hospital
    test_start <- Sys.time()
    
    result <- tryCatch({
      scraper$scrape_hospital(hospital)
    }, error = function(e) {
      cat("✗ ERROR:", e$message, "\n")
      data.frame(
        FAC = hospital$FAC,
        hospital_name = hospital$name,
        executive_name = NA,
        executive_title = NA,
        date_gathered = Sys.Date(),
        error_message = e$message,
        stringsAsFactors = FALSE
      )
    })
    
    test_duration <- round(as.numeric(difftime(Sys.time(), test_start, units = "secs")), 2)
    
    # Analyze results
    valid_count <- sum(!is.na(result$executive_name) & !is.na(result$executive_title))
    total_count <- nrow(result)
    
    # Determine status
    status <- "UNKNOWN"
    issues <- ""
    success_rate <- 0
    
    if (!is.null(result$error_message) && !is.na(result$error_message[1])) {
      status <- "ERROR"
      issues <- result$error_message[1]
      cat("✗ FAILED: Error occurred\n")
    } else if (valid_count == 0) {
      status <- "NO_RESULTS"
      issues <- "No executives found"
      cat("✗ FAILED: No executives found\n")
    } else if (!is.na(expected)) {
      if (valid_count == expected) {
        status <- "COMPLETE"
        success_rate <- 100
        cat("✓ SUCCESS: Found all", expected, "expected executives\n")
      } else if (valid_count < expected) {
        status <- "INCOMPLETE"
        success_rate <- round((valid_count / expected) * 100, 1)
        issues <- sprintf("Missing %d executives", expected - valid_count)
        cat("⚠ PARTIAL: Found", valid_count, "of", expected, "expected executives\n")
      } else {
        status <- "EXTRA"
        success_rate <- 100
        issues <- sprintf("Found %d extra executives", valid_count - expected)
        cat("⚠ WARNING: Found", valid_count, "executives, expected", expected, "\n")
      }
    } else {
      status <- "SUCCESS"
      success_rate <- 100
      cat("✓ SUCCESS: Found", valid_count, "executives (no expected count)\n")
    }
    
    cat("Duration:", test_duration, "seconds\n")
    
    # Show found executives
    if (valid_count > 0) {
      cat("\nExecutives Found:\n")
      for (j in 1:nrow(result)) {
        if (!is.na(result$executive_name[j]) && !is.na(result$executive_title[j])) {
          cat(sprintf("  %2d. %-35s → %s\n", 
                      j, 
                      result$executive_name[j], 
                      result$executive_title[j]))
        }
      }
    }
    
    # Add to test results
    test_results <- rbind(test_results, data.frame(
      FAC = hospital$FAC,
      Hospital = hospital$name,
      Pattern = hospital$pattern,
      Expected = ifelse(is.na(expected), 0, expected),
      Found = valid_count,
      Status = status,
      Success_Rate = success_rate,
      Issues = issues,
      stringsAsFactors = FALSE
    ))
    
    # Store scraped data
    all_scraped_data[[i]] <- result
    
    cat("\n")
    Sys.sleep(1)  # Be polite to servers
  }
  
  # ========================================================================
  # GENERATE SUMMARY REPORT
  # ========================================================================
  
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("                        SUMMARY REPORT                              \n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # Overall statistics
  total_hospitals <- nrow(test_results)
  complete_count <- sum(test_results$Status == "COMPLETE")
  success_count <- sum(test_results$Status %in% c("COMPLETE", "SUCCESS"))
  partial_count <- sum(test_results$Status == "INCOMPLETE")
  failed_count <- sum(test_results$Status %in% c("NO_RESULTS", "ERROR"))
  
  cat("OVERALL STATISTICS:\n")
  cat("  Total hospitals tested:", total_hospitals, "\n")
  cat("  Complete (100% expected):", complete_count, 
      sprintf("(%.1f%%)\n", complete_count/total_hospitals*100))
  cat("  Successful (with results):", success_count, 
      sprintf("(%.1f%%)\n", success_count/total_hospitals*100))
  cat("  Partial results:", partial_count, 
      sprintf("(%.1f%%)\n", partial_count/total_hospitals*100))
  cat("  Failed:", failed_count, 
      sprintf("(%.1f%%)\n", failed_count/total_hospitals*100))
  
  total_expected <- sum(test_results$Expected[test_results$Expected > 0])
  total_found <- sum(test_results$Found)
  
  cat("\n  Total executives expected:", total_expected, "\n")
  cat("  Total executives found:", total_found, "\n")
  if (total_expected > 0) {
    cat("  Overall success rate:", 
        sprintf("%.1f%%\n", (total_found/total_expected)*100))
  }
  
  # Pattern effectiveness
  cat("\n───────────────────────────────────────────────────────────────────\n")
  cat("PATTERN EFFECTIVENESS:\n\n")
  
  pattern_summary <- test_results %>%
    group_by(Pattern) %>%
    summarise(
      Hospitals = n(),
      Complete = sum(Status == "COMPLETE"),
      Partial = sum(Status == "INCOMPLETE"),
      Failed = sum(Status %in% c("NO_RESULTS", "ERROR")),
      Total_Expected = sum(Expected[Expected > 0]),
      Total_Found = sum(Found),
      Avg_Success = ifelse(sum(Expected > 0) > 0,
                           round(mean(Success_Rate[Expected > 0]), 1),
                           NA),
      .groups = "drop"
    ) %>%
    arrange(desc(Hospitals))
  
  print(kable(pattern_summary, format = "simple"))
  
  # Hospitals needing attention
  needs_attention <- test_results %>%
    filter(Status %in% c("INCOMPLETE", "NO_RESULTS", "ERROR", "EXTRA")) %>%
    arrange(Status, FAC)
  
  if (nrow(needs_attention) > 0) {
    cat("\n───────────────────────────────────────────────────────────────────\n")
    cat("HOSPITALS NEEDING ATTENTION:\n\n")
    
    for (i in 1:nrow(needs_attention)) {
      cat(sprintf("  FAC-%s: %s\n", 
                  needs_attention$FAC[i], 
                  needs_attention$Hospital[i]))
      cat(sprintf("    Status: %s | Pattern: %s\n", 
                  needs_attention$Status[i],
                  needs_attention$Pattern[i]))
      cat(sprintf("    Found: %d | Expected: %d\n", 
                  needs_attention$Found[i],
                  needs_attention$Expected[i]))
      if (nchar(needs_attention$Issues[i]) > 0) {
        cat(sprintf("    Issue: %s\n", needs_attention$Issues[i]))
      }
      cat("\n")
    }
    
    cat("RECOMMENDATIONS:\n")
    cat("  • For INCOMPLETE: Check missing_people or adjust pattern\n")
    cat("  • For NO_RESULTS: Use helper$analyze_hospital_structure()\n")
    cat("  • For ERROR: Check URL accessibility and HTML structure\n")
    cat("  • For EXTRA: Verify expected_executives count\n")
  }
  
  # Top performing hospitals
  top_performers <- test_results %>%
    filter(Status %in% c("COMPLETE", "SUCCESS")) %>%
    arrange(desc(Found)) %>%
    head(10)
  
  if (nrow(top_performers) > 0) {
    cat("\n───────────────────────────────────────────────────────────────────\n")
    cat("TOP PERFORMING CONFIGURATIONS:\n\n")
    
    for (i in 1:min(5, nrow(top_performers))) {
      cat(sprintf("  %d. FAC-%s: %s\n", 
                  i,
                  top_performers$FAC[i], 
                  top_performers$Hospital[i]))
      cat(sprintf("     Pattern: %s | Found: %d executives\n", 
                  top_performers$Pattern[i],
                  top_performers$Found[i]))
    }
  }
  
  # Save results
  cat("\n───────────────────────────────────────────────────────────────────\n")
  cat("SAVING RESULTS:\n\n")
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Save test summary
  summary_file <- file.path(output_folder, 
                            paste0("test_summary_", timestamp, ".csv"))
  write.csv(test_results, summary_file, row.names = FALSE)
  cat("  Test summary saved:", basename(summary_file), "\n")
  
  # Save full scraped data
  combined_data <- bind_rows(all_scraped_data)
  data_file <- file.path(output_folder, 
                         paste0("all_hospitals_", timestamp, ".csv"))
  write.csv(combined_data, data_file, row.names = FALSE)
  cat("  Full data saved:", basename(data_file), "\n")
  
  # Generate detailed HTML report (optional)
  report_file <- file.path(output_folder, 
                           paste0("test_report_", timestamp, ".txt"))
  
  sink(report_file)
  cat("HOSPITAL CONFIGURATION TEST REPORT\n")
  cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  cat("SUMMARY STATISTICS:\n")
  cat("  Total hospitals:", total_hospitals, "\n")
  cat("  Complete:", complete_count, "\n")
  cat("  Partial:", partial_count, "\n")
  cat("  Failed:", failed_count, "\n")
  cat("  Total executives found:", total_found, "\n\n")
  
  cat("DETAILED RESULTS:\n\n")
  for (i in 1:nrow(test_results)) {
    cat(sprintf("FAC-%s: %s\n", test_results$FAC[i], test_results$Hospital[i]))
    cat(sprintf("  Pattern: %s\n", test_results$Pattern[i]))
    cat(sprintf("  Status: %s\n", test_results$Status[i]))
    cat(sprintf("  Found: %d | Expected: %d\n", 
                test_results$Found[i], test_results$Expected[i]))
    if (nchar(test_results$Issues[i]) > 0) {
      cat(sprintf("  Issues: %s\n", test_results$Issues[i]))
    }
    cat("\n")
  }
  sink()
  
  cat("  Detailed report saved:", basename(report_file), "\n")
  
  cat("\n═══════════════════════════════════════════════════════════════════\n")
  cat("                      TEST COMPLETE                                 \n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # Return results for further analysis
  return(list(
    summary = test_results,
    data = combined_data,
    timestamp = timestamp
  ))
}

# ============================================================================
# QUICK STATUS CHECK (faster, no scraping)
# ============================================================================

check_configuration_status <- function(config_file = "enhanced_hospitals.yaml") {
  
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("              CONFIGURATION STATUS CHECK                            \n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  if (!file.exists(config_file)) {
    cat("ERROR: Configuration file not found:", config_file, "\n")
    return(NULL)
  }
  
  config <- yaml::read_yaml(config_file)
  hospitals <- config$hospitals
  
  cat("Total hospitals in configuration:", length(hospitals), "\n\n")
  
  # Group by status
  status_summary <- data.frame(
    FAC = character(),
    Hospital = character(),
    Pattern = character(),
    Status = character(),
    Expected = integer(),
    Has_Missing = logical(),
    stringsAsFactors = FALSE
  )
  
  for (hospital in hospitals) {
    has_missing <- !is.null(hospital$html_structure$missing_people)
    
    status_summary <- rbind(status_summary, data.frame(
      FAC = hospital$FAC,
      Hospital = hospital$name,
      Pattern = hospital$pattern,
      Status = hospital$status %||% "unknown",
      Expected = hospital$expected_executives %||% 0,
      Has_Missing = has_missing,
      stringsAsFactors = FALSE
    ))
  }
  
  # Status breakdown
  cat("STATUS BREAKDOWN:\n")
  status_counts <- table(status_summary$Status)
  for (status in names(status_counts)) {
    cat(sprintf("  %s: %d\n", status, status_counts[status]))
  }
  
  # Pattern usage
  cat("\nPATTERN USAGE:\n")
  pattern_counts <- table(status_summary$Pattern)
  pattern_counts <- sort(pattern_counts, decreasing = TRUE)
  for (pattern in names(pattern_counts)) {
    cat(sprintf("  %s: %d hospitals\n", pattern, pattern_counts[pattern]))
  }
  
  # Hospitals with missing_people
  with_missing <- status_summary %>% filter(Has_Missing == TRUE)
  if (nrow(with_missing) > 0) {
    cat("\nHOSPITALS WITH MISSING_PEOPLE:\n")
    for (i in 1:nrow(with_missing)) {
      cat(sprintf("  FAC-%s: %s\n", with_missing$FAC[i], with_missing$Hospital[i]))
    }
  }
  
  cat("\n")
  return(status_summary)
}

# ============================================================================
# USAGE INSTRUCTIONS
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("     HOSPITAL CONFIGURATION TEST SUITE LOADED                       \n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

cat("AVAILABLE FUNCTIONS:\n\n")

cat("1. test_all_configured_hospitals()\n")
cat("   - Comprehensive test of all hospitals in YAML\n")
cat("   - Scrapes each hospital and validates results\n")
cat("   - Generates detailed reports and CSV files\n")
cat("   - Takes ~1-2 minutes per hospital\n\n")

cat("2. check_configuration_status()\n")
cat("   - Quick status check (no scraping)\n")
cat("   - Shows patterns, status, expected counts\n")
cat("   - Identifies hospitals with missing_people\n")
cat("   - Instant results\n\n")

cat("USAGE:\n\n")

cat("# Run comprehensive test:\n")
cat("results <- test_all_configured_hospitals()\n\n")

cat("# Quick configuration check:\n")
cat("status <- check_configuration_status()\n\n")

cat("OUTPUTS:\n")
cat("  • test_summary_TIMESTAMP.csv - Summary of all tests\n")
cat("  • all_hospitals_TIMESTAMP.csv - Complete scraped data\n")
cat("  • test_report_TIMESTAMP.txt - Detailed text report\n\n")

cat("═══════════════════════════════════════════════════════════════════\n\n")

check_configuration_status()

