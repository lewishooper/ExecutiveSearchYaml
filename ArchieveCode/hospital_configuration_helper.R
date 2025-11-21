# hospital_configuration_helper.R - ENHANCED with Pattern Intelligence
# Save this in E:/ExecutiveSearchYaml/code/
# Version 2.0 - Added intelligent pattern prediction

library(rvest)
library(dplyr)
library(yaml)
library(stringr)

HospitalConfigHelper <- function() {
  
  # NEW: Load pattern intelligence database
  load_pattern_database <- function() {
    db_file <- "pattern_intelligence_database.yaml"
    if (file.exists(db_file)) {
      tryCatch({
        pattern_db <- yaml::read_yaml(db_file)
        return(pattern_db)
      }, error = function(e) {
        cat("Warning: Could not load pattern database:", e$message, "\n")
        cat("Pattern suggestions will be limited.\n")
        return(NULL)
      })
    } else {
      cat("Note: pattern_intelligence_database.yaml not found.\n")
      cat("Pattern suggestions will be limited.\n")
      cat("To enable full intelligence, save the pattern database YAML file.\n\n")
      return(NULL)
    }
  }
  
  # NEW: Analyze HTML and suggest patterns using intelligence database
  suggest_pattern_intelligent <- function(html_snippet, pattern_db = NULL) {
    
    if (is.null(pattern_db)) {
      pattern_db <- load_pattern_database()
    }
    
    if (is.null(pattern_db)) {
      # Fallback to basic pattern detection
      return(suggest_pattern_basic(html_snippet))
    }
    
    html_lower <- tolower(as.character(html_snippet))
    matches <- list()
    
    # Check each pattern from database
    for (pattern_name in names(pattern_db$pattern_intelligence)) {
      pattern <- pattern_db$pattern_intelligence[[pattern_name]]
      score <- 0
      matched_indicators <- character()
      
      # Check key indicators
      for (indicator in pattern$key_indicators) {
        indicator_lower <- tolower(indicator)
        
        # Check for element types
        if (grepl("h2", indicator_lower) && grepl("<h2", html_lower)) {
          score <- score + 20
          matched_indicators <- c(matched_indicators, "h2 elements found")
        }
        if (grepl("h3", indicator_lower) && grepl("<h3", html_lower)) {
          score <- score + 20
          matched_indicators <- c(matched_indicators, "h3 elements found")
        }
        if (grepl("table", indicator_lower) && grepl("<table", html_lower)) {
          score <- score + 25
          matched_indicators <- c(matched_indicators, "table structure found")
        }
        if (grepl("class", indicator_lower) && grepl('class="', html_lower)) {
          # Check for semantic class names
          if (grepl('class="[^"]*name', html_lower) || 
              grepl('class="[^"]*title', html_lower) ||
              grepl('class="[^"]*staff', html_lower)) {
            score <- score + 30
            matched_indicators <- c(matched_indicators, "semantic CSS classes found")
          }
        }
        if (grepl("separator", indicator_lower) || grepl(" - ", indicator_lower)) {
          if (grepl(" - ", html_lower) || grepl(", ", html_lower) || grepl(" \\| ", html_lower)) {
            score <- score + 25
            matched_indicators <- c(matched_indicators, "separator characters found")
          }
        }
        if (grepl("list", indicator_lower) && (grepl("<ul", html_lower) || grepl("<li", html_lower))) {
          score <- score + 20
          matched_indicators <- c(matched_indicators, "list structure found")
        }
        if (grepl("id", indicator_lower) && grepl('id="[a-z]-\\d', html_lower)) {
          score <- score + 25
          matched_indicators <- c(matched_indicators, "ID patterns found")
        }
      }
      
      if (score > 0) {
        matches[[pattern_name]] <- list(
          pattern_name = pattern_name,
          display_name = pattern$pattern_name,
          score = score,
          confidence = if(score > 50) "HIGH" else if(score > 30) "MEDIUM" else "LOW",
          success_rate = pattern$success_rate,
          hospital_count = pattern$hospital_count,
          matched_indicators = unique(matched_indicators)
        )
      }
    }
    
    # Sort by score
    if (length(matches) > 0) {
      matches <- matches[order(sapply(matches, function(x) x$score), decreasing = TRUE)]
    }
    
    return(matches)
  }
  
  # Fallback basic pattern detection (if database not available)
  suggest_pattern_basic <- function(html_snippet) {
    html_lower <- tolower(as.character(html_snippet))
    suggestions <- list()
    
    if (grepl("<h2", html_lower) && grepl("<h3", html_lower)) {
      suggestions[["h2_name_h3_title"]] <- list(
        pattern_name = "h2_name_h3_title",
        display_name = "Sequential h2→h3",
        confidence = "MEDIUM",
        note = "h2 and h3 elements detected"
      )
    }
    
    if (grepl('class="[^"]*name', html_lower) || grepl('class="[^"]*title', html_lower)) {
      suggestions[["div_classes"]] <- list(
        pattern_name = "div_classes",
        display_name = "CSS Class-Based",
        confidence = "HIGH",
        note = "Semantic CSS classes detected"
      )
    }
    
    if (grepl(" - ", html_lower) || grepl(", ", html_lower)) {
      suggestions[["combined_h2"]] <- list(
        pattern_name = "combined_h2",
        display_name = "Combined with Separator",
        confidence = "MEDIUM",
        note = "Separator characters detected"
      )
    }
    
    if (grepl("<table", html_lower)) {
      suggestions[["table_rows"]] <- list(
        pattern_name = "table_rows",
        display_name = "Table Structure",
        confidence = "MEDIUM",
        note = "Table structure detected"
      )
    }
    
    return(suggestions)
  }
  
  # ENHANCED: Analyze hospital structure with intelligent pattern suggestions
  analyze_hospital_structure <- function(fac, name, url) {
    cat("\n")
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("  HOSPITAL STRUCTURE ANALYSIS - WITH PATTERN INTELLIGENCE\n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    cat("FAC:", fac, "\n")
    cat("Name:", name, "\n")
    cat("URL:", url, "\n\n")
    
    tryCatch({
      # Read the page
      cat("Fetching page...\n")
      page <- read_html(url)
      cat("✓ Page loaded successfully\n\n")
      
      # Extract HTML body
      body_html <- page %>% html_node("body") %>% as.character()
      
      # 1. Check for common HTML elements
      cat("───────────────────────────────────────────────────────────────\n")
      cat("HTML ELEMENT ANALYSIS:\n")
      cat("───────────────────────────────────────────────────────────────\n")
      
      h1_elements <- page %>% html_nodes("h1") %>% html_text(trim = TRUE)
      h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
      h3_elements <- page %>% html_nodes("h3") %>% html_text(trim = TRUE)
      p_elements <- page %>% html_nodes("p") %>% html_text(trim = TRUE)
      
      cat("H1 elements:", length(h1_elements), "\n")
      cat("H2 elements:", length(h2_elements), "\n")
      cat("H3 elements:", length(h3_elements), "\n")
      cat("P elements:", length(p_elements), "\n\n")
      
      # Sample outputs
      if (length(h2_elements) > 0) {
        cat("Sample H2 elements (first 3):\n")
        for (i in 1:min(3, length(h2_elements))) {
          cat("  ", i, ". ", substr(h2_elements[i], 1, 60), "\n", sep = "")
        }
        cat("\n")
      }
      
      if (length(h3_elements) > 0) {
        cat("Sample H3 elements (first 3):\n")
        for (i in 1:min(3, length(h3_elements))) {
          cat("  ", i, ". ", substr(h3_elements[i], 1, 60), "\n", sep = "")
        }
        cat("\n")
      }
      
      # 2. Check for CSS classes
      cat("───────────────────────────────────────────────────────────────\n")
      cat("CSS CLASS ANALYSIS:\n")
      cat("───────────────────────────────────────────────────────────────\n")
      
      all_classes <- page %>% html_nodes("[class]") %>% html_attr("class")
      all_classes <- unlist(strsplit(all_classes, "\\s+"))
      
      # Look for leadership-related classes
      leadership_keywords <- c("name", "title", "staff", "leader", "exec", "admin", 
                               "position", "role", "board", "team", "member", "field")
      
      leadership_classes <- all_classes[grepl(paste(leadership_keywords, collapse = "|"), 
                                              all_classes, ignore.case = TRUE)]
      unique_leadership_classes <- unique(leadership_classes)
      
      if (length(unique_leadership_classes) > 0) {
        cat("Leadership-related CSS classes found:\n")
        for (cls in unique_leadership_classes[1:min(10, length(unique_leadership_classes))]) {
          cat("  • class=\"", cls, "\"\n", sep = "")
        }
        cat("\n")
      } else {
        cat("No obvious leadership-related classes found\n\n")
      }
      
      # 3. Check for tables
      cat("───────────────────────────────────────────────────────────────\n")
      cat("TABLE STRUCTURE ANALYSIS:\n")
      cat("───────────────────────────────────────────────────────────────\n")
      
      tables <- page %>% html_nodes("table")
      cat("Tables found:", length(tables), "\n")
      
      if (length(tables) > 0) {
        cat("First table structure:\n")
        first_table <- tables[[1]]
        rows <- first_table %>% html_nodes("tr")
        cat("  Rows:", length(rows), "\n")
        if (length(rows) > 0) {
          first_row <- rows[[1]] %>% html_nodes("td, th") %>% html_text(trim = TRUE)
          cat("  Columns:", length(first_row), "\n")
          cat("  First row sample:", paste(substr(first_row, 1, 30), collapse = " | "), "\n")
        }
        cat("\n")
      } else {
        cat("No tables found\n\n")
      }
      
      # 4. Check for lists
      cat("───────────────────────────────────────────────────────────────\n")
      cat("LIST STRUCTURE ANALYSIS:\n")
      cat("───────────────────────────────────────────────────────────────\n")
      
      ul_count <- length(page %>% html_nodes("ul"))
      ol_count <- length(page %>% html_nodes("ol"))
      li_elements <- page %>% html_nodes("li") %>% html_text(trim = TRUE)
      
      cat("Unordered lists (ul):", ul_count, "\n")
      cat("Ordered lists (ol):", ol_count, "\n")
      cat("List items (li):", length(li_elements), "\n")
      
      if (length(li_elements) > 0) {
        cat("\nSample list items (first 3):\n")
        for (i in 1:min(3, length(li_elements))) {
          cat("  ", i, ". ", substr(li_elements[i], 1, 60), "\n", sep = "")
        }
      }
      cat("\n")
      
      # 5. NEW: INTELLIGENT PATTERN SUGGESTIONS
      cat("═══════════════════════════════════════════════════════════════\n")
      cat("  🤖 INTELLIGENT PATTERN PREDICTIONS\n")
      cat("═══════════════════════════════════════════════════════════════\n\n")
      
      # Load pattern database
      pattern_db <- load_pattern_database()
      
      # Get pattern suggestions
      suggestions <- suggest_pattern_intelligent(body_html, pattern_db)
      
      if (length(suggestions) > 0) {
        cat("Based on analysis of 38 successful hospitals:\n\n")
        
        for (i in 1:min(3, length(suggestions))) {
          suggestion <- suggestions[[i]]
          cat("PREDICTION #", i, ": ", suggestion$display_name, "\n", sep = "")
          cat("  Pattern Code: ", suggestion$pattern_name, "\n", sep = "")
          cat("  Confidence: ", suggestion$confidence, "\n", sep = "")
          
          if (!is.null(suggestion$success_rate)) {
            cat("  Success Rate: ", suggestion$success_rate, " (", 
                suggestion$hospital_count, " hospitals)\n", sep = "")
          }
          
          if (length(suggestion$matched_indicators) > 0) {
            cat("  Why: ", paste(suggestion$matched_indicators, collapse = ", "), "\n", sep = "")
          }
          
          # Show example hospitals if available
          if (!is.null(pattern_db) && !is.null(pattern_db$pattern_intelligence[[suggestion$pattern_name]])) {
            pattern_info <- pattern_db$pattern_intelligence[[suggestion$pattern_name]]
            if (!is.null(pattern_info$successful_hospitals) && length(pattern_info$successful_hospitals) > 0) {
              cat("  Similar to: ")
              example_hospitals <- sapply(pattern_info$successful_hospitals[1:min(3, length(pattern_info$successful_hospitals))], 
                                          function(h) paste0("FAC-", h$fac))
              cat(paste(example_hospitals, collapse = ", "), "\n")
            }
          }
          
          cat("\n")
        }
        
        # Show YAML template for top suggestion
        top_suggestion <- suggestions[[1]]
        cat("───────────────────────────────────────────────────────────────\n")
        cat("RECOMMENDED YAML CONFIGURATION:\n")
        cat("───────────────────────────────────────────────────────────────\n\n")
        
        if (!is.null(pattern_db) && !is.null(pattern_db$pattern_intelligence[[top_suggestion$pattern_name]])) {
          yaml_template <- pattern_db$pattern_intelligence[[top_suggestion$pattern_name]]$yaml_template
          
          cat("- FAC: \"", sprintf("%03d", as.numeric(fac)), "\"\n", sep = "")
          cat("  name: \"", name, "\"\n", sep = "")
          cat("  url: \"", url, "\"\n", sep = "")
          cat("  expected_executives: 6  # UPDATE based on actual count\n")
          cat(yaml_template, "\n")
          cat("  status: \"needs_testing\"\n\n")
        }
        
        cat("📖 For detailed examples, see:\n")
        cat("   - Published web tool (bookmarked)\n")
        cat("   - Hospital_Scraper_Pattern_Intelligence_Reference.md\n")
        cat("   - pattern_intelligence_database.yaml\n\n")
        
        return(list(
          suggested_pattern = top_suggestion$pattern_name,
          confidence = top_suggestion$confidence,
          all_suggestions = suggestions,
          h2_count = length(h2_elements),
          h3_count = length(h3_elements),
          leadership_classes = unique_leadership_classes
        ))
        
      } else {
        # Fallback if no matches
        cat("No strong pattern match detected.\n")
        cat("Manual inspection recommended.\n")
        cat("Common patterns to check:\n")
        cat("  1. div_classes - if you see CSS classes like .name or .title\n")
        cat("  2. combined_h2 - if name and title are together with separator\n")
        cat("  3. h2_name_h3_title - if h2 for names, h3 for titles\n\n")
        
        return(list(
          suggested_pattern = "needs_manual_inspection",
          h2_count = length(h2_elements),
          h3_count = length(h3_elements),
          leadership_classes = unique_leadership_classes
        ))
      }
      
    }, error = function(e) {
      cat("❌ ERROR analyzing ", url, ": ", e$message, "\n", sep = "")
      return(NULL)
    })
  }
  
  # Show pattern guide (existing function)
  show_pattern_guide <- function() {
    cat("\n=== HOSPITAL SCRAPER PATTERN GUIDE ===\n\n")
    
    cat("COMMON PATTERNS (in order of frequency):\n\n")
    
    cat("1. DIV_CLASSES (21% - MOST COMMON):\n")
    cat("   - Names/titles in divs with semantic CSS classes\n")
    cat("   - Classes like: .name, .title, .staff-name, .position\n")
    cat("   - Example: <div class='name'>John</div><div class='title'>CEO</div>\n\n")
    
    cat("2. COMBINED_H2 (11% - VERY HIGH SUCCESS):\n")
    cat("   - Name and title together in same element\n")
    cat("   - Separated by: ' - ', ', ', ' | '\n")
    cat("   - Example: <h2>John Smith - CEO</h2>\n\n")
    
    cat("3. H2_NAME_H3_TITLE (8%):\n")
    cat("   - Names in H2, titles in H3\n")
    cat("   - Sequential pairs\n")
    cat("   - Example: <h2>John Smith</h2><h3>CEO</h3>\n\n")
    
    cat("4. H2_NAME_P_TITLE (8%):\n")
    cat("   - Names in H2, titles in P\n")
    cat("   - Example: <h2>John Smith</h2><p>CEO</p>\n\n")
    
    cat("5. TABLE_ROWS (5%):\n")
    cat("   - Tabular structure\n")
    cat("   - Example: <td>John Smith</td><td>CEO</td>\n\n")
    
    cat("6. LIST_ITEMS (8%):\n")
    cat("   - List with separators\n")
    cat("   - Example: <li>John Smith | CEO</li>\n\n")
    
    cat("For complete details, see:\n")
    cat("  • Published pattern intelligence web tool\n")
    cat("  • Hospital_Scraper_Pattern_Intelligence_Reference.md\n")
    cat("  • pattern_intelligence_database.yaml\n\n")
  }
  
  # Test hospital configuration (existing function - reads from YAML)
  test_hospital_config <- function(fac, name, url, pattern) {
    cat("\n=== TESTING HOSPITAL CONFIGURATION ===\n\n")
    cat("FAC:", fac, "\n")
    cat("Name:", name, "\n")
    cat("Pattern:", pattern, "\n\n")
    
    # Source the scraper
    if (file.exists("pattern_based_scraper.R")) {
      source("pattern_based_scraper.R")
    } else {
      cat("ERROR: pattern_based_scraper.R not found\n")
      return(NULL)
    }
    
    # Initialize scraper
    scraper <- PatternBasedScraper()
    
    # Read config from YAML
    if (file.exists("enhanced_hospitals.yaml")) {
      config <- yaml::read_yaml("enhanced_hospitals.yaml")
      
      # Find hospital in config
      fac_formatted <- sprintf("%03d", as.numeric(fac))
      hospital_info <- NULL
      
      for (h in config$hospitals) {
        if (h$FAC == fac_formatted) {
          hospital_info <- h
          break
        }
      }
      
      if (!is.null(hospital_info)) {
        cat("Found configuration in enhanced_hospitals.yaml\n")
        cat("Testing with actual YAML configuration...\n\n")
        
        result <- scraper$scrape_hospital(hospital_info)
        
        cat("\n=== TEST RESULTS ===\n")
        valid_count <- sum(!is.na(result$executive_name) & !is.na(result$executive_title))
        cat("Executives found:", valid_count, "\n")
        
        if (valid_count > 0) {
          cat("\nExecutives:\n")
          for (i in 1:nrow(result)) {
            if (!is.na(result$executive_name[i])) {
              cat(sprintf("  %d. %s - %s\n", i, result$executive_name[i], result$executive_title[i]))
            }
          }
        }
        
        return(result)
        
      } else {
        cat("Hospital not found in enhanced_hospitals.yaml\n")
        cat("Please add configuration first.\n")
        return(NULL)
      }
    } else {
      cat("ERROR: enhanced_hospitals.yaml not found\n")
      return(NULL)
    }
  }
  
  # Return helper functions
  return(list(
    analyze_hospital_structure = analyze_hospital_structure,
    test_hospital_config = test_hospital_config,
    show_pattern_guide = show_pattern_guide,
    load_pattern_database = load_pattern_database,
    suggest_pattern_intelligent = suggest_pattern_intelligent
  ))
}

# Initialize helper
helper <- HospitalConfigHelper()

cat("═══════════════════════════════════════════════════════════════\n")
cat("  HOSPITAL CONFIGURATION HELPER v2.0 - WITH AI INTELLIGENCE\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("✨ NEW: Intelligent pattern prediction based on 38 hospitals!\n\n")

cat("AVAILABLE FUNCTIONS:\n")
cat("1. helper$analyze_hospital_structure(fac, name, url)\n")
cat("   → Analyzes HTML + suggests best patterns with AI\n\n")
cat("2. helper$test_hospital_config(fac, name, url, pattern)\n")
cat("   → Tests configuration from enhanced_hospitals.yaml\n\n")
cat("3. helper$show_pattern_guide()\n")
cat("   → Quick pattern reference\n\n")
cat("4. helper$load_pattern_database()\n")
cat("   → Load pattern intelligence database\n\n")

cat("INTELLIGENT WORKFLOW:\n")
cat("Step 1: helper$analyze_hospital_structure(FAC, 'Name', 'URL')\n")
cat("        → Gets AI predictions based on 38 successful hospitals\n")
cat("Step 2: Use suggested YAML configuration\n")
cat("Step 3: Add to enhanced_hospitals.yaml\n")
cat("Step 4: Test with quick_test(FAC)\n\n")

cat("EXAMPLE:\n")
cat("helper$analyze_hospital_structure(726, 'Midland Hospital', 'URL')\n")
cat("# Shows: Top 3 pattern predictions with confidence scores\n")
cat("# Explains: Why each pattern matches (indicators found)\n")
cat("# Suggests: Ready-to-use YAML configuration\n\n")

cat("📚 REFERENCE MATERIALS:\n")
cat("  • Published web tool (bookmarked) - interactive predictor\n")
cat("  • Hospital_Scraper_Pattern_Intelligence_Reference.md\n")
cat("  • pattern_intelligence_database.yaml\n\n")

cat("Ready to configure hospitals with AI assistance! 🚀\n\n")