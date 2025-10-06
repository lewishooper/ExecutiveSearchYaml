# hybrid_scraper.R - YAML-configured hybrid scraper
# Save this in E:/ExecutiveSearchYaml/code/

library(rvest)
library(dplyr)
library(stringr)
library(yaml)

HybridScraper <- function() {
  
  # Generic h2/h3 approach (for hospitals that work well)
  scrape_generic_h2_h3 <- function(hospital_info) {
    tryCatch({
      page <- read_html(hospital_info$url)
      
      # Get h2 (names) and h3 (titles) in order
      h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
      h3_elements <- page %>% html_nodes("h3") %>% html_text(trim = TRUE)
      
      # Filter names (including Dr. titles)
      name_pattern <- "^(Dr\\.?\\s+)?[A-Z][a-z]+\\s+[A-Z][a-z]+$"
      names <- h2_elements[grepl(name_pattern, h2_elements)]
      
      # Filter titles (first N matching executive titles)
      title_keywords <- c("CEO", "Chief", "President", "Director", "Officer", "Administrator", 
                          "Manager", "Supervisor", "VP", "Vice President", "Medical", "Clinical")
      title_pattern <- paste(title_keywords, collapse = "|")
      titles <- h3_elements[grepl(title_pattern, h3_elements, ignore.case = TRUE)]
      
      # Limit to expected count if specified
      if (!is.null(hospital_info$expected_executives)) {
        titles <- titles[1:min(hospital_info$expected_executives, length(titles))]
      }
      
      # Pair names with titles
      pairs <- list()
      max_pairs <- min(length(names), length(titles))
      
      if (max_pairs > 0) {
        for (i in 1:max_pairs) {
          pairs[[i]] <- list(name = names[i], title = titles[i])
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Table-based approach with configuration
  scrape_table_configured <- function(hospital_info) {
    tryCatch({
      page <- read_html(hospital_info$url)
      tables <- page %>% html_table(fill = TRUE)
      
      config <- hospital_info$table_config
      pairs <- list()
      
      for (table in tables) {
        if (ncol(table) >= max(config$name_column, config$title_column) && nrow(table) > 0) {
          
          for (row_idx in 1:nrow(table)) {
            potential_name <- trimws(table[row_idx, config$name_column])
            potential_title <- trimws(table[row_idx, config$title_column])
            
            # Clean extensions and formatting
            potential_name <- str_remove_all(potential_name, "\\s*ext\\.\\s*\\d+.*$")
            potential_title <- str_remove_all(potential_title, "\\s*ext\\.\\s*\\d+.*$")
            
            # Check if valid name and title
            name_pattern <- "^(Dr\\.?\\s+)?[A-Z][a-z]+\\s+[A-Z][a-z]+$"
            title_keywords <- c("CEO", "Chief", "President", "Director", "Officer", "Administrator", 
                                "Manager", "Supervisor", "VP", "Vice President")
            title_pattern <- paste(title_keywords, collapse = "|")
            
            if (grepl(name_pattern, potential_name) && 
                grepl(title_pattern, potential_title, ignore.case = TRUE)) {
              
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
  
  # Custom approach with specific selectors and additional searches
  scrape_custom_configured <- function(hospital_info) {
    tryCatch({
      page <- read_html(hospital_info$url)
      config <- hospital_info$custom_config
      
      pairs <- list()
      
      # Get names from specified selectors
      names <- character(0)
      for (selector in config$name_selectors) {
        elements <- page %>% html_nodes(selector) %>% html_text(trim = TRUE)
        name_pattern <- "^(Dr\\.?\\s+)?[A-Z][a-z]+\\s+[A-Z][a-z]+$"
        valid_names <- elements[grepl(name_pattern, elements)]
        names <- c(names, valid_names)
      }
      
      # Get titles from specified selectors
      titles <- character(0)
      for (selector in config$title_selectors) {
        elements <- page %>% html_nodes(selector) %>% html_text(trim = TRUE)
        title_keywords <- c("CEO", "Chief", "President", "Director", "Officer", "Administrator", 
                            "Manager", "Supervisor", "VP", "Vice President")
        title_pattern <- paste(title_keywords, collapse = "|")
        valid_titles <- elements[grepl(title_pattern, elements, ignore.case = TRUE)]
        titles <- c(titles, valid_titles)
      }
      
      # Pair names with titles
      max_pairs <- min(length(names), length(titles))
      if (max_pairs > 0) {
        for (i in 1:max_pairs) {
          pairs[[i]] <- list(name = names[i], title = titles[i])
        }
      }
      
      # Add any additional_search items specified in config
      if (!is.null(config$additional_search)) {
        for (additional in config$additional_search) {
          # Parse "Name, Title" format
          parts <- strsplit(additional, ",")[[1]]
          if (length(parts) == 2) {
            pairs[[length(pairs) + 1]] <- list(
              name = trimws(parts[1]),
              title = trimws(parts[2])
            )
          }
        }
      }
      
      return(pairs)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Subpage navigation approach
  scrape_subpage <- function(hospital_info) {
    tryCatch({
      base_url <- hospital_info$url
      config <- hospital_info$subpage_config
      
      # Navigate to subpage if specified
      if (!is.null(config$leadership_link)) {
        # Construct full URL for subpage
        if (startsWith(config$leadership_link, "http")) {
          subpage_url <- config$leadership_link
        } else {
          # Relative URL - construct from base
          base_domain <- str_extract(base_url, "https?://[^/]+")
          subpage_url <- paste0(base_domain, config$leadership_link)
        }
        
        page <- read_html(subpage_url)
      } else {
        page <- read_html(base_url)
      }
      
      # Use generic approach on the subpage
      temp_hospital <- hospital_info
      temp_hospital$url <- if (!is.null(config$leadership_link)) subpage_url else base_url
      
      return(scrape_generic_h2_h3(temp_hospital))
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Generic fallback for unconfigured hospitals
  scrape_generic_fallback <- function(hospital_info) {
    tryCatch({
      page <- read_html(hospital_info$url)
      
      # Try multiple generic approaches
      approaches <- list(
        scrape_generic_h2_h3(hospital_info)
      )
      
      # Pick the approach with the most results
      best_result <- list()
      for (approach in approaches) {
        if (length(approach) > length(best_result)) {
          best_result <- approach
        }
      }
      
      return(best_result)
      
    }, error = function(e) {
      return(list())
    })
  }
  
  # Main scraper dispatcher
  scrape_hospital <- function(hospital_info) {
    cat("Scraping", hospital_info$name, "(FAC-", hospital_info$FAC, ")")
    
    # Determine scrape method
    method <- hospital_info$scrape_method %||% "generic"
    cat(" using method:", method, "\n")
    
    # Dispatch to appropriate scraper
    pairs <- switch(method,
                    "generic_h2_h3" = scrape_generic_h2_h3(hospital_info),
                    "table_configured" = scrape_table_configured(hospital_info),
                    "custom" = scrape_custom_configured(hospital_info),
                    "subpage" = scrape_subpage(hospital_info),
                    # Default fallback
                    scrape_generic_fallback(hospital_info)
    )
    
    # Convert pairs to data frame
    if (length(pairs) > 0) {
      names <- sapply(pairs, function(p) p$name)
      titles <- sapply(pairs, function(p) p$title)
      
      result_df <- data.frame(
        FAC = sprintf("%03d", as.numeric(hospital_info$FAC)),
        hospital_name = hospital_info$name,
        executive_name = names,
        executive_title = titles,
        scrape_date = Sys.Date(),
        source_url = hospital_info$url,
        scrape_method = paste0("hybrid_", method),
        stringsAsFactors = FALSE
      )
      
      cat("  Success:", length(pairs), "executives found\n")
      return(result_df)
      
    } else {
      cat("  No executives found\n")
      return(data.frame(
        FAC = sprintf("%03d", as.numeric(hospital_info$FAC)),
        hospital_name = hospital_info$name,
        executive_name = NA,
        executive_title = NA,
        scrape_date = Sys.Date(),
        source_url = hospital_info$url,
        scrape_method = paste0("hybrid_", method, "_no_results"),
        stringsAsFactors = FALSE
      ))
    }
  }
  
  # Batch processing
  scrape_batch <- function(hospitals_list, output_folder = "E:/ExecutiveSearchYaml/output") {
    all_results <- list()
    
    for (i in seq_along(hospitals_list)) {
      cat(sprintf("[%d/%d] ", i, length(hospitals_list)))
      result <- scrape_hospital(hospitals_list[[i]])
      all_results[[i]] <- result
      
      Sys.sleep(1)  # Rate limiting
    }
    
    # Combine and save results
    final_results <- bind_rows(all_results)
    
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_file <- file.path(output_folder, paste0("hybrid_scraper_results_", timestamp, ".csv"))
    write.csv(final_results, output_file, row.names = FALSE)
    
    # Summary
    cat("\n=== HYBRID SCRAPER SUMMARY ===\n")
    total_records <- nrow(final_results)
    valid_records <- sum(!is.na(final_results$executive_name))
    hospitals_with_data <- length(unique(final_results$hospital_name[!is.na(final_results$executive_name)]))
    
    cat("Total records:", total_records, "\n")
    cat("Valid records:", valid_records, "\n") 
    cat("Success rate:", round(valid_records / total_records * 100, 1), "%\n")
    cat("Hospitals with data:", hospitals_with_data, "out of", length(hospitals_list), "\n")
    cat("Results saved to:", basename(output_file), "\n")
    
    return(final_results)
  }
  
  return(list(
    scrape_hospital = scrape_hospital,
    scrape_batch = scrape_batch
  ))
}