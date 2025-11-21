# pattern_based_scraper.R - Enhanced scraper with 14 pattern-based approaches
# Save this in E:/ExecutiveSearchYaml/code/
# UPDATED: Added missing_people support to Patterns 5 & 8, fixed Pattern 8 for FAC 777
# updated to add new patterns

###############
##############
#   TEST sytem replacing html_text2() with html_text2()
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
    
    name <- gsub("[Ã Ã¡Ã¢Ã£Ã¤Ã¥Ã€ÃÃ‚ÃƒÃ„Ã…]", "a", name)
    name <- gsub("[Ã¨Ã©ÃªÃ«ÃˆÃ‰ÃŠÃ‹]", "e", name)
    name <- gsub("[Ã¬Ã­Ã®Ã¯ÃŒÃÃŽÃ]", "i", name)
    name <- gsub("[Ã²Ã³Ã´ÃµÃ¶Ã’Ã“Ã”Ã•Ã–]", "o", name)
    name <- gsub("[Ã¹ÃºÃ»Ã¼Ã™ÃšÃ›Ãœ]", "u", name)
    name <- gsub("[Ã§Ã‡]", "c", name)
    name <- gsub("[Ã±Ã‘]", "n", name)
    name <- gsub("[Ã½Ã]", "y", name)
    name <- gsub("ÃŸ", "ss", name)
    name <- gsub("[Ã¦Ã†]", "ae", name)
    name <- gsub("[Å“Å’]", "oe", name)
    
    return(name)
  }
  
  
  # Check if text matches name patterns
  # Check if text matches name patternsNew
  # add in debug language
  # new function that uses yaml as the source of truth
  # creates a common approach to verifying names and titles
  # Check if text matches name patterns
  is_executive_name <- function(text, config, hospital_info = NULL) {
    if (is.na(text) || nchar(trimws(text)) < 3) return(FALSE)
    
    # Get base name patterns from config
    name_patterns <- c(
      config$name_patterns$standard,
      config$name_patterns$with_titles,
      config$name_patterns$with_credentials,
      config$name_patterns$hyphenated_names,
      config$name_patterns$complex_credentials,
      config$name_patterns$internal_capitals,
      config$name_patterns$accented_names,
      config$name_patterns$parenthetical_names,
      config$name_patterns$flexible
    )
    
    # Add hospital-specific name patterns if available
    if (!is.null(hospital_info)) {
      fac_key <- paste0("FAC_", hospital_info$FAC)
      if (!is.null(config$hospital_overrides[[fac_key]]$additional_name_patterns)) {
        name_patterns <- c(name_patterns, 
                           config$hospital_overrides[[fac_key]]$additional_name_patterns)
        cat(sprintf("  [FAC %s] Using %d additional name patterns\n", 
                    hospital_info$FAC,
                    length(config$hospital_overrides[[fac_key]]$additional_name_patterns)))
      }
    }
    
    # Clean text first (but preserve hyphens in names)
    clean_text <- str_remove_all(text, "\\s*ext\\.?\\s*\\d+.*$")
    clean_text <- trimws(clean_text)
    
    # Check against patterns
    matches_pattern <- any(sapply(name_patterns, function(p) {
      if (!is.null(p) && !is.na(p)) {
        grepl(p, clean_text)
      } else {
        FALSE
      }
    }))
#was an n here???
    
    # Get exclusions from config (no longer hardcoded)
    non_names <- config$recognition_config$name_exclusions
    is_non_name <- any(sapply(non_names, function(p) 
      grepl(p, clean_text, ignore.case = TRUE)))
    
    # Debug logging
    if (!matches_pattern || is_non_name) {
      cat("DEBUG: Rejected name: '", text, "'", 
          " (matches_pattern=", matches_pattern, 
          ", is_non_name=", is_non_name, ")\n", sep = "")
    }
    
    return(matches_pattern && !is_non_name)
  }
  
  
  
  # Simplified title checking - just look for executive keywords
  
   # new revised exexcutive title key words
    # Check if text matches title patterns
    is_executive_title <- function(text, config, hospital_info = NULL) {
      if (is.na(text) || nchar(trimws(text)) < 3) return(FALSE)
      
      # Clean text first
      clean_text <- str_remove_all(text, "\\s*ext\\.?\\s*\\d+.*$")
      clean_text <- str_remove_all(clean_text, "\\s*extension\\s*\\d+.*$")
      clean_text <- trimws(clean_text)
      
      # Get executive keywords from config (no longer hardcoded)
      executive_keywords <- c(
        config$recognition_config$title_keywords$primary,
        config$recognition_config$title_keywords$secondary,
        config$recognition_config$title_keywords$medical_specific
      )
      
      # Add hospital-specific title keywords if available
      if (!is.null(hospital_info)) {
        fac_key <- paste0("FAC_", hospital_info$FAC)
        if (!is.null(config$hospital_overrides[[fac_key]]$additional_title_keywords)) {
          executive_keywords <- c(executive_keywords,
                                  config$hospital_overrides[[fac_key]]$additional_title_keywords)
          cat(sprintf("  [FAC %s] Using %d additional title keywords\n", 
                      hospital_info$FAC,
                      length(config$hospital_overrides[[fac_key]]$additional_title_keywords)))
        }
      }
      
      # Check if contains ANY executive keyword
      contains_keyword <- any(sapply(executive_keywords, function(k) 
        grepl(k, clean_text, ignore.case = TRUE)))
      
      # Get invalid patterns from config (no longer hardcoded)
      invalid_title_patterns <- config$recognition_config$title_exclusions
      # ADD THIS BLOCK:
      # Add hospital-specific title exclusions if available
      if (!is.null(hospital_info)) {
        fac_key <- paste0("FAC_", hospital_info$FAC)
        if (!is.null(config$hospital_overrides[[fac_key]]$additional_title_exclusions)) {
          invalid_title_patterns <- c(invalid_title_patterns,
                                      config$hospital_overrides[[fac_key]]$additional_title_exclusions)
          cat(sprintf("  [FAC %s] Using %d additional title exclusions\n", 
                      hospital_info$FAC,
                      length(config$hospital_overrides[[fac_key]]$additional_title_exclusions)))
        }
      }
      # Check if title contains any invalid terms
      has_invalid_term <- any(sapply(invalid_title_patterns, function(pattern) {
        grepl(pattern, clean_text, ignore.case = TRUE)
      }))
      
      if (has_invalid_term) return(FALSE)
      
      return(contains_keyword)
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
#Start changing patterns here?
  
  # ============================================================================
  # PATTERN 1: H2 names + H3 titles (Sequential different elements)
  # ============================================================================
  scrape_h2_name_h3_title <- function(page, hospital_info, config) {
    tryCatch({
      # Get h2 and h3 elements
      h2_elements <- page %>% html_nodes("h2") %>% html_text2()
      h3_elements <- page %>% html_nodes("h3") %>% html_text2()
      
      # Normalize text
      h2_elements <- sapply(h2_elements, normalize_text)
      h3_elements <- sapply(h3_elements, normalize_text)
      
      # Filter for actual names and titles
      # Filter for actual names and titles (now with hospital_info for overrides)
      names <- h2_elements[sapply(h2_elements, function(x) 
        is_executive_name(x, config, hospital_info))]
      titles <- h3_elements[sapply(h3_elements, function(x) 
        is_executive_title(x, config, hospital_info))]
      
      
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
  # ============================================================================
  # PATTERN 2: Combined name+title in single element
  # UPDATED: Added 'reversed' parameter to handle Title:Name format
  # ============================================================================
  scrape_combined_h2 <- function(page, hospital_info, config) {
    tryCatch({
      separator <- hospital_info$html_structure$separator %||% " - "
      element_type <- hospital_info$html_structure$combined_element %||% "h2"
      
      # NEW: Check if reversed order (title comes before name)
      # Defaults to FALSE for backward compatibility
      reversed <- hospital_info$html_structure$reversed %||% FALSE
      
     # insert code on <br> recognition here.
      # REPLACE WITH:
      # Handle <br> separator specially
      if (separator == "<br>" || separator == "br") {
        elements_raw <- page %>% html_nodes(element_type)
        elements <- sapply(elements_raw, function(elem) {
          # Replace <br> with our separator marker before extracting text
          html_content <- as.character(elem)
          html_content <- gsub("<br\\s*/?>", " |BR| ", html_content, ignore.case = TRUE)
          # Now extract text
          read_html(html_content) %>% html_text2()
        })
        # Update separator to match our marker
        separator <- " |BR| "
      } else {
        elements <- page %>% html_nodes(element_type) %>% html_text2()
      }
      
      pairs <- list()
      
      for (element_text in elements) {
        element_text <- normalize_text(element_text)
        
        # Split by separator (using fixed=TRUE to handle special chars like |)
        parts <- strsplit(element_text, separator, fixed = TRUE)[[1]]
        
        if (length(parts) >= 2) {
          part1 <- trimws(parts[1])
          part2 <- trimws(paste(parts[2:length(parts)], collapse = separator))
          
          # NEW: Assign name and title based on reversed flag
          if (reversed) {
            # Reversed: part1 is title, part2 is name
            potential_name <- part2
            potential_title <- part1
          } else {
            # Normal: part1 is name, part2 is title
            potential_name <- part1
            potential_title <- part2
          }
          
          if ( is_executive_name(potential_name, config, hospital_info) && 
              is_executive_title(potential_title, config, hospital_info)) {
            
            pairs[[length(pairs) + 1]] <- list(
              name = clean_text_data(potential_name),
              title = clean_text_data(potential_title)
            )
          }
        }
      }
      
      # Add missing people
      # code insert Claude
      # Deduplicate pairs before adding missing people
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

# Add missing people
if (!is.null(hospital_info$html_structure$missing_people)) {
  for (missing in hospital_info$html_structure$missing_people) {
    unique_pairs[[length(unique_pairs) + 1]] <- list(
      name = missing$name,
      title = missing$title
    )
  }
}

# Note: No longer limiting to expected_executives count
# All unique pairs are returned for filtering in final database phase

return(unique_pairs)
      
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
            
            if (is_executive_name(potential_name, config, hospital_info) && 
                is_executive_title(potential_title, config, hospital_info)) {
              
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
  # ============================================================================
  # PATTERN 4: Sequential name + title (Flexible version)
  # UPDATED: Now supports h2â†’p OR p(with strong)â†’p patterns or <a>
  # ============================================================================
  # ============================================================================
  # PATTERN 4: Sequential name + title (Flexible version)
  # UPDATED: Now supports h2â†’p OR p(with strong)â†’p patterns or <a>
  # NEW: Added 'reversed' parameter to handle Titleâ†’Name order
  # ============================================================================
  scrape_h2_name_p_title <- function(page, hospital_info, config) {
    tryCatch({
      # Get configuration for which elements to use
      # new code from claude
      # Get configuration for which elements to use
      name_element <- hospital_info$html_structure$name_element %||% "h2"
      title_element <- hospital_info$html_structure$title_element %||% "p"
      
      # NEW: Extract just the tag name for comparison (before any classes/IDs)
      name_tag <- gsub("\\..*$|#.*$|\\[.*$", "", name_element)
      title_tag <- gsub("\\..*$|#.*$|\\[.*$", "", title_element)
      
      # NEW: Check if reversed order (title comes before name)
      # Defaults to FALSE for backward compatibility
      reversed <- hospital_info$html_structure$reversed %||% FALSE
      
      # NEW: If reversed, swap BOTH the full selectors and the tag names
      if (reversed) {
        temp <- name_element
        name_element <- title_element
        title_element <- temp
        
        temp_tag <- name_tag
        name_tag <- title_tag
        title_tag <- temp_tag
      }
      
      # Build selector for elements we're looking for (use full selectors with classes)
      selector <- paste(name_element, title_element, sep = ", ")
      
      all_elements <- page %>% html_nodes(selector)
      
      pairs <- list()
      
      for (i in 1:(length(all_elements) - 1)) {
        current_element <- all_elements[[i]]
        next_element <- all_elements[[i + 1]]
        
        # Check if current element is the name type and next is title type
        #replace with new claude code
        # Check if current element is the name type and next is title type
        # Compare HTML tag names (not full selectors with classes)
        current_is_name <- html_name(current_element) == name_tag
        next_is_title <- html_name(next_element) == title_tag
        if (current_is_name && next_is_title) {
          current_text <- normalize_text(html_text(current_element, trim = TRUE))
          next_text <- normalize_text(html_text(next_element, trim = TRUE))
          
          # NEW: Handle reversed order
          if (reversed) {
            # If reversed, current is actually title, next is actually name
            name_text <- next_text
            title_text <- current_text
          } else {
            # Normal order: current is name, next is title
            name_text <- current_text
            title_text <- next_text
          }
          
          # Additional filter for pâ†’p pattern: name must contain <strong> or <a>
          # Skip this check if reversed (since we swapped the elements)
          if (name_element == "p" && title_element == "p" && !reversed) {
            # Check if current element has strong or a tag
            has_strong <- length(current_element %>% html_nodes("strong")) > 0
            has_link <- length(current_element %>% html_nodes("a")) > 0
            
            if (!has_strong && !has_link) {
              next
            }
          }
          
          # MODIFIED: Use name_text and title_text variables instead of current_text and next_text
          if (is_executive_name(name_text, config, hospital_info) && 
              is_executive_title(title_text, config, hospital_info)) {
            
            # Enhanced title cleaning for phone/fax numbers
            cleaned_title <- title_text
            cleaned_title <- gsub("Telephone:.*$", "", cleaned_title, ignore.case = TRUE)
            cleaned_title <- gsub("Fax:.*$", "", cleaned_title, ignore.case = TRUE)
            cleaned_title <- gsub("\\d{3}[-\\.\\s]?\\d{3}[-\\.\\s]?\\d{4}.*$", "", cleaned_title)
            cleaned_title <- trimws(cleaned_title)
            
            pairs[[length(pairs) + 1]] <- list(
              name = clean_text_data(name_text),
              title = clean_text_data(cleaned_title)
            )
          }
        }
      }
      
      # Limit to expected count if specified
      if (!is.null(hospital_info$expected_executives)) {
        max_count <- hospital_info$expected_executives
        if (length(pairs) > max_count) {
          pairs <- pairs[1:max_count]
        }
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
      cat("  ERROR:", e$message, "\n")
      return(list())
    })
  }
  # ============================================================================
  # PATTERN 5: Div classes (CSS class-based) - UPDATED with missing_people
# Debug code added
  # ============================================================================
  scrape_div_classes <- function(page, hospital_info, config) {
    tryCatch({
      name_class <- hospital_info$html_structure$name_class
      title_class <- hospital_info$html_structure$title_class
      container_class <- hospital_info$html_structure$container_class
      
      pairs <- list()
      
      # If container_class specified, use container-based pairing
      if (!is.null(container_class) && container_class != "") {
        containers <- page %>% html_nodes(paste0(".", container_class))
        
        cat("DEBUG: Found", length(containers), "containers\n")
        
        for (i in seq_along(containers)) {
          container <- containers[[i]]
          
          # Extract name and title from within this container
          name_nodes <- container %>% html_nodes(paste0(".", name_class))
          title_nodes <- container %>% html_nodes(paste0(".", title_class))
          
          if (length(name_nodes) > 0 && length(title_nodes) > 0) {
            potential_name <- clean_text_data(html_text2(name_nodes[[1]]))
            potential_title <- clean_text_data(html_text2(title_nodes[[1]]))
            
            cat("DEBUG: Container", i, "- Name:", potential_name, "\n")
            cat("DEBUG:              Title:", potential_title, "\n")
            
            # Validate both
            name_valid <- is_executive_name(potential_name, config, hospital_info)
            title_valid <- is_executive_title(potential_title, config, hospital_info)
            
            cat("DEBUG:   name_valid:", name_valid, ", title_valid:", title_valid, "\n")
            
            if (name_valid && title_valid) {
              pairs[[length(pairs) + 1]] <- list(
                name = potential_name,
                title = potential_title
              )
              cat("DEBUG:   âœ“ ADDED TO PAIRS\n")
            }
          }
        }
      } else {
        # Fallback to sequential pairing if no container specified
        name_elements <- page %>% html_nodes(paste0(".", name_class)) %>% html_text2()
        title_elements <- page %>% html_nodes(paste0(".", title_class)) %>% html_text2()
        
        for (i in seq_along(name_elements)) {
          potential_name <- clean_text_data(name_elements[i])
          
          if (i <= length(title_elements)) {
            potential_title <- clean_text_data(title_elements[i])
            
            name_valid <- is_executive_name(potential_name, config, hospital_info)
            title_valid <- is_executive_title(potential_title, config, hospital_info)
            
            if (name_valid && title_valid) {
              pairs[[length(pairs) + 1]] <- list(
                name = potential_name,
                title = potential_title
              )
            }
          }
        }
      }
      
      cat("DEBUG: Total pairs found:", length(pairs), "\n")
      
      # Add missing people support
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(
            name = missing$name,
            title = missing$title
          )
        }
      }
      
      if (length(pairs) > 0) {
        df <- data.frame(
          name = sapply(pairs, function(p) p$name),
          title = sapply(pairs, function(p) p$title),
          stringsAsFactors = FALSE
        )
        df_unique <- df[!duplicated(df), ]
        
        unique_pairs <- list()
        for (i in 1:nrow(df_unique)) {
          unique_pairs[[i]] <- list(name = df_unique$name[i], title = df_unique$title[i])
        }
        return(unique_pairs)
      } else {
        return(pairs)
      }
      
    }, error = function(e) {
      cat("ERROR in scrape_div_classes:", e$message, "\n")
      return(list())
    })
  }
  # ============================================================================
  # PATTERN 6: List items with separator
  # ============================================================================
  scrape_list_items <- function(page, hospital_info, config) {
    tryCatch({
      li_elements <- page %>% html_nodes("li") %>% html_text2()
      
      pairs <- list()
      
      # Get separator from config
      separator <- hospital_info$html_structure$separator %||% " - "
      
      for (li_text in li_elements) {
        # Clean out common noise (email links)
        clean_li <- str_remove_all(li_text, "\\s*email\\s*$")
        clean_li <- trimws(clean_li)
        
        # Build regex pattern for separator
        # put in Claude fix 
        # Build regex pattern for separator
        if (separator == " | ") {
          sep_pattern <- "\\s*\\|\\s*"
        } else if (separator == ", ") {
          sep_pattern <- "\\s*,\\s*"
        } else if (separator == " - ") {
          sep_pattern <- "\\s*-\\s*"
        } else {
          # Escape all regex special characters
          sep_clean <- trimws(separator)
          # Use fixed=TRUE instead of regex to avoid escaping issues
          # Just mark where to split
          sep_pattern <- sep_clean
        }
        
        # Split using the pattern
        # insert claude split 
        parts <- strsplit(clean_li, sep_pattern, fixed = TRUE)[[1]]
        
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
        name_valid <- is_executive_name(potential_name, config, hospital_info)
        title_valid <- is_executive_title(potential_title, config, hospital_info)
        
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
  # Pattern 7: Boardcard gallery pattern - UPDATED VERSION
  scrape_boardcard_pattern <- function(page, hospital_info, config) {
    tryCatch({
      boardcard_elements <- page %>% html_nodes("div.boardcard") %>% html_text2()
      
      # Normalize text
      boardcard_elements <- sapply(boardcard_elements, normalize_text)
      
      pairs <- list()
      
      for (boardcard_text in boardcard_elements) {
        clean_text <- clean_text_data(boardcard_text)
        
        if (grepl(",", clean_text)) {
          parts <- strsplit(clean_text, ",", fixed = TRUE)[[1]]
          
          if (length(parts) >= 2) {
            potential_name <- trimws(parts[1])
            
            # CHANGED: Take ALL parts after the name, not just parts[2]
            potential_title <- trimws(paste(parts[2:length(parts)], collapse = ","))
            
            # Take only the first sentence/phrase of the title
            potential_title <- trimws(strsplit(potential_title, "\\.")[[1]][1])
            
            if (is_executive_name(potential_name, config, hospital_info) && 
                is_executive_title(potential_title, config, hospital_info)) {
              
              pairs[[length(pairs) + 1]] <- list(
                name = potential_name,
                title = potential_title
              )
            }
          }
        }
      }
      
      # Add missing people from YAML config
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
            html_text2() %>% 
            first()
          
          # Look for title in BOTH div AND p elements with text-align styles
          # QCH uses both formats
          title_divs <- cell %>% html_nodes("div[style*='text-align']")
          title_ps <- cell %>% html_nodes("p:not(:has(strong)):not(:has(img))")
          
          # Combine both sources
          all_title_elements <- c(
            title_divs %>% html_text2(),
            title_ps %>% html_text2()
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
          if (is_executive_name(potential_name, config, hospital_info) && 
              is_executive_title(potential_title, config, hospital_info)) {
            
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
        html_text2()
      
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
          if (is_executive_name(potential_name, config, hospital_info) && 
              is_executive_title(potential_title, config, hospital_info)) {
            
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
      all_names <- page %>% html_nodes(name_selector) %>% html_text2()
      all_titles <- page %>% html_nodes(title_selector) %>% html_text2()
      
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
        name_valid <- is_executive_name(potential_name, config, hospital_info)
        title_valid <- is_executive_title(potential_title, config, hospital_info)
        
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
              html_text2() %>% 
              first()
            
            # STEP 2: Find title - try multiple strategies
            potential_title <- NA
            
            # Strategy A: Look for divs with text-align style (Table 1 format)
            title_divs <- cell %>% 
              html_nodes("div[style*='text-align']") %>% 
              html_text2()
            
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
                  p_text <- p_tag %>% html_text2()
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
            name_valid <- is_executive_name(potential_name, config, hospital_info)
            title_valid <- is_executive_title(potential_title, config, hospital_info)
            
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
  # PATTERN 12: P elements with bold/strong name and br separator
  # ============================================================================
  scrape_p_with_bold_and_br <- function(page, hospital_info, config) {
    pairs <- list()
    
    # Make it flexible - use custom selector if provided in YAML
    if (!is.null(hospital_info$html_structure$container_selector)) {
      p_elements <- page %>% html_nodes(hospital_info$html_structure$container_selector)
    } else {
      # Default: find all p elements
      p_elements <- page %>% html_nodes("p")
    }
    
    for (p in p_elements) {
      # Look for strong OR b tag for the name
      name_node <- p %>% html_node("strong, b")
      
      # Skip if no name found
      if (length(name_node) == 0 || is.na(name_node)) next
      
      name <- html_text(name_node, trim = TRUE)
      
      # Skip if name is empty
      if (nchar(name) == 0) next
      
      # Get all text from the p element
      full_text <- html_text(p, trim = TRUE)
      
      # Split by newlines (handles both \n and \r\n)
      lines <- strsplit(full_text, "\r?\n")[[1]]
      lines <- trimws(lines)
      
      # Remove empty lines
      lines <- lines[nchar(lines) > 0]
      
      # If only one line, try splitting on the name
      if (length(lines) == 1) {
        # Try to split: "NameTitleContactInfo" -> separate parts
        text_after_name <- sub(paste0("^", gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", name)), "", full_text)
        text_after_name <- trimws(text_after_name)
        
        # Split remaining text by common separators
        parts <- strsplit(text_after_name, "(?<=\\w)(\\d{3}[-\\s]|[0-9]{3}\\-)", perl = TRUE)[[1]]
        
        if (length(parts) > 0 && nchar(parts[1]) > 0) {
          lines <- c(name, parts[1])
        }
      }
      
      # Title is typically the second line (first line is the name)
      if (length(lines) >= 2) {
        title <- lines[2]
        
        # Clean up title - remove emails and phone numbers that might be concatenated
        title <- gsub("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "", title)
        title <- gsub("\\d{3}[-\\.\\s]?\\d{3}[-\\.\\s]?\\d{4}", "", title)
        title <- gsub("\\s+ext\\.?\\s*\\d+", "", title, ignore.case = TRUE)
        title <- trimws(title)
        
        # Validate using standard validation functions
        name_valid <- is_executive_name(name, config,hospital_info)
        title_valid <- is_executive_title(title, config,hospital_info)
        
        if (name_valid && title_valid) {
          pairs[[length(pairs) + 1]] <- list(
            name = name,
            title = title
          )
        }
      }
    }
    
    return(pairs)
  }
  # ============================================================================
  # PATTERN 13: Manual Entry (for blocked sites)
  # ============================================================================
  scrape_manual_entry <- function(page, hospital_info, config) {
    # Don't actually scrape - just return the known_executives from YAML
    pairs <- list()
    
    if (!is.null(hospital_info$known_executives)) {
      for (exec in hospital_info$known_executives) {
        pairs[[length(pairs) + 1]] <- list(
          name = exec$name,
          title = exec$title
        )
      }
    }
    
    return(pairs)
  } 
  # ============================================================================
  # PATTERN 14: H2 with complex combined name/title requiring smart parsing
  # ============================================================================
  scrape_h2_combined_complex <- function(page, hospital_info, config) {
    pairs <- list()
    
    h2_elements <- page %>% html_nodes("h2") %>% html_text2()
    
    for (text in h2_elements) {
      # Skip if empty or too short
      if (nchar(text) < 5) next
      
      # Clean up whitespace
      text <- gsub("\\s+", " ", text)
      text <- trimws(text)
      
      # List of title keywords to search for
      title_keywords <- c(
        "Executive Vice President",
        "Senior Vice President", 
        "Vice President",
        "Chief Operating Officer",
        "Chief Nursing Executive",
        "Chief Financial Officer",
        "Chief Information Officer",
        "Chief Health Information Officer",
        "Chief People Officer",
        "Chief of Staff",
        "Chief Scientist",
        "President & CEO",
        "President & Chief Executive Officer",
        "General Counsel"
      )
      
      # Find the EARLIEST occurrence of any title keyword
      earliest_position <- nchar(text) + 1  # Start with position beyond text
      earliest_keyword <- NULL
      
      for (keyword in title_keywords) {
        match_result <- regexpr(keyword, text, ignore.case = FALSE)
        
        if (match_result[1] != -1 && match_result[1] < earliest_position) {
          earliest_position <- match_result[1]
          earliest_keyword <- keyword
        }
      }
      
      # If we found a title keyword
      if (!is.null(earliest_keyword)) {
        # Everything before is the name (possibly with credentials)
        name_part <- substr(text, 1, earliest_position - 1)
        name_part <- trimws(name_part)
        
        # Remove credentials from name (B.Sc., MBA, MLT, LL.B., etc.)
        # First remove degree abbreviations with periods
        name_part <- gsub("\\s*,?\\s*[A-Z]\\.[A-Za-z\\.]+", "", name_part, perl = TRUE)
        # Then remove trailing acronyms (2+ capital letters at end)
        name_part <- gsub("\\s*,?\\s*[A-Z]{2,}\\s*$", "", name_part, perl = TRUE)
        # Remove any trailing commas
        name_part <- gsub("\\s*,\\s*$", "", name_part)
        name_part <- trimws(name_part)
        
        # Everything from earliest match onwards is the title (capture ALL of it)
        title_part <- substr(text, earliest_position, nchar(text))
        title_part <- trimws(title_part)
        
        # Skip if name is too short or looks wrong
        if (nchar(name_part) >= 3 && !grepl("^(The|A|An)\\s", name_part)) {
          pairs[[length(pairs) + 1]] <- list(
            name = name_part,
            title = title_part
          )
        }
      }
    }
    
    return(pairs)
  }
  
  # ============================================================
  # PATTERN 15: div_container_multiclass
  # Name and title in separate <p> tags with different classes within container divs
  # revised to include both p and div tags
  # ============================================================
  scrape_div_container_multiclass = function(page, hospital_info, config) {
    tryCatch({
      container_selector <- hospital_info$html_structure$container_selector %||% "[data-testid='mesh-container-content']"
      name_class <- hospital_info$html_structure$name_class %||% "font_5"
      title_class <- hospital_info$html_structure$title_class %||% "font_8"
      category_filter <- hospital_info$html_structure$category_filter %||% NULL
      element_type <- hospital_info$html_structure$element_type %||% "p"  # NEW: Allow div or p
      
      containers <- page %>% html_nodes(container_selector)
      
      # Initialize empty list for results
      pairs <- list()
      seen <- list()  # Track unique name-title combinations
      
      for (container in containers) {
        # Extract name - MODIFIED to use element_type
        if (name_class != "") {
          name <- container %>% 
            html_nodes(paste0(element_type, ".", name_class)) %>% 
            html_text2() %>%
            paste(collapse = " ") %>%
            str_trim()
          
          # Skip containers with multiple names (master containers)
          name_count <- container %>% 
            html_nodes(paste0(element_type, ".", name_class)) %>% 
            length()
          
          if (name_count > 1) next
        } else {
          name <- ""
        }
        
        # Extract title - MODIFIED to handle both classed and unclassed elements
        if (title_class != "") {
          # Standard: title has a class
          title_paragraphs <- container %>% 
            html_nodes(paste0(element_type, ".", title_class)) %>% 
            html_text2() %>%
            str_trim()
        } else {
          # NEW: Special case - title has NO class (get second div/p in container)
          all_elements <- container %>% html_nodes(element_type)
          if (length(all_elements) >= 2) {
            title_paragraphs <- all_elements[2] %>% html_text2() %>% str_trim()
          } else {
            title_paragraphs <- character(0)
          }
        }
        
        # Filter out category markers if specified
        if (!is.null(category_filter)) {
          title_paragraphs <- title_paragraphs[!title_paragraphs %in% category_filter]
        }
        
        # Combine remaining paragraphs as title
        title <- paste(title_paragraphs, collapse = " ") %>% str_trim()
        
        # Only add if we have both name and title, and haven't seen this combo
        if (name != "" && title != "" && nchar(title) > 0) {
          key <- paste(name, title, sep = "|||")
          if (!(key %in% names(seen))) {
            seen[[key]] <- TRUE
            pairs[[length(pairs) + 1]] <- list(
              name = clean_text_data(name),
              title = clean_text_data(title)
            )
          }
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  # ============================================================================
  # PATTERN 16: Table cells (each TD contains name + title)
  # ============================================================================
  # ============================================================================
  # PATTERN 16: Table cells (each TD contains name + title) rev2
  # ============================================================================
  scrape_table_cells <- function(page, hospital_info, config) {
    tryCatch({
      separator <- hospital_info$html_structure$separator %||% "\n"
      cells <- page %>% html_nodes("table td") %>% html_text2()
      pairs <- list()
      
      for (cell_text in cells) {
        # Skip empty cells BEFORE normalizing
        if (nchar(trimws(cell_text)) == 0 || cell_text == "Ã‚ ") next
        
        # Split by separator BEFORE normalizing (preserve newlines)
        lines <- strsplit(cell_text, separator, fixed = TRUE)[[1]]
        lines <- trimws(lines)
        lines <- lines[nchar(lines) > 0]
        
        if (length(lines) >= 2) {
          for (i in 1:(length(lines) - 1)) {
            # NOW normalize each line individually
            potential_name <- normalize_text(lines[i])
            potential_title <- normalize_text(lines[i + 1])
            
            if (is_executive_name(potential_name, config,hospital_info) && 
                is_executive_title(potential_title, config,hospital_info)) {
              pairs[[length(pairs) + 1]] <- list(
                name = clean_text_data(potential_name),
                title = clean_text_data(potential_title)
              )
              break
            }
          }
        }
      }
      
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(name = missing$name, title = missing$title)
        }
      }
      
      if (!is.null(hospital_info$expected_executives)) {
        max_count <- hospital_info$expected_executives
        if (length(pairs) > max_count) pairs <- pairs[1:max_count]
      }
      
      return(pairs)
    }, error = function(e) {
      message("Error in scrape_table_cells: ", e$message)
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 17: Single P element with BR-separated list (Title | Name)
  # ============================================================================
  scrape_p_with_br_list_reversed <- function(page, hospital_info, config) {
    tryCatch({
      separator <- hospital_info$html_structure$separator %||% " | "
      container_class <- hospital_info$html_structure$container_class %||% "elementor-icon-box-description"
      
      # Find the container paragraph
      p_elements <- page %>% html_nodes(paste0("p.", container_class))
      
      pairs <- list()
      
      for (p_elem in p_elements) {
        # Get HTML content and split by <br> tags
        html_content <- p_elem %>% html_children()
        text_content <- p_elem %>% html_text2()
        
        # Split by newlines (br tags become newlines with html_text2)
        lines <- strsplit(text_content, "\n")[[1]]
        lines <- trimws(lines)
        lines <- lines[nchar(lines) > 0]
        
        for (line in lines) {
          # Skip lines that don't contain the separator
          if (!grepl(separator, line, fixed = TRUE)) next
          
          # Split by separator
          parts <- strsplit(line, separator, fixed = TRUE)[[1]]
          if (length(parts) < 2) next
          
          # REVERSED: part1 is title, part2 is name
          potential_title <- trimws(parts[1])
          potential_name <- trimws(parts[2])
          
          if (is_executive_name(potential_name, config,hospital_info) && 
              is_executive_title(potential_title, config,hospital_info)) {
            pairs[[length(pairs) + 1]] <- list(
              name = clean_text_data(potential_name),
              title = clean_text_data(potential_title)
            )
          }
        }
      }
      
      if (!is.null(hospital_info$html_structure$missing_people)) {
        for (missing in hospital_info$html_structure$missing_people) {
          pairs[[length(pairs) + 1]] <- list(name = missing$name, title = missing$title)
        }
      }
      
      if (!is.null(hospital_info$expected_executives)) {
        max_count <- hospital_info$expected_executives
        if (length(pairs) > max_count) pairs <- pairs[1:max_count]
      }
      
      return(pairs)
    }, error = function(e) {
      message("Error in scrape_p_with_br_list_reversed: ", e$message)
      return(list())
    })
  }
  
  # ============================================================================
  # PATTERN 18: table_data_name_accordion
  # Structure: h2 name in div.factsheet__callout, td[data-name="accParent"] for title
  # Example: FAC-751 (CHEO)
  # ============================================================================
  scrape_table_data_name_accordion <- function(page, hospital_info, config) {
    tryCatch({
      pairs <- list()  # Changed from data.frame to list
      debug <- config$debug_mode
      non_name_pattern <- config$non_names_pattern
      
      # Get all factsheet callout containers
      containers <- page %>% html_nodes("div.factsheet__callout")
      
      if (length(containers) == 0) {
        if (debug) cat("DEBUG: No factsheet callout containers found\n")
        return(pairs)  # Changed to return empty list
      }
      
      for (container in containers) {
        # Extract name from h2
        name_node <- container %>% html_node("h2")
        if (length(name_node) == 0) next
        
        name <- name_node %>% html_text(trim = TRUE)
        
        # Extract title from table td with data-name="accParent"
        title_node <- container %>% html_node('td[data-name="accParent"]')
        if (length(title_node) == 0) next
        
        title <- title_node %>% html_text(trim = TRUE)
        
        # Validate both name and title exist
        if (is.na(name) || is.na(title) || nchar(name) == 0 || nchar(title) == 0) {
          next
        }
        
        # Apply standard validation
        passes_pattern <- !grepl(non_name_pattern, name, ignore.case = TRUE)
        
        if (debug && !passes_pattern) {
          cat(sprintf("DEBUG: Rejected name: '%s'\n", name))
        }
        
        if (passes_pattern) {
          pairs[[length(pairs) + 1]] <- list(  # Changed to list format
            name = name,
            title = title
          )
        }
      }
      
      return(pairs)  # Return list of lists
      
    }, error = function(e) {
      if (config$debug_mode) {
        cat("DEBUG: Error in table_data_name_accordion pattern:", e$message, "\n")
      }
      return(list())  # Return empty list on error
    })
  }
  
  # ============================================================================
  # PATTERN 19: p_strong_combined
  # Extracts name and title from <strong> tags within <p> elements
  # Ignores any text outside the <strong> tags (like bios in <em> or plain text)
  # ============================================================================
  scrape_p_strong_combined <- function(page, hospital_info, config) {
    tryCatch({
      # Get configuration
      separator <- hospital_info$html_structure$separator %||% ", "
      container_selector <- hospital_info$html_structure$container_selector %||% "p"
      
      # Find all strong tags within p elements
      strong_elements <- html_nodes(page, paste0(container_selector, " strong"))
      
      pairs <- list()
      
      for(strong in strong_elements) {
        text <- html_text(strong, trim = TRUE)
        text <- normalize_text(text)
        
        # Skip if no separator
        if(!grepl(separator, text, fixed = TRUE)) next
        
        # Split on separator
        parts <- strsplit(text, separator, fixed = TRUE)[[1]]
        if(length(parts) < 2) next
        
        name_part <- trimws(parts[1])
        title_part <- paste(parts[-1], collapse = separator)
        title_part <- trimws(title_part)
        
        # Validate
        if(is_executive_name(name_part, config,hospital_info) && 
           is_executive_title(title_part, config,hospital_info)) {
          pairs[[length(pairs) + 1]] <- list(
            name = clean_text_data(name_part),
            title = clean_text_data(title_part)
          )
        }
      }
      
      # Limit to expected count if specified
      if (!is.null(hospital_info$expected_executives)) {
        max_count <- hospital_info$expected_executives
        if (length(pairs) > max_count) {
          pairs <- pairs[1:max_count]
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
      # Special handling for manual entry - skip URL reading
      if (hospital_info$pattern == "manual_entry_required") {
        pairs <- scrape_manual_entry(NULL, hospital_info, config)
      } else {
        # Normal scraping for all other patterns
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
                        "p_with_bold_and_br" = scrape_p_with_bold_and_br(page, hospital_info, config),  # Pattern 12
                        "manual_entry_required" = scrape_manual_entry(page, hospital_info, config),  # â† ADD THIS
                        "h2_combined_complex" = scrape_h2_combined_complex(page, hospital_info, config),
                        "div_container_multiclass" = scrape_div_container_multiclass(page, hospital_info, config),
                        "table_cells" = scrape_table_cells(page, hospital_info, config),
                        "p_with_br_list_reversed" = scrape_p_with_br_list_reversed(page, hospital_info, config),
                        "table_data_name_accordion" = scrape_table_data_name_accordion(page, hospital_info, config),
                        "p_strong_combined" = scrape_p_strong_combined(page, hospital_info, config),
                        
                        # Default fallback 
                        scrape_h2_name_h3_title(page, hospital_info, config)
        )
      }
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
