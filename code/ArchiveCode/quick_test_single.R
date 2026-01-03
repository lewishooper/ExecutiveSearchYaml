# quick_test_single.R - Quick test for individual hospitals using only FAC number
# Save this in E:/ExecutiveSearchYaml/code/

setwd("E:/ExecutiveSearchYaml/code/")

library(yaml)
library(dplyr)
source("pattern_based_scraper.R")

# Quick test function - only needs FAC number
quick_test <- function(fac) {
  
  # Format FAC number
  fac_formatted <- sprintf("%03d", as.numeric(fac))
  
  # Read YAML configuration
  if (!file.exists("enhanced_hospitals.yaml")) {
    cat("ERROR: enhanced_hospitals.yaml not found\n")
    return(NULL)
  }
  
  config <- yaml::read_yaml("enhanced_hospitals.yaml")
  
  if (is.null(config$hospitals)) {
    cat("ERROR: No hospitals found in YAML\n")
    return(NULL)
  }
  
  # Find the hospital by FAC
  hospital_info <- NULL
  for (hospital in config$hospitals) {
    if (hospital$FAC == fac_formatted) {
      hospital_info <- hospital
      break
    }
  }
  
  if (is.null(hospital_info)) {
    cat("ERROR: Hospital with FAC", fac_formatted, "not found in YAML\n")
    cat("Available FAC numbers:", paste(sapply(config$hospitals, function(h) h$FAC), collapse = ", "), "\n")
    return(NULL)
  }
  
  # Display hospital information
  cat("=== TESTING FAC-", fac_formatted, "===\n")
  cat("Hospital:", hospital_info$name, "\n")
  cat("URL:", hospital_info$url, "\n")
  cat("Pattern:", hospital_info$pattern, "\n")
  cat("Expected executives:", hospital_info$expected_executives %||% "Not specified", "\n")
  cat(rep("=", 70), "\n\n")
  
  # Initialize scraper and test
  scraper <- PatternBasedScraper()
  
  cat("Scraping...\n")
  result <- tryCatch({
    scraper$scrape_hospital(hospital_info)
  }, error = function(e) {
    cat("ERROR during scraping:", e$message, "\n")
    return(data.frame(
      FAC = fac_formatted,
      hospital_name = hospital_info$name,
      executive_name = NA,
      executive_title = NA,
      date_gathered = Sys.Date(),
      error_message = e$message,
      stringsAsFactors = FALSE
    ))
  })
  
  # Display results
  cat("\n=== RESULTS ===\n")
  
  valid_count <- sum(!is.na(result$executive_name) & !is.na(result$executive_title))
  total_count <- nrow(result)
  expected <- hospital_info$expected_executives %||% NA
  
  if (valid_count > 0) {
    cat("✓ SUCCESS:", valid_count, "executives found\n")
    
    if (!is.na(expected)) {
      if (valid_count == expected) {
        cat("✓ COMPLETE: Found expected number of executives (", expected, ")\n")
      } else if (valid_count < expected) {
        cat("⚠ INCOMPLETE: Found", valid_count, "of", expected, "expected executives\n")
      } else {
        cat("⚠ EXTRA: Found", valid_count, "executives, expected", expected, "\n")
      }
    }
    
    cat("\nExecutives Found:\n")
    cat(rep("-", 70), "\n")
    
    for (i in 1:nrow(result)) {
      if (!is.na(result$executive_name[i]) && !is.na(result$executive_title[i])) {
        cat(sprintf("%2d. %-35s → %s\n", 
                    i, 
                    result$executive_name[i], 
                    result$executive_title[i]))
      }
    }
    
  } else {
    cat("✗ FAILED: No executives found\n")
    if (!is.null(result$error_message) && !is.na(result$error_message[1])) {
      cat("Error:", result$error_message[1], "\n")
    }
    cat("\nTroubleshooting suggestions:\n")
    cat("1. Check if URL is accessible\n")
    cat("2. Verify pattern matches HTML structure\n")
    cat("3. Use helper$analyze_hospital_structure(", fac, ", 'name', 'url') for details\n")
  }
  
  cat(rep("=", 70), "\n")
  
  # Return result invisibly for further analysis if needed
  invisible(result)
}

