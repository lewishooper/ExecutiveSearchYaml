# quality_analyzer.R - Tools to analyze and improve scraping quality
# Save this in E:/ClaudeExecScraper/code/

library(dplyr)
library(rvest)
library(stringr)

# Quality Analysis Functions
QualityAnalyzer <- function() {
  
  # Analyze the quality of scraped results
  analyze_results_quality <- function(results_df, output_folder = "E:/ClaudeExecScraper/output") {
    cat("=== QUALITY ANALYSIS REPORT ===\n\n")
    
    # Overall statistics
    total_records <- nrow(results_df)
    valid_records <- sum(!is.na(results_df$executive_name) & !is.na(results_df$executive_title))
    
    cat("OVERALL STATISTICS:\n")
    cat("- Total records:", total_records, "\n")
    cat("- Valid records:", valid_records, "\n")
    cat("- Success rate:", round(valid_records/total_records*100, 1), "%\n\n")
    
    # Method effectiveness
    cat("METHOD EFFECTIVENESS:\n")
    method_summary <- results_df %>%
      filter(!is.na(executive_name)) %>%
      group_by(scrape_method) %>%
      summarise(
        records = n(),
        hospitals = n_distinct(hospital_name),
        avg_per_hospital = round(n()/n_distinct(hospital_name), 1),
        .groups = "drop"
      ) %>%
      arrange(desc(records))
    
    print(method_summary)
    cat("\n")
    
    # Hospital-by-hospital performance
    cat("HOSPITAL PERFORMANCE:\n")
    hospital_summary <- results_df %>%
      group_by(FAC, hospital_name, scrape_method) %>%
      summarise(
        total_records = n(),
        valid_records = sum(!is.na(executive_name) & !is.na(executive_title)),
        .groups = "drop"
      ) %>%
      arrange(desc(valid_records))
    
    for (i in 1:nrow(hospital_summary)) {
      cat(sprintf("FAC-%s: %s - %d/%d valid (Method: %s)\n", 
                  hospital_summary$FAC[i], 
                  hospital_summary$hospital_name[i],
                  hospital_summary$valid_records[i],
                  hospital_summary$total_records[i],
                  hospital_summary$scrape_method[i]))
    }
    
    # Identify problem patterns
    cat("\nPROBLEM PATTERNS:\n")
    
    # Suspicious names (too short, all caps, etc.)
    suspicious_names <- results_df %>%
      filter(!is.na(executive_name)) %>%
      filter(
        nchar(executive_name) < 5 |
          nchar(executive_name) > 50 |
          grepl("^[A-Z]+$", executive_name) |
          grepl("\\d{3,}", executive_name) |
          grepl("^[a-z]+$", executive_name)
      )
    
    cat("- Suspicious names found:", nrow(suspicious_names), "\n")
    if (nrow(suspicious_names) > 0) {
      cat("  Examples:", paste(head(suspicious_names$executive_name, 3), collapse = ", "), "\n")
    }
    
    # Suspicious titles
    suspicious_titles <- results_df %>%
      filter(!is.na(executive_title)) %>%
      filter(
        nchar(executive_title) < 3 |
          nchar(executive_title) > 100 |
          !grepl("(CEO|Chief|President|Director|Officer|Administrator|Manager|VP|Vice)", executive_title, ignore.case = TRUE)
      )
    
    cat("- Suspicious titles found:", nrow(suspicious_titles), "\n")
    if (nrow(suspicious_titles) > 0) {
      cat("  Examples:", paste(head(suspicious_titles$executive_title, 3), collapse = ", "), "\n")
    }
    
    # Save detailed analysis
    analysis_file <- file.path(output_folder, paste0("quality_analysis_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"))
    
    detailed_analysis <- results_df %>%
      mutate(
        name_suspicious = ifelse(!is.na(executive_name),
                                 nchar(executive_name) < 5 | nchar(executive_name) > 50 | 
                                   grepl("^[A-Z]+$", executive_name) | grepl("\\d{3,}", executive_name), FALSE),
        title_suspicious = ifelse(!is.na(executive_title),
                                  nchar(executive_title) < 3 | nchar(executive_title) > 100 |
                                    !grepl("(CEO|Chief|President|Director|Officer|Administrator|Manager|VP|Vice)", executive_title, ignore.case = TRUE), FALSE),
        quality_score = case_when(
          is.na(executive_name) | is.na(executive_title) ~ 0,
          name_suspicious | title_suspicious ~ 1,
          TRUE ~ 2
        )
      )
    
    write.csv(detailed_analysis, analysis_file, row.names = FALSE)
    cat("\nDetailed analysis saved to:", basename(analysis_file), "\n")
    
    return(list(
      method_summary = method_summary,
      hospital_summary = hospital_summary,
      suspicious_names = suspicious_names,
      suspicious_titles = suspicious_titles,
      detailed_analysis = detailed_analysis
    ))
  }
  
  # Manual verification helper
  create_verification_sample <- function(results_df, sample_size = 10, output_folder = "E:/ClaudeExecScraper/output") {
    cat("Creating manual verification sample...\n")
    
    # Sample records for manual checking
    sample_records <- results_df %>%
      filter(!is.na(executive_name) & !is.na(executive_title)) %>%
      sample_n(min(sample_size, nrow(.))) %>%
      select(FAC, hospital_name, executive_name, executive_title, source_url, scrape_method)
    
    # Add verification columns
    sample_records$name_correct <- ""
    sample_records$title_correct <- ""
    sample_records$corrected_name <- ""
    sample_records$corrected_title <- ""
    sample_records$notes <- ""
    
    verification_file <- file.path(output_folder, paste0("verification_sample_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"))
    write.csv(sample_records, verification_file, row.names = FALSE)
    
    cat("Verification sample saved to:", basename(verification_file), "\n")
    cat("Instructions:\n")
    cat("1. Open this file in Excel\n")
    cat("2. For each row, visit the source_url\n")
    cat("3. Mark name_correct as TRUE/FALSE\n")
    cat("4. Mark title_correct as TRUE/FALSE\n")
    cat("5. Fill corrected_name and corrected_title if needed\n")
    cat("6. Save and use with improve_scrapers_from_verification()\n")
    
    return(verification_file)
  }
  
  # Improve scrapers based on manual verification
  improve_scrapers_from_verification <- function(verification_file) {
    cat("Analyzing verification results...\n")
    
    verification_data <- read.csv(verification_file, stringsAsFactors = FALSE)
    
    # Calculate accuracy by method
    method_accuracy <- verification_data %>%
      mutate(
        name_accurate = name_correct == "TRUE",
        title_accurate = title_correct == "TRUE",
        both_accurate = name_accurate & title_accurate
      ) %>%
      group_by(scrape_method) %>%
      summarise(
        records = n(),
        name_accuracy = round(mean(name_accurate, na.rm = TRUE) * 100, 1),
        title_accuracy = round(mean(title_accurate, na.rm = TRUE) * 100, 1),
        overall_accuracy = round(mean(both_accurate, na.rm = TRUE) * 100, 1),
        .groups = "drop"
      )
    
    cat("\nACCURACY BY METHOD:\n")
    print(method_accuracy)
    
    # Identify common error patterns
    errors <- verification_data %>%
      filter(name_correct == "FALSE" | title_correct == "FALSE")
    
    if (nrow(errors) > 0) {
      cat("\nCOMMON ERROR PATTERNS:\n")
      cat("- Total errors:", nrow(errors), "\n")
      
      error_methods <- table(errors$scrape_method)
      cat("- Methods with most errors:\n")
      for (method in names(sort(error_methods, decreasing = TRUE))) {
        cat("  *", method, ":", error_methods[method], "errors\n")
      }
    }
    
    return(method_accuracy)
  }
  
  # Create custom scraper for specific hospital
  create_hospital_specific_scraper <- function(fac_number, hospital_url) {
    cat("=== MANUAL INSPECTION FOR FAC-", sprintf("%03d", fac_number), "===\n")
    cat("URL:", hospital_url, "\n\n")
    
    tryCatch({
      page <- read_html(hospital_url)
      
      cat("PAGE ANALYSIS:\n")
      
      # 1. Check page structure
      cat("1. HTML Structure:\n")
      cat("   - H1:", length(page %>% html_nodes("h1")), "elements\n")
      cat("   - H2:", length(page %>% html_nodes("h2")), "elements\n")
      cat("   - H3:", length(page %>% html_nodes("h3")), "elements\n")
      cat("   - H4:", length(page %>% html_nodes("h4")), "elements\n")
      cat("   - Tables:", length(page %>% html_nodes("table")), "elements\n")
      cat("   - Divs with 'leader/exec' in class:", length(page %>% html_nodes("div[class*='leader'], div[class*='exec']")), "elements\n\n")
      
      # 2. Sample content from different elements
      cat("2. Sample Content:\n")
      
      h2_content <- page %>% html_nodes("h2") %>% html_text(trim = TRUE) %>% head(5)
      if (length(h2_content) > 0) {
        cat("   H2 elements:\n")
        for (i in 1:length(h2_content)) {
          cat("     ", i, ":", h2_content[i], "\n")
        }
      }
      
      h3_content <- page %>% html_nodes("h3") %>% html_text(trim = TRUE) %>% head(5)
      if (length(h3_content) > 0) {
        cat("   H3 elements:\n")
        for (i in 1:length(h3_content)) {
          cat("     ", i, ":", h3_content[i], "\n")
        }
      }
      
      # 3. Look for executive keywords
      page_text <- html_text(page)
      exec_keywords <- c("CEO", "Chief Executive", "President", "Chief Medical", "Administrator")
      
      cat("\n3. Executive Keywords Found:\n")
      for (kw in exec_keywords) {
        matches <- str_locate_all(page_text, regex(kw, ignore_case = TRUE))[[1]]
        if (nrow(matches) > 0) {
          cat("   -", kw, ":", nrow(matches), "times\n")
        }
      }
      
      # 4. Suggest custom selectors
      cat("\n4. SUGGESTED CUSTOM APPROACH:\n")
      cat("Based on this analysis, try:\n")
      
      # Check if names are in h2 and titles in h3
      name_pattern <- "(Dr\\.|Mr\\.|Ms\\.|Mrs\\.)?\\s*[A-Z][a-z]+ [A-Z][a-z]+"
      h2_names <- str_extract_all(paste(h2_content, collapse = " "), name_pattern)[[1]]
      
      if (length(h2_names) > 0) {
        cat("   - H2 elements contain names - use h2/h3 strategy\n")
      } else {
        cat("   - Look for table-based or div-based structure\n")
      }
      
    }, error = function(e) {
      cat("Error loading page:", e$message, "\n")
    })
  }
  
  # Return functions
  return(list(
    analyze_results_quality = analyze_results_quality,
    create_verification_sample = create_verification_sample,
    improve_scrapers_from_verification = improve_scrapers_from_verification,
    create_hospital_specific_scraper = create_hospital_specific_scraper
  ))
}