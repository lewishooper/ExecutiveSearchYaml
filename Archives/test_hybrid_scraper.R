# test_hybrid_scraper.R - Test the hybrid YAML-configured scraper
# Save this in E:/ExecutiveSearchYaml/code/

setwd("E:/ExecutiveSearchYaml/code/")
source("hybrid_scraper.R")

# Initialize hybrid scraper
hybrid <- HybridScraper()

cat("=== HYBRID YAML-CONFIGURED SCRAPER TEST ===\n\n")

# Test specific hospitals with their configurations
test_configured_hospitals <- function(fac_numbers = c(707, 624, 596, 661, 953)) {
  cat("=== TESTING CONFIGURED HOSPITALS ===\n\n")
  
  hospitals_data <- yaml::read_yaml("hybrid_hospitals.yaml")
  hospitals <- hospitals_data$hospitals
  
  results <- list()
  
  for (fac_num in fac_numbers) {
    # Find hospital by FAC number
    target_hospital <- NULL
    for (h in hospitals) {
      if (as.numeric(h$FAC) == fac_num) {
        target_hospital <- h
        break
      }
    }
    
    if (!is.null(target_hospital)) {
      cat("=== FAC-", fac_num, ": ", target_hospital$name, "===\n")
      cat("Method:", target_hospital$scrape_method, "\n")
      cat("Expected:", target_hospital$expected_executives, "executives\n")
      
      # Run the hybrid scraper
      result <- hybrid$scrape_hospital(target_hospital)
      results[[as.character(fac_num)]] <- result
      
      cat("Results:\n")
      if (nrow(result) > 0 && !is.na(result$executive_name[1])) {
        for (i in 1:nrow(result)) {
          cat(sprintf("  %d. %s → %s\n", i, result$executive_name[i], result$executive_title[i]))
        }
        
        # Check for specific missing people
        missing_people <- c("Dr. Bharat Chawla", "Dr. Dimitri Louvish", "Dr. Roger Musa", "Carmine Stumpo")
        for (person in missing_people) {
          found <- any(grepl(person, result$executive_name, ignore.case = TRUE))
          if (found) {
            cat("  ✓ FOUND:", person, "\n")
          }
        }
        
      } else {
        cat("  No results found\n")
      }
      
      cat("Notes:", target_hospital$notes, "\n")
      cat(rep("=", 70), "\n\n")
      
    } else {
      cat("Hospital with FAC", fac_num, "not found in configuration\n\n")
    }
    
    Sys.sleep(1)
  }
  
  return(results)
}

# Test all configured hospitals
test_all_configured <- function(yaml_file = "hybrid_hospitals.yaml") {
  
  hospitals_data <- yaml::read_yaml(yaml_file)
  hospitals <- hospitals_data$hospitals
  
  cat("Testing", length(hospitals), "configured hospitals with hybrid scraper...\n\n")
  
  results <- hybrid$scrape_batch(hospitals)
  
  return(results)
}

# Add a hospital to the configuration
add_hospital_config <- function(fac, name, url, method = "generic", config = NULL, notes = "") {
  
  # Read existing config
  hospitals_data <- yaml::read_yaml("hybrid_hospitals.yaml")
  
  # Create new hospital entry
  new_hospital <- list(
    FAC = sprintf("%03d", as.numeric(fac)),
    name = name,
    url = url,
    scrape_method = method,
    notes = notes
  )
  
  # Add specific config based on method
  if (method == "table_configured" && !is.null(config)) {
    new_hospital$table_config <- config
  } else if (method == "custom" && !is.null(config)) {
    new_hospital$custom_config <- config
  } else if (method == "subpage" && !is.null(config)) {
    new_hospital$subpage_config <- config
  }
  
  # Add to hospitals list
  hospitals_data$hospitals <- c(hospitals_data$hospitals, list(new_hospital))
  
  # Write back to file
  yaml::write_yaml(hospitals_data, "hybrid_hospitals.yaml")
  
  cat("Added FAC-", fac, ":", name, "with method", method, "\n")
}

# Generate template configuration for a failing hospital
suggest_config_for_hospital <- function(fac_number, hospital_name, hospital_url) {
  cat("=== SUGGESTED CONFIGURATION FOR FAC-", fac_number, "===\n")
  cat("Hospital:", hospital_name, "\n")
  cat("URL:", hospital_url, "\n\n")
  
  # Basic template
  cat("Add this to hybrid_hospitals.yaml:\n")
  cat("---\n")
  cat("- FAC: \"", sprintf("%03d", fac_number), "\"\n", sep = "")
  cat("  name: \"", hospital_name, "\"\n", sep = "")
  cat("  url: \"", hospital_url, "\"\n", sep = "")
  cat("  scrape_method: \"custom\"  # or table_configured, subpage, generic_h2_h3\n")
  cat("  expected_executives: 5  # adjust as needed\n")
  cat("  custom_config:\n")
  cat("    name_selectors: [\"h2\", \"h3\"]  # CSS selectors for names\n")
  cat("    title_selectors: [\"p\", \"h3\"]   # CSS selectors for titles\n")
  cat("    additional_search:  # optional - manually add missing people\n")
  cat("      - \"Dr. Missing Person, Chief of Staff\"\n")
  cat("  notes: \"Configuration needed - add specific patterns\"\n")
  cat("---\n\n")
}

# Update existing hospital configuration
update_hospital_config <- function(fac_number, updates) {
  hospitals_data <- yaml::read_yaml("hybrid_hospitals.yaml")
  
  # Find and update the hospital
  for (i in seq_along(hospitals_data$hospitals)) {
    if (as.numeric(hospitals_data$hospitals[[i]]$FAC) == fac_number) {
      # Update specified fields
      for (field in names(updates)) {
        hospitals_data$hospitals[[i]][[field]] <- updates[[field]]
      }
      
      # Write back to file
      yaml::write_yaml(hospitals_data, "hybrid_hospitals.yaml")
      cat("Updated FAC-", fac_number, "configuration\n")
      return()
    }
  }
  
  cat("Hospital FAC-", fac_number, "not found in configuration\n")
}

# Usage instructions
cat("HYBRID SCRAPER FUNCTIONS LOADED:\n")
cat("1. test_configured_hospitals(c(707, 624, 596)) - Test hospitals with configurations\n")
cat("2. test_all_configured() - Test all configured hospitals\n")
cat("3. add_hospital_config(fac, name, url, method, config) - Add new hospital config\n")
cat("4. suggest_config_for_hospital(fac, name, url) - Generate config template\n")
cat("5. update_hospital_config(fac, list(field=value)) - Update existing config\n\n")

cat("WORKFLOW:\n")
cat("1. Test configured hospitals to see which work:\n")
cat("   test_configured_hospitals(c(707, 624, 596, 661, 953))\n\n")
cat("2. For failing hospitals, add configurations:\n")
cat("   suggest_config_for_hospital(999, 'Hospital Name', 'URL')\n\n")
cat("3. Test all configured hospitals:\n")
cat("   hybrid_results <- test_all_configured()\n\n")

cat("EXAMPLE - Add a hospital with custom configuration:\n")
cat("add_hospital_config(\n")
cat("  fac = 999,\n")
cat("  name = 'Example Hospital',\n") 
cat("  url = 'https://example.com/leadership',\n")
cat("  method = 'custom',\n")
cat("  config = list(\n")
cat("    name_selectors = c('h2', 'h3'),\n")
cat("    title_selectors = c('p'),\n")
cat("    additional_search = c('Dr. Missing Person, Chief of Staff')\n")
cat("  ),\n")
cat("  notes = 'Custom configuration for specific structure'\n")
cat(")\n\n")