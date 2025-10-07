# pattern_based_scraper.R - Enhanced scraper with 10 pattern-based approaches
# Save this in E:/ExecutiveSearchYaml/code/
# UPDATED: Added missing_people support to Patterns 5 & 8, fixed Pattern 8 for FAC 777

library(rvest)
library(dplyr)
library(stringr)
library(yaml)

PatternBasedScraper <- function() {
  
  # Load configuration data
  load_config <- function(config_file = "enhanced_hospitals.yaml") {
    config <- yaml::read_yaml(config_file)
    return(config)
  }
  
  # Normalize text - handle non-breaking spaces, HTML entities, etc.
  normalize_text <- function(text) {
    if (is.na(text)) return(text)
    text <- gsub("\u00A0", " ", text)    # Non-breaking spaces (ASCII 160)
    text <- gsub("&amp;", "&", text)     # HTML ampersand entity
    text <- gsub("&nbsp;", " ", text)    # HTML non-breaking space entity
    text <- gsub("\\s+", " ", text)      # Multiple spaces to single space
    text <- trimws(text)
    return(text)
  }
  
 ## nEW
  
  ## END nEW
  
  normalize_name_for_matching <- function(name) {
    if (is.na(name)) return(name)
    
    name <- gsub("[àáâãäåÀÁÂÃÄÅ]", "a", name)
    name <- gsub("[èéêëÈÉÊË]", "e", name)
    name <- gsub("[ìíîïÌÍÎÏ]", "i", name)
    name <- gsub("[òóôõöÒÓÔÕÖ]", "o", name)
    name <- gsub("[ùúûüÙÚÛÜ]", "u", name)
    name <- gsub("[çÇ]", "c", name)
    name <- gsub("[ñÑ]", "n", name)
    name <- gsub("[ýÝ]", "y", name)
    name <- gsub("ß", "ss", name)
    name <- gsub("[æÆ]", "ae", name)
    name <- gsub("[œŒ]", "oe", name)
    
    return(name)
  }
  
  
  # Check if text matches name patterns
  # Check if text matches name patternsNew
  is_executive_name <- function(text, config) {
    if (is.na(text) || nchar(trimws(text)) < 3) return(FALSE)
    
    # Get name patterns from config
    name_patterns <- c(
      config$name_patterns$standard,
      config$name_patterns$with_titles,
      config$name_patterns$with_credentials,
      config$name_patterns$hyphenated_names,
      config$name_patterns$complex_credentials,
      config$name_patterns$internal_capitals,
      config$name_patterns$accented_names,
      config$name_patterns$flexible
    )
    
    # Clean text first (but preserve hyphens in names)
    clean_text <- str_remove_all(text, "\\s*ext\\.?\\s*\\d+.*$")
    clean_text <- trimws(clean_text)
    
    # Check against patterns with original text
    matches_pattern <- any(sapply(name_patterns, function(p) grepl(p, clean_text)))
    
    # If doesn't match, try normalized version (without accents)
    if (!matches_pattern) {
      normalized <- normalize_name_for_matching(clean_text)
      matches_pattern <- any(sapply(name_patterns, function(p) grepl(p, normalized)))
      
      if (matches_pattern) {
        cat("DEBUG: Matched normalized name: '", text, "' (normalized: '", normalized, "')\n", sep = "")
      }
    }
    
    # Exclude obvious non-names
    non_names <- c(
      "^(About|Our|The|Welcome|Contact|Services|Programs|News|Events)\\b",
      "^(Ontario|Ministry|Government|Hospital|Health|Department)\\b",
      "^(For Staff|Staff Only|General|Information)\\b"
    )
    
    is_non_name <- any(sapply(non_names, function(p) grepl(p, clean_text, ignore.case = TRUE)))
    
    return(matches_pattern && !is_non_name)
  }
  
    
  # Clean and format text data
  clean_text_data <- function(text) {
    if (is.na(text)) return(text)
    
    cleaned <- text
    # Remove extensions
    cleaned <- str_remove_all(cleaned, "\\s*ext\\.?\\s*\\d+.*$")
    cleaned <- str_remove_all(cleaned, "\\s*extension\\s*\\d+.*$")
    # Remove extra whitespace
    cleaned <- str_replace_all(cleaned, "\\s+", " ")
    cleaned <- trimws(cleaned)
    
    return(cleaned)
  }
  
  # ============================================================================
  # PATTERN 1: H2 names + H3 titles (Sequential different elements)
  # ============================================================================
  scrape_h2_name_h3_title <- function(page, hospital_info, config) {
    tryCatch({
      # Get h2 and h3 elements
      h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
      h3_elements <- page %>% html_nodes("h3") %>% html_text(trim = TRUE)
      
      # Normalize text
      h2_elements <- sapply(h2_elements, normalize_text)
      h3_elements <- sapply(h3_elements, normalize_text)
      
      # Filter for actual names and titles
      names <- h2_elements[sapply(h2_elements, function(x) is_executive_name(x, config))]
      titles <- h3_elements[sapply(h3_elements, function(x) is_executive_title(x, config))]
      
      # Limit to expected count
      if (!is.null(hospital_info$expected_executives)) {
        max_count <- hospital_info$expected_executives
        names <- names[1:min(length(names), max_count)]
        titles <- titles[1:min(length(titles), max_count)]
      }
      
      # Create name-title pairs
      pairs <- list()
      max_pairs <- min(length(names), length(titles))
      
      for (i in 1:max_pairs) {
        pairs[[i]] <- list(
          name = clean_text_data(names[i]),
          title = clean_text_data(titles[i])
        )
      }
      
      # Add any missing people specified in config
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 2: Combined name+title in single element
  # ============================================================================
  scrape_combined_h2 <- function(page, hospital_info, config) {
    tryCatch({
      separator <- hospital_info$html_structure$separator %||% " - "
      element_type <- hospital_info$html_structure$combined_element %||% "h2"
      
      elements <- page %>% html_nodes(element_type) %>% html_text(trim = TRUE)
      
      pairs <- list()
      
      for (element_text in elements) {
        element_text <- normalize_text(element_text)
        
        # Split by separator (using fixed=TRUE to handle special chars like |)
        parts <- strsplit(element_text, separator, fixed = TRUE)[[1]]
        
        if (length(parts) >= 2) {
          potential_name <- trimws(parts[1])
          potential_title <- trimws(parts[2])
          
          if (is_executive_name(potential_name, config) && 
              is_executive_title(potential_title, config)) {
            
            pairs[[length(pairs) + 1]] <- list(
              name = clean_text_data(potential_name),
              title = clean_text_data(potential_title)
            )
          }
        }
      }
      
      # Add missing people
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 3: Table rows
  # ============================================================================
  scrape_table_rows <- function(page, hospital_info, config) {
    tryCatch({
      tables <- page %>% html_table(fill = TRUE)
      
      name_col <- as.numeric(str_extract(hospital_info$html_structure$name_location, "\\d+"))
      title_col <- as.numeric(str_extract(hospital_info$html_structure$title_location, "\\d+"))
      
      pairs <- list()
      
      for (table in tables) {
        if (ncol(table) >= max(name_col, title_col) && nrow(table) > 0) {
          
          for (row_idx in 1:nrow(table)) {
            potential_name <- normalize_text(clean_text_data(table[row_idx, name_col]))
            potential_title <- normalize_text(clean_text_data(table[row_idx, title_col]))
            
            if (is_executive_name(potential_name, config) && 
                is_executive_title(potential_title, config)) {
              
              pairs[[length(pairs) + 1]] <- list(
                name = potential_name,
                title = potential_title
              )
            }
          }
        }
      }
      
      # Add missing people
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 4: H2 name + P title (Specific sequential pattern)
  # ============================================================================
  scrape_h2_name_p_title <- function(page, hospital_info, config) {
    tryCatch({
      # Get all h2 and p elements in order
      all_elements <- page %>% html_nodes("h2, p")
      
      pairs <- list()
      
      for (i in 1:(length(all_elements) - 1)) {
        current_element <- all_elements[[i]]
        next_element <- all_elements[[i + 1]]
        
        if (html_name(current_element) == "h2" && html_name(next_element) == "p") {
          current_text <- normalize_text(html_text(current_element, trim = TRUE))
          next_text <- normalize_text(html_text(next_element, trim = TRUE))
          
          if (is_executive_name(current_text, config) && 
              is_executive_title(next_text, config)) {
            
            pairs[[length(pairs) + 1]] <- list(
              name = clean_text_data(current_text),
              title = clean_text_data(next_text)
            )
          }
        }
      }
      
      # Add missing people
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 5: Div classes (CSS class-based) - UPDATED with missing_people
  # ============================================================================
  scrape_div_classes <- function(page, hospital_info, config) {
    tryCatch({
      name_class <- hospital_info$html_structure$name_class
      title_class <- hospital_info$html_structure$title_class
      
      name_elements <- page %>% html_nodes(paste0(".", name_class)) %>% html_text(trim = TRUE)
      title_elements <- page %>% html_nodes(paste0(".", title_class)) %>% html_text(trim = TRUE)
      
      pairs <- list()
      max_pairs <- min(length(name_elements), length(title_elements))
      
      for (i in 1:max_pairs) {
        potential_name <- clean_text_data(name_elements[i])
        potential_title <- clean_text_data(title_elements[i])
        
        if (is_executive_name(potential_name, config) && 
            is_executive_title(potential_title, config)) {
          
          pairs[[length(pairs) + 1]] <- list(
            name = potential_name,
            title = potential_title
          )
        }
      }
      
      # FIXED: Add missing people support
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 6: List items with separator
  # ============================================================================
  scrape_list_items <- function(page, hospital_info, config) {
    tryCatch({
      li_elements <- page %>% html_nodes("li") %>% html_text(trim = TRUE)
      
      pairs <- list()
      
      # Get separator from config
      separator <- hospital_info$html_structure$separator %||% " - "
      
      for (li_text in li_elements) {
        # Clean out common noise (email links)
        clean_li <- str_remove_all(li_text, "\\s*email\\s*$")
        clean_li <- trimws(clean_li)
        
        # Build regex pattern for separator
        if (separator == " | ") {
          sep_pattern <- "\\s*\\|\\s*"
        } else if (separator == ", ") {
          sep_pattern <- "\\s*,\\s*"
        } else if (separator == " - ") {
          sep_pattern <- "\\s*-\\s*"
        } else {
          sep_clean <- trimws(separator)
          sep_escaped <- gsub("([\\|\\(\\)\\[\\]\\{\\}\\+\\*\\?\\.\\^\\$])", "\\\\\\1", sep_clean)
          sep_pattern <- paste0("\\s*", sep_escaped, "\\s*")
        }
        
        # Split using the pattern
        parts <- strsplit(clean_li, sep_pattern, perl = TRUE)[[1]]
        
        if (length(parts) < 2) next
        
        # Extract name and title
        potential_name <- trimws(parts[1])
        
        # Handle multiple separators: combine all parts after first as title
        if (length(parts) > 2) {
          potential_title <- paste(parts[2:length(parts)], collapse = trimws(separator))
        } else {
          potential_title <- trimws(parts[2])
        }
        
        # Clean the extracted data
        potential_name <- clean_text_data(potential_name)
        potential_title <- clean_text_data(potential_title)
        
        # Skip empty or invalid
        if (nchar(potential_name) < 3 || nchar(potential_title) < 3 ||
            tolower(potential_title) == "email") {
          next
        }
        
        # Validate
        name_valid <- is_executive_name(potential_name, config)
        title_valid <- is_executive_title(potential_title, config)
        
        if (name_valid && title_valid) {
          pairs[[length(pairs) + 1]] <- list(
            name = potential_name,
            title = potential_title
          )
        }
      }
      
      # Add missing people
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      cat("ERROR in scrape_list_items:", e$message, "\n")
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 7: Boardcard gallery pattern
  # ============================================================================
  scrape_boardcard_pattern <- function(page, hospital_info, config) {
    tryCatch({
      boardcard_elements <- page %>% html_nodes("div.boardcard") %>% html_text(trim = TRUE)
      
      # Normalize text
      boardcard_elements <- sapply(boardcard_elements, normalize_text)
      
      pairs <- list()
      
      for (boardcard_text in boardcard_elements) {
        clean_text <- clean_text_data(boardcard_text)
        
        if (grepl(",", clean_text)) {
          parts <- strsplit(clean_text, ",", fixed = TRUE)[[1]]
          
          if (length(parts) >= 2) {
            potential_name <- trimws(parts[1])
            potential_title <- trimws(parts[2])
            
            # Take only the first sentence/phrase of the title
            potential_title <- trimws(strsplit(potential_title, "\\.")[[1]][1])
            
            if (is_executive_name(potential_name, config) && 
                is_executive_title(potential_title, config)) {
              
              pairs[[length(pairs) + 1]] <- list(
                name = potential_name,
                title = potential_title
              )
            }
          }
        }
      }
      
      # Add missing people
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 8: Custom table with nested elements - FIXED for FAC 777
  # Only processes Senior Administration section, excludes Medical Leadership
  # ============================================================================
  scrape_custom_table_nested <- function(page, hospital_info, config) {
    tryCatch({
      # Get non-breadcrumb tables only
      all_tables <- page %>% html_nodes("table:not([role='presentation'])")
      
      cat("  Found", length(all_tables), "content tables\n")
      
      # Process only first 3 tables (Senior Administration)
      tables_to_process <- all_tables[1:min(3, length(all_tables))]
      cat("  Processing first 3 tables (Senior Administration only)\n")
      
      pairs <- list()
      
      # Process each selected table
      for (table_idx in seq_along(tables_to_process)) {
        table <- tables_to_process[[table_idx]]
        
        # Get all table cells in this table
        table_cells <- table %>% html_nodes("td")
        
        for (cell in table_cells) {
          # Look for name in p with strong tag (updated for FAC 777)
          name_elements <- cell %>% html_nodes("p strong")
          
          if (length(name_elements) == 0) next
          
          # Extract name from strong element inside p
          potential_name <- name_elements %>% 
            html_text(trim = TRUE) %>% 
            first()
          
          # Look for title in BOTH div AND p elements with text-align styles
          # QCH uses both formats
          title_divs <- cell %>% html_nodes("div[style*='text-align']")
          title_ps <- cell %>% html_nodes("p:not(:has(strong)):not(:has(img))")
          
          # Combine both sources
          all_title_elements <- c(
            title_divs %>% html_text(trim = TRUE),
            title_ps %>% html_text(trim = TRUE)
          )
          
          # Remove empty strings and filter
          title_parts <- all_title_elements[nchar(all_title_elements) > 0]
          
          # Remove image alt text and &nbsp;
          title_parts <- title_parts[!grepl("^\\s*&nbsp;\\s*$", title_parts)]
          
          if (length(title_parts) == 0) next
          
          # Combine all title parts (handles multi-line titles)
          potential_title <- paste(title_parts, collapse = " ")
          
          # Clean the extracted data
          potential_name <- clean_text_data(potential_name)
          potential_title <- clean_text_data(potential_title)
          
          # Remove HTML entities like &nbsp;
          potential_title <- gsub("&nbsp;", " ", potential_title)
          potential_title <- gsub("&amp;", "&", potential_title)
          potential_title <- gsub("\\s+", " ", potential_title)
          potential_title <- trimws(potential_title)
          
          # Skip if name or title is empty
          if (is.na(potential_name) || is.na(potential_title) ||
              nchar(potential_name) < 3 || nchar(potential_title) < 3) {
            next
          }
          
          # Validate name and title
          if (is_executive_name(potential_name, config) && 
              is_executive_title(potential_title, config)) {
            
            pairs[[length(pairs) + 1]] <- list(
              name = potential_name,
              title = potential_title
            )
          }
        }
      }
      
      # Remove duplicates (in case someone appears in multiple tables)
      unique_pairs <- list()
      for (pair in pairs) {
        is_duplicate <- FALSE
        for (existing in unique_pairs) {
          if (existing$name == pair$name && existing$title == pair$title) {
            is_duplicate <- TRUE
            break
          }
        }
        if (!is_duplicate) {
          unique_pairs <- c(unique_pairs, list(pair))
        }
      }
      
      # Add missing_people support
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          unique_pairs[[length(unique_pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      cat("  Found", length(unique_pairs), "executives in Senior Administration\n")
      
      return(unique_pairs)
      
    }, error = function(e) {
      cat("  ERROR:", e$message, "\n")
      return(list())
    })
  }
  # ============================================================================
  # PATTERN 9: Sequential field-content elements
  # ============================================================================
  scrape_field_content_sequential <- function(page, hospital_info, config) {
    tryCatch({
      # Get ALL field-content elements
      all_field_content <- page %>% 
        html_nodes(".field-content") %>% 
        html_text(trim = TRUE)
      
      pairs <- list()
      
      # Pattern: skip first 2 elements, then Name, Title, Empty, Name, Title, Empty...
      i <- 3
      
      while (i < length(all_field_content)) {
        potential_name <- all_field_content[i]
        potential_title <- if ((i + 1) <= length(all_field_content)) all_field_content[i + 1] else NA
        
        # Clean the data
        potential_name <- clean_text_data(potential_name)
        potential_title <- clean_text_data(potential_title)
        
        # Skip if name or title is empty/NA
        if (!is.na(potential_name) && !is.na(potential_title) && 
            nchar(potential_name) > 0 && nchar(potential_title) > 0) {
          
          # Validate
          if (is_executive_name(potential_name, config) && 
              is_executive_title(potential_title, config)) {
            
            pairs[[length(pairs) + 1]] <- list(
              name = potential_name,
              title = potential_title
            )
          }
        }
        
        # Move to next set (skip the empty element at i+2)
        i <- i + 3
      }
      
      # Add missing people
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 10: Nested list with ID-based selectors
  # ============================================================================
  scrape_nested_list_with_ids <- function(page, hospital_info, config) {
    tryCatch({
      # Get name and title selectors from config
      name_selector <- hospital_info$html_structure$name_selector %||% "div[id^='t-']"
      title_selector <- hospital_info$html_structure$title_selector %||% "span[id^='d-']"
      
      # Extract all names and titles
      all_names <- page %>% html_nodes(name_selector) %>% html_text(trim = TRUE)
      all_titles <- page %>% html_nodes(title_selector) %>% html_text(trim = TRUE)
      
      pairs <- list()
      
      # Pair up names and titles (they should be in same order)
      max_pairs <- min(length(all_names), length(all_titles))
      
      for (i in 1:max_pairs) {
        potential_name <- all_names[i]
        potential_title <- all_titles[i]
        
        # Clean the data
        potential_name <- clean_text_data(potential_name)
        potential_title <- clean_text_data(potential_title)
        
        # Skip empty strings
        if (nchar(potential_name) < 3 || nchar(potential_title) < 3) {
          next
        }
        
        # Validate
        name_valid <- is_executive_name(potential_name, config)
        title_valid <- is_executive_title(potential_title, config)
        
        if (name_valid && title_valid) {
          pairs[[length(pairs) + 1]] <- list(
            name = potential_name,
            title = potential_title
          )
        }
      }
      
      # Add missing people
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  # ============================================================================
  # PATTERN 11: QCH-style mixed table structure (for FAC 777)
  # Tables use different formats - some use divs, some use p tags for titles
  # ============================================================================
  scrape_qch_mixed_tables <- function(page, hospital_info, config) {
    tryCatch({
      # Get non-breadcrumb tables only
      all_tables <- page %>% html_nodes("table:not([role='presentation'])")
      
      cat("  Found", length(all_tables), "content tables\n")
      
      # Process only first 3 tables (Senior Administration)
      tables_to_process <- all_tables[1:min(3, length(all_tables))]
      cat("  Processing first 3 tables for Senior Administration\n")
      
      pairs <- list()
      
      # Process each table
      for (table_idx in seq_along(tables_to_process)) {
        table <- tables_to_process[[table_idx]]
        
        cat("  Scanning table", table_idx, "...\n")
        
        # Get all rows
        rows <- table %>% html_nodes("tr")
        
        for (row in rows) {
          # Get all cells in this row
          cells <- row %>% html_nodes("td")
          
          for (cell_idx in seq_along(cells)) {
            cell <- cells[[cell_idx]]
            
            # STEP 1: Find name in <strong> tag
            strong_elements <- cell %>% html_nodes("strong")
            
            if (length(strong_elements) == 0) next
            
            potential_name <- strong_elements %>% 
              html_text(trim = TRUE) %>% 
              first()
            
            # STEP 2: Find title - try multiple strategies
            potential_title <- NA
            
            # Strategy A: Look for divs with text-align style (Table 1 format)
            title_divs <- cell %>% 
              html_nodes("div[style*='text-align']") %>% 
              html_text(trim = TRUE)
            
            title_divs <- title_divs[nchar(trimws(title_divs)) > 0]
            
            if (length(title_divs) > 0) {
              # Found title in divs - combine them
              potential_title <- paste(title_divs, collapse = " ")
              cat("    Cell", cell_idx, "- Found name in strong, title in divs\n")
            } else {
              # Strategy B: Look in <p> tags that don't have strong or img (Tables 2-3 format)
              all_p_tags <- cell %>% html_nodes("p")
              
              title_parts <- c()
              for (p_tag in all_p_tags) {
                # Skip if this p contains the strong tag (the name)
                has_strong <- length(p_tag %>% html_nodes("strong")) > 0
                # Skip if this p contains an img
                has_img <- length(p_tag %>% html_nodes("img")) > 0
                
                if (!has_strong && !has_img) {
                  p_text <- p_tag %>% html_text(trim = TRUE)
                  if (nchar(p_text) > 0 && !grepl("^\\s*&nbsp;\\s*$", p_text)) {
                    title_parts <- c(title_parts, p_text)
                  }
                }
              }
              
              if (length(title_parts) > 0) {
                potential_title <- paste(title_parts, collapse = " ")
                cat("    Cell", cell_idx, "- Found name in strong, title in p tags\n")
              }
            }
            
            # STEP 3: Validate and clean
            if (is.na(potential_title)) {
              cat("    Cell", cell_idx, "- Name found but no title, skipping\n")
              next
            }
            
            # Clean the data
            potential_name <- clean_text_data(potential_name)
            potential_title <- clean_text_data(potential_title)
            
            # Remove HTML entities
            potential_title <- gsub("&nbsp;", " ", potential_title)
            potential_title <- gsub("&amp;", "&", potential_title)
            potential_title <- gsub("\\s+", " ", potential_title)
            potential_title <- trimws(potential_title)
            potential_name <- trimws(potential_name)
            
            # Skip if too short
            if (nchar(potential_name) < 3 || nchar(potential_title) < 3) {
              cat("    Cell", cell_idx, "- Name or title too short, skipping\n")
              next
            }
            
            # Validate with pattern matching
            name_valid <- is_executive_name(potential_name, config)
            title_valid <- is_executive_title(potential_title, config)
            
            if (name_valid && title_valid) {
              cat("    Cell", cell_idx, "- VALID: ", potential_name, " -> ", potential_title, "\n")
              
              pairs[[length(pairs) + 1]] <- list(
                name = potential_name,
                title = potential_title
              )
            } else {
              cat("    Cell", cell_idx, "- Invalid (name_valid:", name_valid, 
                  ", title_valid:", title_valid, ") - ", potential_name, " / ", potential_title, "\n")
            }
          }
        }
      }
      
      # Remove duplicates
      unique_pairs <- list()
      for (pair in pairs) {
        is_duplicate <- FALSE
        for (existing in unique_pairs) {
          if (existing$name == pair$name && existing$title == pair$title) {
            is_duplicate <- TRUE
            break
          }
        }
        if (!is_duplicate) {
          unique_pairs <- c(unique_pairs, list(pair))
        }
      }
      
      # Add missing_people support
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          unique_pairs[[length(unique_pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      cat("  Total executives found:", length(unique_pairs), "\n")
      
      return(unique_pairs)
      
    }, error = function(e) {
      cat("  ERROR:", e$message, "\n")
      return(list())
    })
  }
  # ============================================================================
  # MAIN SCRAPER FUNCTION
  # ============================================================================
  scrape_hospital <- function(hospital_info, config_file = "enhanced_hospitals.yaml") {
    config <- load_config(config_file)
    
    cat("Scraping", hospital_info$name, "(FAC-", hospital_info$FAC, ")")
    cat(" - Pattern:", hospital_info$pattern, "\n")
    
    tryCatch({
      page <- read_html(hospital_info$url)
      
      # Dispatch to appropriate pattern scraper
      pairs <- switch(hospital_info$pattern,
                      "h2_name_h3_title" = scrape_h2_name_h3_title(page, hospital_info, config),
                      "combined_h2" = scrape_combined_h2(page, hospital_info, config),
                      "table_rows" = scrape_table_rows(page, hospital_info, config),
                      "h2_name_p_title" = scrape_h2_name_p_title(page, hospital_info, config),
                      "div_classes" = scrape_div_classes(page, hospital_info, config),
                      "list_items" = scrape_list_items(page, hospital_info, config),
                      "boardcard_gallery" = scrape_boardcard_pattern(page, hospital_info, config),
                      "custom_table_nested" = scrape_custom_table_nested(page, hospital_info, config),
                      "field_content_sequential" = scrape_field_content_sequential(page, hospital_info, config),
                      "nested_list_with_ids" = scrape_nested_list_with_ids(page, hospital_info, config),
                      "qch_mixed_tables" = scrape_qch_mixed_tables(page, hospital_info, config),
                      # Default fallback 
                      scrape_h2_name_h3_title(page, hospital_info, config)
      )
      
      # Create consistent output data frame
      if (length(pairs) > 0) {
        result_df <- data.frame(
          FAC = sprintf("%03d", as.numeric(hospital_info$FAC)),
          hospital_name = hospital_info$name,
          executive_name = sapply(pairs, function(p) p$name),
          executive_title = sapply(pairs, function(p) p$title),
          date_gathered = Sys.Date(),
          stringsAsFactors = FALSE
        )
        
        cat("  Success:", nrow(result_df), "executives found\n")
        return(result_df)
        
      } else {
        cat("  No executives found\n")
        return(data.frame(
          FAC = sprintf("%03d", as.numeric(hospital_info$FAC)),
          hospital_name = hospital_info$name,
          executive_name = NA,
          executive_title = NA,
          date_gathered = Sys.Date(),
          stringsAsFactors = FALSE
        ))
      }
      
    }, error = function(e) {
      cat("  Error:", e$message, "\n")
      return(data.frame(
        FAC = sprintf("%03d", as.numeric(hospital_info$FAC)),
        hospital_name = hospital_info$name,
        executive_name = NA,
        executive_title = NA,
        date_gathered = Sys.Date(),
        error_message = e$message,
        stringsAsFactors = FALSE
      ))
    })
  }
  
  # ============================================================================
  # BATCH PROCESSING
  # ============================================================================
  scrape_batch <- function(hospitals_list, config_file = "enhanced_hospitals.yaml", 
                           output_folder = "E:/ExecutiveSearchYaml/output") {
    
    all_results <- list()
    
    for (i in seq_along(hospitals_list)) {
      cat(sprintf("[%d/%d] ", i, length(hospitals_list)))
      result <- scrape_hospital(hospitals_list[[i]], config_file)
      all_results[[i]] <- result
      
      Sys.sleep(1)  # Rate limiting
    }
    
    # Combine and save results
    final_results <- bind_rows(all_results)
    
    # Create consistent output file
    timestamp <- format(Sys.Date(), "%Y%m%d")
    output_file <- file.path(output_folder, paste0("hospital_executives_", timestamp, ".csv"))
    write.csv(final_results, output_file, row.names = FALSE)
    
    # Summary
    cat("\n=== SCRAPING SUMMARY ===\n")
    total_records <- nrow(final_results)
    valid_records <- sum(!is.na(final_results$executive_name))
    hospitals_with_data <- length(unique(final_results$hospital_name[!is.na(final_results$executive_name)]))
    
    cat("Total records:", total_records, "\n")
    cat("Valid records:", valid_records, "\n") 
    cat("Success rate:", round(valid_records / total_records * 100, 1), "%\n")
    cat("Hospitals with data:", hospitals_with_data, "out of", length(hospitals_list), "\n")
    cat("Output file:", basename(output_file), "\n")
    
    return(final_results)
  }
  
  # ============================================================================
  # TEST FUNCTION
  # ============================================================================
  test_hospital <- function(fac, name, url, pattern = "h2_name_h3_title", config_file = "enhanced_hospitals.yaml") {
    
    hospital_info <- list(
      FAC = sprintf("%03d", as.numeric(fac)),
      name = name,
      url = url,
      pattern = pattern,
      expected_executives = 5
    )
    
    result <- scrape_hospital(hospital_info, config_file)
    return(result)
  }
  
  return(list(
    scrape_hospital = scrape_hospital,
    scrape_batch = scrape_batch,
    test_hospital = test_hospital,
    load_config = load_config
  ))
}