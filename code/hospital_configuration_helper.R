# hospital_configuration_helper.R - Tools to help configure hospitals
# Save this in E:/ExecutiveSearchYaml/code/

setwd("E:/ExecutiveSearchYaml/code/")
library(rvest)
library(yaml)
source("pattern_based_scraper.R")

HospitalConfigHelper <- function() {
  
  # Analyze a hospital's HTML structure to suggest configuration
  analyze_hospital_structure <- function(fac, name, url) {
    cat("=== ANALYZING", name, "(FAC-", fac, ") ===\n")
    cat("URL:", url, "\n\n")
    
    tryCatch({
      page <- read_html(url)
      
      # 1. Count different element types
      cat("ELEMENT COUNTS:\n")
      cat("  H1:", length(page %>% html_nodes("h1")), "\n")
      cat("  H2:", length(page %>% html_nodes("h2")), "\n")
      cat("  H3:", length(page %>% html_nodes("h3")), "\n")
      cat("  H4:", length(page %>% html_nodes("h4")), "\n")
      cat("  P:", length(page %>% html_nodes("p")), "\n")
      cat("  Tables:", length(page %>% html_nodes("table")), "\n")
      cat("  Lists (UL/OL):", length(page %>% html_nodes("ul, ol")), "\n\n")
      
      # 2. Sample H2 content (potential names)
      h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
      cat("SAMPLE H2 ELEMENTS (first 10):\n")
      for (i in 1:min(10, length(h2_elements))) {
        looks_like_name <- grepl("^(Dr\\.?\\s+)?[A-Z][a-z]+\\s+[A-Z][a-z]+$", h2_elements[i])
        cat(sprintf("  %2d: %s %s\n", i, h2_elements[i], 
                    ifelse(looks_like_name, "← LOOKS LIKE NAME", "")))
      }
      cat("\n")
      
      # 3. Sample H3 content (potential titles)
      h3_elements <- page %>% html_nodes("h3") %>% html_text(trim = TRUE)
      cat("SAMPLE H3 ELEMENTS (first 10):\n")
      for (i in 1:min(10, length(h3_elements))) {
        looks_like_title <- grepl("(CEO|Chief|President|Director|Officer|Administrator|Manager|VP)", 
                                  h3_elements[i], ignore.case = TRUE)
        cat(sprintf("  %2d: %s %s\n", i, h3_elements[i], 
                    ifelse(looks_like_title, "← LOOKS LIKE TITLE", "")))
      }
      cat("\n")
      
      # 4. Check for common class patterns
      cat("COMMON CSS CLASSES FOUND:\n")
      all_classes <- page %>% html_nodes("*") %>% html_attr("class")
      all_classes <- all_classes[!is.na(all_classes)]
      
      # Look for leadership-related classes
      leadership_classes <- grep("(name|title|executive|leader|staff|team|bio|card)", 
                                 all_classes, ignore.case = TRUE, value = TRUE)
      
      unique_leadership_classes <- unique(leadership_classes)[1:min(10, length(unique(leadership_classes)))]
      
      if (length(unique_leadership_classes) > 0) {
        for (class_name in unique_leadership_classes) {
          cat("  ", class_name, "\n")
        }
      } else {
        cat("  No obvious leadership-related classes found\n")
      }
      cat("\n")
      
      # 5. Suggest pattern based on analysis
      cat("SUGGESTED PATTERN:\n")
      
      name_h2_count <- sum(sapply(h2_elements, function(x) 
        grepl("^(Dr\\.?\\s+)?[A-Z][a-z]+\\s+[A-Z][a-z]+$", x)))
      title_h3_count <- sum(sapply(h3_elements, function(x) 
        grepl("(CEO|Chief|President|Director|Officer|Administrator)", x, ignore.case = TRUE)))
      
      if (name_h2_count >= 3 && title_h3_count >= 3) {
        cat("  RECOMMENDED: h2_name_h3_title\n")
        cat("  REASON: Found", name_h2_count, "name-like H2s and", title_h3_count, "title-like H3s\n")
        suggested_pattern <- "h2_name_h3_title"
      } else {
        cat("  RECOMMENDED: Needs further analysis\n")
        cat("  REASON: H2/H3 pattern not clear (", name_h2_count, "names,", title_h3_count, "titles)\n")
        suggested_pattern <- "custom"
      }
      
      cat("\n")
      
      # 6. Generate YAML configuration
      cat("SUGGESTED YAML CONFIGURATION:\n")
      cat("---\n")
      cat("- FAC: \"", sprintf("%03d", as.numeric(fac)), "\"\n", sep = "")
      cat("  name: \"", name, "\"\n", sep = "")
      cat("  url: \"", url, "\"\n", sep = "")
      cat("  pattern: \"", suggested_pattern, "\"\n", sep = "")
      cat("  expected_executives: ", max(3, min(name_h2_count, title_h3_count, 8)), "\n", sep = "")
      cat("  html_structure:\n")
      
      if (suggested_pattern == "h2_name_h3_title") {
        cat("    name_element: \"h2\"\n")
        cat("    title_element: \"h3\"\n")
        cat("    notes: \"h2=Name, h3=Title pattern detected\"\n")
      } else {
        cat("    name_element: \"TBD\"  # Specify after manual inspection\n")
        cat("    title_element: \"TBD\"  # Specify after manual inspection\n") 
        cat("    notes: \"Needs custom configuration\"\n")
      }
      
      cat("  status: \"needs_testing\"\n")
      cat("---\n\n")
      
      return(list(
        pattern = suggested_pattern,
        name_h2_count = name_h2_count,
        title_h3_count = title_h3_count,
        leadership_classes = unique_leadership_classes
      ))
      
    }, error = function(e) {
      cat("Error analyzing", url, ":", e$message, "\n")
      return(NULL)
    })
  }
  
  # Add multiple hospitals to configuration at once
  add_hospital_batch <- function(hospitals_info) {
    cat("=== ADDING BATCH OF", length(hospitals_info), "HOSPITALS ===\n\n")
    
    # Read existing config
    if (file.exists("enhanced_hospitals.yaml")) {
      config <- yaml::read_yaml("enhanced_hospitals.yaml")
    } else {
      config <- list(hospitals = list())
    }
    
    for (hospital in hospitals_info) {
      cat("Analyzing", hospital$name, "(FAC-", hospital$fac, ")...\n")
      
      # Analyze structure
      analysis <- analyze_hospital_structure(hospital$fac, hospital$name, hospital$url)
      
      # Create hospital entry
      new_hospital <- list(
        FAC = sprintf("%03d", as.numeric(hospital$fac)),
        name = hospital$name,
        url = hospital$url,
        pattern = if(!is.null(analysis)) analysis$pattern else "h2_name_h3_title",
        expected_executives = hospital$expected %||% 5,
        html_structure = list(
          name_element = "h2",
          title_element = "h3", 
          notes = "Auto-generated configuration - verify manually"
        ),
        status = "needs_testing"
      )
      
      # Add to config
      config$hospitals <- c(config$hospitals, list(new_hospital))
      
      pattern_used <- if(!is.null(analysis)) analysis$pattern else "h2_name_h3_title"
      cat("  → Added with pattern:", pattern_used, "\n\n")
    }
    
    # Write updated config
    yaml::write_yaml(config, "enhanced_hospitals.yaml")
    cat("Updated enhanced_hospitals.yaml with", length(hospitals_info), "hospitals\n")
  }
  
  # Test a hospital configuration - UPDATED to read from YAML
  test_hospital_config <- function(fac, name, url, pattern = "h2_name_h3_title", config_file = "enhanced_hospitals.yaml") {
    cat("=== TESTING CONFIGURATION FOR", name, "===\n")
    
    # Try to read existing config from YAML first
    hospital_info <- NULL
    
    if (file.exists(config_file)) {
      config <- yaml::read_yaml(config_file)
      if (!is.null(config$hospitals)) {
        # Look for this hospital in the config
        for (hospital in config$hospitals) {
          if (hospital$FAC == sprintf("%03d", as.numeric(fac))) {
            hospital_info <- hospital
            cat("Found existing configuration in YAML\n")
            break
          }
        }
      }
    }
    
    # If not found in YAML, create basic structure
    if (is.null(hospital_info)) {
      cat("No existing configuration found, creating basic test structure\n")
      hospital_info <- list(
        FAC = sprintf("%03d", as.numeric(fac)),
        name = name,
        url = url,
        pattern = pattern,
        expected_executives = 5,
        html_structure = list(
          name_element = "h2",
          title_element = "h3",
          notes = "Test configuration"
        )
      )
    }
    
    # Initialize scraper and test
    scraper <- PatternBasedScraper()
    result <- scraper$scrape_hospital(hospital_info)
    
    cat("TEST RESULTS:\n")
    if (nrow(result) > 0 && !is.na(result$executive_name[1])) {
      for (i in 1:nrow(result)) {
        cat(sprintf("  %d. %s → %s\n", i, result$executive_name[i], result$executive_title[i]))
      }
      
      cat("\nSUCCESS: Found", nrow(result), "executives\n")
      cat("RECOMMENDATION: Configuration working correctly\n")
      
    } else {
      cat("  No valid results found\n")
      cat("RECOMMENDATION: Check pattern or add to YAML configuration\n")
    }
    
    return(result)
  }
  
  # Quick pattern identification guide
  show_pattern_guide <- function() {
    cat("=== HOSPITAL PATTERN IDENTIFICATION GUIDE ===\n\n")
    
    cat("COMMON PATTERNS TO LOOK FOR:\n\n")
    
    cat("1. H2_NAME_H3_TITLE (most common):\n")
    cat("   - Executive names in <h2> elements\n")
    cat("   - Titles in <h3> elements immediately following\n")
    cat("   - Example: <h2>John Smith</h2> <h3>CEO</h3>\n\n")
    
    cat("2. COMBINED_H2 (name and title together):\n")
    cat("   - Both name and title in same element\n")
    cat("   - Usually separated by ' - ' or ', '\n")
    cat("   - Example: <h2>John Smith - CEO</h2>\n")
    cat("   - Can also be h3: <h3>John Smith - CEO</h3>\n\n")
    
    cat("3. TABLE_ROWS (structured data):\n")
    cat("   - Names and titles in table columns\n")
    cat("   - Usually column 1 = name, column 2 = title\n")
    cat("   - Example: <td>John Smith</td><td>CEO</td>\n\n")
    
    cat("4. H2_NAME_P_TITLE:\n")
    cat("   - Names in <h2>, titles in following <p>\n")
    cat("   - Example: <h2>John Smith</h2> <p>CEO</p>\n\n")
    
    cat("5. BOARDCARD_GALLERY (special pattern):\n")
    cat("   - Names and titles in div.boardcard elements\n")
    cat("   - Format: Name, Title separated by comma\n")
    cat("   - Example: <div class='boardcard'>John Smith, CEO</div>\n\n")
    
    cat("6. DIV_CLASSES (CSS-based):\n")
    cat("   - Names/titles in divs with specific classes\n")
    cat("   - Example: <div class='name'>John</div><div class='title'>CEO</div>\n\n")
    
    cat("INSPECTION CHECKLIST:\n")
    cat("□ Right-click → Inspect Element on executive names\n")
    cat("□ Note the HTML tag (h1, h2, h3, p, div, span, td, li)\n")
    cat("□ Check for CSS classes or IDs\n")
    cat("□ See if names and titles are in same or different elements\n")
    cat("□ Look for consistent patterns across all executives\n")
    cat("□ Note any missing people not in main structure\n\n")
  }
  
  # Generate batch configuration from a list
  generate_batch_config <- function(hospital_list_file = "hospital_batch.csv") {
    cat("=== GENERATING BATCH CONFIGURATION ===\n")
    
    if (!file.exists(hospital_list_file)) {
      cat("Creating template file:", hospital_list_file, "\n")
      template <- data.frame(
        fac = c("001", "002", "003"),
        name = c("Example Hospital 1", "Example Hospital 2", "Example Hospital 3"),
        url = c("https://example1.com/leadership", "https://example2.com/team", "https://example3.com/admin"),
        expected = c(5, 6, 4)
      )
      write.csv(template, hospital_list_file, row.names = FALSE)
      cat("Please fill out", hospital_list_file, "with your hospital information\n")
      return()
    }
    
    # Read hospital list
    hospitals <- read.csv(hospital_list_file, stringsAsFactors = FALSE)
    
    cat("Found", nrow(hospitals), "hospitals in", hospital_list_file, "\n\n")
    
    # Convert to list format for batch processing
    hospitals_info <- list()
    for (i in 1:nrow(hospitals)) {
      hospitals_info[[i]] <- list(
        fac = hospitals$fac[i],
        name = hospitals$name[i], 
        url = hospitals$url[i],
        expected = if(!is.na(hospitals$expected[i])) hospitals$expected[i] else 5
      )
    }
    
    # Process batch
    add_hospital_batch(hospitals_info)
  }
  
  return(list(
    analyze_hospital_structure = analyze_hospital_structure,
    add_hospital_batch = add_hospital_batch,
    test_hospital_config = test_hospital_config,
    show_pattern_guide = show_pattern_guide,
    generate_batch_config = generate_batch_config
  ))
}