# Batch quick test - test multiple FACs at once
quick_test_batch <- function(fac_numbers) {
  
  cat("=== QUICK BATCH TEST ===\n")
  cat("Testing", length(fac_numbers), "hospitals\n\n")
  
  all_results <- list()
  summary_data <- data.frame(
    FAC = character(),
    Hospital = character(),
    Found = numeric(),
    Expected = numeric(),
    Status = character(),
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(fac_numbers)) {
    fac <- fac_numbers[i]
    
    cat("[", i, "/", length(fac_numbers), "] ")
    result <- quick_test(fac)
    cat("\n")
    
    if (!is.null(result)) {
      all_results[[i]] <- result
      
      # Add to summary
      valid_count <- sum(!is.na(result$executive_name) & !is.na(result$executive_title))
      
      # Get expected from YAML
      config <- yaml::read_yaml("enhanced_hospitals.yaml")
      fac_formatted <- sprintf("%03d", as.numeric(fac))
      expected <- NA
      hospital_name <- ""
      
      for (hospital in config$hospitals) {
        if (hospital$FAC == fac_formatted) {
          expected <- hospital$expected_executives %||% NA
          hospital_name <- hospital$name
          break
        }
      }
      
      status <- if (valid_count == 0) {
        "Failed"
      } else if (!is.na(expected) && valid_count == expected) {
        "Complete"
      } else if (!is.na(expected) && valid_count < expected) {
        "Incomplete"
      } else {
        "Success"
      }
      
      summary_data <- rbind(summary_data, data.frame(
        FAC = fac_formatted,
        Hospital = hospital_name,
        Found = valid_count,
        Expected = ifelse(is.na(expected), "-", as.character(expected)),
        Status = status,
        stringsAsFactors = FALSE
      ))
    }
    
    Sys.sleep(1)  # Be polite to servers
  }
  
  # Display summary
  cat("\n=== BATCH SUMMARY ===\n")
  print(summary_data)
  
  # Count by status
  cat("\nStatus Breakdown:\n")
  status_counts <- table(summary_data$Status)
  for (status in names(status_counts)) {
    cat("  ", status, ":", status_counts[status], "\n")
  }
  
  # Return combined results
  if (length(all_results) > 0) {
    return(bind_rows(all_results))
  } else {
    return(NULL)
  }
}

# Show FAC numbers available in YAML
show_available_facs <- function() {
  config <- yaml::read_yaml("enhanced_hospitals.yaml")
  
  cat("=== HOSPITALS IN YAML ===\n\n")
  
  for (hospital in config$hospitals) {
    status_symbol <- if (hospital$status == "configured") "✓" else "○"
    cat(sprintf("%s FAC-%s: %s (Pattern: %s)\n", 
                status_symbol,
                hospital$FAC, 
                hospital$name,
                hospital$pattern))
  }
  
  cat("\nTotal hospitals:", length(config$hospitals), "\n")
  configured <- sum(sapply(config$hospitals, function(h) h$status == "configured"))
  cat("Configured:", configured, "\n")
  cat("Needs work:", length(config$hospitals) - configured, "\n")
}

# Usage instructions
cat("=== QUICK SINGLE HOSPITAL TEST LOADED ===\n\n")

cat("USAGE:\n")
cat("1. quick_test(FAC) - Test single hospital by FAC number\n")
cat("2. quick_test_batch(c(FAC1, FAC2, ...)) - Test multiple hospitals\n")
cat("3. show_available_facs() - List all hospitals in YAML\n\n")

cat("EXAMPLES:\n")
cat("# Test Thunder Bay (FAC 935):\n")
cat("quick_test(935)\n\n")

cat("# Test multiple hospitals:\n")
cat("quick_test_batch(c(707, 935, 941, 952))\n\n")

cat("# See what's available:\n")
cat("show_available_facs()\n\n")

cat("The script reads everything from enhanced_hospitals.yaml - just provide FAC number!\n\n")

