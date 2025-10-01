# pattern_based_scraper.R - Enhanced scraper with pattern-based approach
# Save this in E:/ExecutiveSearchYaml/code/

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
  #load_config()
  # Check if text matches name patterns
  is_executive_name <- function(text, config) {
    if (is.na(text) || nchar(trimws(text)) < 3) return(FALSE)
    
    # Get name patterns from config
    name_patterns <- c(
      config$name_patterns$standard,
      config$name_patterns$with_titles,
      config$name_patterns$with_credentials,
      config$name_patterns$hyphenated_names,      # ADD
      config$name_patterns$complex_credentials    # ADD
    )
    
    # Clean text first (but preserve hyphens in names)
    clean_text <- str_remove_all(text, "\\s*ext\\.?\\s*\\d+.*$")
    clean_text <- trimws(clean_text)
    
    # Check against patterns
    matches_pattern <- any(sapply(name_patterns, function(p) grepl(p, clean_text)))
    
    # Exclude obvious non-names
    non_names <- c(
      "^(About|Our|The|Welcome|Contact|Services|Programs|News|Events)\\b",
      "^(Ontario|Ministry|Government|Hospital|Health|Department)\\b",
      "^(For Staff|Staff Only|General|Information)\\b"
    )
    
    is_non_name <- any(sapply(non_names, function(p) grepl(p, clean_text, ignore.case = TRUE)))
    
    return(matches_pattern && !is_non_name)
  }
  
  #End is_excutive_Name    #end check if text matches name patterns.
  # 
  
  # Check if text matches title patterns
  is_executive_title <- function(text, config) {
    if (is.na(text) || nchar(trimws(text)) < 3) return(FALSE)
    
    # Get all executive titles from config
    all_titles <- c(
      config$executive_titles$primary,
      config$executive_titles$secondary,
      config$executive_titles$medical_specific
    )
    
    # Clean text first
    clean_text <- str_remove_all(text, "\\s*ext\\.?\\s*\\d+.*$")
    clean_text <- trimws(clean_text)
    
    # Check if text contains any executive title
    return(any(sapply(all_titles, function(t) grepl(t, clean_text, ignore.case = TRUE))))
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
  
  # Pattern 1: H2 names + H3 titles
  scrape_h2_name_h3_title <- function(page, hospital_info, config) {
    tryCatch({
      # Get h2 and h3 elements
      h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
      h3_elements <- page %>% html_nodes("h3") %>% html_text(trim = TRUE)
      
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
  
  # Pattern 2: Combined name+title in single element
  scrape_combined_h2 <- function(page, hospital_info, config) {
    tryCatch({
      separator <- hospital_info$html_structure$separator %||% " - "
      element_type <- hospital_info$html_structure$combined_element %||% "h2"
      
      elements <- page %>% html_nodes(element_type) %>% html_text(trim = TRUE)
      
      pairs <- list()
      
      for (element_text in elements) {
        # Split by separator
        parts <- strsplit(element_text, separator)[[1]]
        
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
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Pattern 3: Table rows
  scrape_table_rows <- function(page, hospital_info, config) {
    tryCatch({
      tables <- page %>% html_table(fill = TRUE)
      
      name_col <- as.numeric(str_extract(hospital_info$html_structure$name_location, "\\d+"))
      title_col <- as.numeric(str_extract(hospital_info$html_structure$title_location, "\\d+"))
      
      pairs <- list()
      
      for (table in tables) {
        if (ncol(table) >= max(name_col, title_col) && nrow(table) > 0) {
          
          for (row_idx in 1:nrow(table)) {
            potential_name <- clean_text_data(table[row_idx, name_col])
            potential_title <- clean_text_data(table[row_idx, title_col])
            
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
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Pattern 4: H2 name + P title
  scrape_h2_name_p_title <- function(page, hospital_info, config) {
    tryCatch({
      # Get all h2 and p elements in order
      all_elements <- page %>% html_nodes("h2, p")
      
      pairs <- list()
      
      for (i in 1:(length(all_elements) - 1)) {
        current_element <- all_elements[[i]]
        next_element <- all_elements[[i + 1]]
        
        if (html_name(current_element) == "h2" && html_name(next_element) == "p") {
          current_text <- html_text(current_element, trim = TRUE)
          next_text <- html_text(next_element, trim = TRUE)
          
          if (is_executive_name(current_text, config) && 
              is_executive_title(next_text, config)) {
            
            pairs[[length(pairs) + 1]] <- list(
              name = clean_text_data(current_text),
              title = clean_text_data(next_text)
            )
          }
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Pattern 5: Div classes
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
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Pattern 6: List items
  scrape_list_items <- function(page, hospital_info, config) {
    tryCatch({
      li_elements <- page %>% html_nodes("li") %>% html_text(trim = TRUE)
      
      pairs <- list()
      
      for (li_text in li_elements) {
        # Try to split combined name+title in list items
        if (grepl(" - ", li_text) || grepl(", ", li_text)) {
          separator <- if (grepl(" - ", li_text)) " - " else ", "
          parts <- strsplit(li_text, separator)[[1]]
          
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
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Pattern 7: Boardcard gallery pattern (for Thunder Bay FAC=935)
  # Pattern for boardcard gallery (updated to include missing people)
  # test Lines
  #page="https://tbrhsc.net/about-us/leadership/"
  
  scrape_boardcard_pattern <- function(page, hospital_info, config) {
    tryCatch({
      boardcard_elements <- page %>% html_nodes("div.boardcard") %>% html_text(trim = TRUE)
      
      pairs <- list()
      
      for (boardcard_text in boardcard_elements) {
        clean_text <- clean_text_data(boardcard_text)
        
        if (grepl(",", clean_text)) {
          parts <- strsplit(clean_text, ",")[[1]]
          
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
      # pattern  9 
      # Pattern for custom table with nested elements (Queensway Carleton style)
      scrape_custom_table_nested <- function(page, hospital_info, config) {
        tryCatch({
          # Get all table cells that contain both p and div elements
          table_cells <- page %>% html_nodes("td")
          
          pairs <- list()
          
          for (cell in table_cells) {
            # Look for name in p with text-align: left style
            name_elements <- cell %>% html_nodes("p[style*='text-align: left'], p[style*='text-align:left']")
            
            # Look for title in div with text-align: left style  
            title_elements <- cell %>% html_nodes("div[style*='text-align: left'], div[style*='text-align:left']")
            
            if (length(name_elements) > 0 && length(title_elements) > 0) {
              # Extract name from first p element
              potential_name <- name_elements %>% 
                html_text(trim = TRUE) %>% 
                first()
              
              # Extract and combine titles from all div elements
              title_parts <- title_elements %>% 
                html_text(trim = TRUE)
              
              # Combine multiple title parts and clean
              potential_title <- paste(title_parts, collapse = " ")
              potential_title <- str_replace_all(potential_title, "\\s+", " ")  # Clean extra spaces
              potential_title <- trimws(potential_title)
              
              # Clean the extracted data
              potential_name <- clean_text_data(potential_name)
              potential_title <- clean_text_data(potential_title)
              
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
          
          return(unique_pairs)
          
        }, error = function(e) {
          return(list())
        })
      }
      
      
      
      # ADD THIS SECTION - Handle missing people from YAML config
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
  # test Lines
  #
  # Main scraper function
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
                      "boardcard_gallery" =scrape_boardcard_pattern(page, hospital_info, config),
                      "custom_table_nested" = scrape_custom_table_nested(page, hospital_info, config), 
                      "custom_table_nested" = scrape_custom_table_nested(page, hospital_info, config),
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
  
  # Batch processing
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
  
  # Test a single hospital configuration
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