# Initialize helper
helper <- HospitalConfigHelper()

cat("=== HOSPITAL CONFIGURATION HELPER LOADED ===\n\n")

cat("AVAILABLE FUNCTIONS:\n")
cat("1. helper$analyze_hospital_structure(fac, name, url) - Analyze HTML structure\n")
cat("2. helper$test_hospital_config(fac, name, url, pattern) - Test configuration (reads from YAML)\n")  
cat("3. helper$show_pattern_guide() - Show pattern identification guide\n")
cat("4. helper$generate_batch_config('file.csv') - Generate config from CSV\n\n")

cat("WORKFLOW FOR ADDING NEW HOSPITALS:\n")
cat("Step 1: Use browser to find leadership page URL\n")
cat("Step 2: helper$analyze_hospital_structure(624, 'Hospital Name', 'URL')\n")
cat("Step 3: Review suggested configuration and manually verify\n")
cat("Step 4: Add to enhanced_hospitals.yaml with any missing_people\n")
cat("Step 5: helper$test_hospital_config(624, 'Hospital Name', 'URL', 'pattern')\n\n")

cat("EXAMPLE USAGE:\n")
cat("# Analyze a hospital:\n")
cat("helper$analyze_hospital_structure(935, 'Thunder Bay', 'URL')\n\n")
cat("# Test configuration (now reads missing_people from YAML):\n")
cat("helper$test_hospital_config(935, 'Thunder Bay', 'URL', 'boardcard_gallery')\n\n")

cat("# Show pattern guide:\n")
cat("helper$show_pattern_guide()\n\n")