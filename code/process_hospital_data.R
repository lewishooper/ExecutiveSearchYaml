# process_hospital_data.R
# Post-processing script for hospital executive data
# Converts raw scraper output into cleaned, classified datasets
# Version 1.0 - November 2025

# ==============================================================================
# SETUP AND DEPENDENCIES
# ==============================================================================

library(tidyverse)
library(lubridate)
library(stringr)
library(yaml)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# File paths
DEFAULT_CONFIG_FILE <- "enhanced_hospitals.yaml"
DEFAULT_OUTPUT_FOLDER <- "E:/ExecutiveSearchYaml/output"
DEFAULT_PROCESSED_FOLDER <- "E:/ExecutiveSearchYaml/processed"

# Validation thresholds
MAX_NAME_LENGTH <- 50
MAX_TITLE_LENGTH <- 100

# Common credentials patterns
# Common credentials patterns (expanded list)
CREDENTIAL_PATTERNS <- c(
  # Medical
  "MD", "MBBS", "DO", "FRCPC", "FRCSC", "CCFP", "FACEP", "FACP", "FACS",
  # Nursing
  "RN", "BScN", "MScN", "MN", "NP", "CNS", "CCRN", "CNA", "LPN", "RPN",
  # Academic
  "PhD", "DPhil", "EdD", "DSc", "ScD", "MSc", "MSW", "MA", "MPA", "MHA",
  "MBA", "MEd", "MPhil", "BSc", "BA", "BBA", "BComm",
  # Professional
  "CPA", "CGA", "CMA", "CA", "CFA", "CFP", "PMP", "CAPM", "CHRP", "CHRL", 
  "CHRE", "CIPD", "MCIPD", "CHE", "FACHE", "CPHR", "SHRM-SCP", "SHRM-CP",
  "FCPA", "FCMA", "MHS",
  # Health Administration
  "FACHE", "CHE", "CHFP", "CMPE", "FACMPE",
  # Allied Health
  "OT", "PT", "PharmD", "RPh", "DDS", "DMD", "OD", "AuD","RRT",
  # Legal
  "JD", "LLB", "LLM", "QC", "KC",
  # Other
  "PEng", "P.Eng", "PE", "CPSM", "CSP", "CSPO", "PMI-ACP"
)

# ==============================================================================
# MODULE 1: DATA NORMALIZATION
# ==============================================================================

normalize_raw_data <- function(raw_data, config) {
  cat("=== NORMALIZING DATA ===\n")
  
  # Ensure required columns exist
  required_cols <- c("FAC", "hospital_name", "executive_name", "executive_title", "date_gathered")
  missing_cols <- setdiff(required_cols, names(raw_data))
  
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Flatten if needed (in case of nested structures)
  if (is.list(raw_data) && !is.data.frame(raw_data)) {
    raw_data <- bind_rows(raw_data)
  }
  
  # Standardize field names
  normalized <- raw_data %>%
    rename_with(tolower) %>%
    rename_with(~ gsub("\\.", "_", .))
  
  # Ensure FAC is properly formatted (3 digits with leading zeros)
  normalized <- normalized %>%
    mutate(fac = sprintf("%03d", as.numeric(fac)))
  
  # Handle missing values
  normalized <- normalized %>%
    mutate(
      executive_name = if_else(is.na(executive_name) | executive_name == "", NA_character_, executive_name),
      executive_title = if_else(is.na(executive_title) | executive_title == "", NA_character_, executive_title)
    )
  
  # Normalize text encoding (UTF-8)
  normalized <- normalized %>%
    mutate(
      executive_name = iconv(executive_name, to = "UTF-8"),
      executive_title = iconv(executive_title, to = "UTF-8")
    )
  
  # Clean HTML entities
  normalized <- normalized %>%
    mutate(
      executive_name = str_replace_all(executive_name, "&nbsp;", " "),
      executive_name = str_replace_all(executive_name, "&amp;", "&"),
      executive_title = str_replace_all(executive_title, "&nbsp;", " "),
      executive_title = str_replace_all(executive_title, "&amp;", "&")
    )
  
  # Standardize Unicode for French names
  normalized <- normalized %>%
    mutate(
      executive_name = normalize_unicode(executive_name),
      executive_title = normalize_unicode(executive_title)
    )
  
  # Extract credentials from names
  normalized <- normalized %>%
    mutate(
      credentials = extract_credentials(executive_name),
      person_name = remove_credentials(executive_name)
    )
  
  # Validate name and title lengths
  normalized <- normalized %>%
    mutate(
      name_length_warning = nchar(person_name) > MAX_NAME_LENGTH,
      title_length_warning = nchar(executive_title) > MAX_TITLE_LENGTH
    )
  
  cat("  Normalized", nrow(normalized), "records\n")
  cat("  Name length warnings:", sum(normalized$name_length_warning, na.rm = TRUE), "\n")
  cat("  Title length warnings:", sum(normalized$title_length_warning, na.rm = TRUE), "\n")
  
  return(normalized)
}

# ==============================================================================
# HELPER: Normalize Unicode characters
# ==============================================================================
# ==============================================================================
# HELPER: Normalize Unicode characters revised version
# ==============================================================================

normalize_unicode <- function(text) {
  # Handle NA and empty values
  if (all(is.na(text))) return(text)
  
  # Vectorized processing
  result <- sapply(text, function(x) {
    if (is.na(x) || length(x) == 0 || x == "") return(x)
    
    # Normalize different Unicode representations of same characters
    x <- stringi::stri_trans_general(x, "Latin-ASCII; NFC")
    
    # Standardize apostrophes (', ', etc. → ')
    x <- str_replace_all(x, "['']", "'")
    
    # Normalize accented characters to their canonical form
    x <- stringi::stri_trans_nfc(x)
    
    return(x)
  }, USE.NAMES = FALSE)
  
  return(result)
}
# ==============================================================================
# HELPER: Extract credentials from name
# ==============================================================================
# ==============================================================================
# HELPER: Extract credentials from name revised
# ==============================================================================

extract_credentials <- function(name) {
  # Handle NA and empty values
  if (all(is.na(name))) return(rep(NA_character_, length(name)))
  
  # Build regex pattern for credentials
  pattern <- paste0("\\b(", paste(CREDENTIAL_PATTERNS, collapse = "|"), ")\\b")
  
  # Vectorized processing
  result <- sapply(name, function(x) {
    if (is.na(x) || length(x) == 0 || x == "") return(NA_character_)
    
    # Find all credentials
    credentials <- str_extract_all(x, pattern)[[1]]
    
    # Return comma-separated string or NA
    if (length(credentials) == 0) return(NA_character_)
    paste(unique(credentials), collapse = ", ")
  }, USE.NAMES = FALSE)
  
  return(result)
}


# ==============================================================================
# HELPER: Remove credentials from name
# ==============================================================================

# ==============================================================================
# HELPER: Remove credentials from name revised version
# ==============================================================================

remove_credentials <- function(name) {
  # Handle NA and empty values
  if (all(is.na(name))) return(name)
  
  # Build regex pattern for credentials
  pattern <- paste0(",?\\s*\\b(", paste(CREDENTIAL_PATTERNS, collapse = "|"), ")\\b")
  
  # Vectorized processing
  result <- sapply(name, function(x) {
    if (is.na(x) || length(x) == 0 || x == "") return(x)
    
    # Remove credentials and clean up
    clean_name <- str_remove_all(x, pattern)
    clean_name <- str_replace_all(clean_name, "\\s+", " ")
    clean_name <- str_trim(clean_name)
    
    # Remove trailing commas
    clean_name <- str_remove(clean_name, ",$")
    
    return(clean_name)
  }, USE.NAMES = FALSE)
  
  return(result)
}

# ==============================================================================
# MODULE 2: EMPLOYEE VS VOLUNTEER CLASSIFICATION
# ==============================================================================

classify_person_type <- function(data, config) {
  cat("\n=== CLASSIFYING EMPLOYEES VS VOLUNTEERS ===\n")
  
  # Load classification keywords from config if available
  volunteer_keywords <- get_volunteer_keywords(config)
  employee_keywords <- get_employee_keywords(config)
  
  # Classify each person
  data <- data %>%
    mutate(
      person_type = case_when(
        # Check volunteer rules first (priority order)
        is_volunteer(executive_title, volunteer_keywords) ~ "Volunteer",
        # If not volunteer, must be employee
        TRUE ~ "Employee"
      )
    )
  
  # Add priority flagging (only CEO and Board Chair)
  data <- data %>%
    mutate(
      priority_flag = is_priority_position(executive_title)
    )
  
  # Summary
  employee_count <- sum(data$person_type == "Employee", na.rm = TRUE)
  volunteer_count <- sum(data$person_type == "Volunteer", na.rm = TRUE)
  priority_count <- sum(data$priority_flag, na.rm = TRUE)
  
  cat("  Employees:", employee_count, "\n")
  cat("  Volunteers:", volunteer_count, "\n")
  cat("  Priority positions:", priority_count, "\n")
  
  return(data)
}

# ==============================================================================
# HELPER: Check if title matches volunteer criteria
# ==============================================================================

# ==============================================================================
# HELPER: Check if title matches volunteer criteria revised
# ==============================================================================
# ==============================================================================
# HELPER: Check if title matches volunteer criteria revised Again
# ==============================================================================
# ==============================================================================
# HELPER: Check if title matches volunteer criteria
# ==============================================================================

is_volunteer <- function(title, keywords = NULL) {
  # Handle NA and empty values
  if (all(is.na(title))) return(rep(FALSE, length(title)))
  
  # Default volunteer keywords if not provided
  if (is.null(keywords)) {
    keywords <- list(
      board_terms = c("board", "trustee", "governor"),
      volunteer_terms = c("volunteer")
    )
  }
  
  # Vectorized processing
  result <- sapply(title, function(t) {
    if (is.na(t) || t == "") return(FALSE)
    
    title_lower <- tolower(t)
    title_trimmed <- trimws(title_lower)
    
    # ========================================================================
    # PRIORITY RULE: Executive/Employee titles = NOT volunteer
    # Check this FIRST before any board-related terms
    # ========================================================================
    employee_override_patterns <- c(
      "president",
      "\\bceo\\b",
      "chief executive officer",
      "chief executive",
      "executive director",
      "executive assistant",
      "assistant to the ceo",
      "assistant to the president"
    )
    
    if (any(sapply(employee_override_patterns, function(x) grepl(x, title_lower)))) {
      return(FALSE)  # Employee, regardless of "board" mentions
    }
    
    # ========================================================================
    # RULE 1: Check for explicit board-related terms
    # ========================================================================
    # Board, Trustee, Governor = volunteer (but only if not caught by employee override above)
    if (grepl("\\btrustee\\b", title_lower) || grepl("\\bgovernor\\b", title_lower)) {
      return(TRUE)
    }
    
    # ========================================================================
    # RULE 2: Director patterns
    # ========================================================================
    # "Director" ONLY (nothing else) = volunteer
    if (title_trimmed == "director") {
      return(TRUE)
    }
    # "Director *" with literal asterisk = volunteer
    if (grepl("director\\s*\\*", title_lower)) {
      return(TRUE)
    }
    # If "director" appears with other words = employee
    if (grepl("director", title_lower)) {
      return(FALSE)
    }
    
    # ========================================================================
    # RULE 3: Chair patterns
    # ========================================================================
    if (grepl("chair", title_lower)) {
      # "Chair" by itself = volunteer
      if (title_trimmed == "chair") {
        return(TRUE)
      }
      
      # Board Chair patterns (volunteers)
      board_chair_patterns <- c(
        "board chair",
        "\\bvice chair\\b",  # word boundary to avoid "vice chair of medical"
        "first vice chair",
        "second vice chair",
        "past board chair",
        "past chair",
        "chair.+(quality|governance|planning|finance|resources|audit|nominating|hr).+committee",
        "chair.+committee"  # Generic board committee chair
      )
      
      if (any(sapply(board_chair_patterns, function(pat) grepl(pat, title_lower)))) {
        return(TRUE)
      }
      
      # Medical/Operational Chair patterns (employees)
      employee_chair_patterns <- c(
        "chair of the medical advisory committee",
        "chair.+medical advisory",
        "chair.+pharmacy",
        "chair.+therapeutics",
        "chair.+department",
        "department chair"
      )
      
      if (any(sapply(employee_chair_patterns, function(pat) grepl(pat, title_lower)))) {
        return(FALSE)
      }
    }
    
    # ========================================================================
    # RULE 4: Treasurer in board context = volunteer
    # ========================================================================
    if (grepl("treasurer", title_lower)) {
      # If treasurer is combined with board or committee terms = volunteer
      if (grepl("board|committee", title_lower)) {
        return(TRUE)
      }
      # If treasurer is standalone = volunteer
      if (title_trimmed == "treasurer") {
        return(TRUE)
      }
    }
    
    # ========================================================================
    # RULE 5: Board-only context (after employee override checked)
    # ========================================================================
    # If title contains "board" but we got here (not caught by employee override)
    # then it's likely a pure board volunteer role
    if (grepl("\\bboard\\b", title_lower)) {
      # But not if it contains operational words
      if (!grepl("secretary of the board|board secretary", title_lower)) {
        return(TRUE)
      }
    }
    
    # ========================================================================
    # RULE 6: Explicit volunteer designation
    # ========================================================================
    if (grepl("volunteer", title_lower)) {
      return(TRUE)
    }
    
    # ========================================================================
    # Default: if none of the above, assume employee
    # ========================================================================
    return(FALSE)
  }, USE.NAMES = FALSE)
  
  return(result)
}

# ==============================================================================
# HELPER: Check if position is priority (CEO or Board Chair only)
# ==============================================================================

# ==============================================================================
# HELPER: Check if position is priority (CEO or Board Chair only)
# ==============================================================================

is_priority_position <- function(title) {
  # Handle NA and empty values
  if (all(is.na(title))) return(rep(FALSE, length(title)))
  
  # Vectorized processing
  result <- sapply(title, function(t) {
    if (is.na(t) || t == "") return(FALSE)
    
    title_lower <- tolower(t)
    
    # Check for CEO
    is_ceo <- grepl("\\bchief executive officer\\b", title_lower) || 
      grepl("\\bceo\\b", title_lower)
    
    # Check for Board Chair
    is_board_chair <- grepl("\\bboard chair\\b", title_lower) ||
      grepl("\\bchair.+board\\b", title_lower) ||
      grepl("\\bchairperson\\b", title_lower)
    
    return(is_ceo || is_board_chair)
  }, USE.NAMES = FALSE)
  
  return(result)
}

# ==============================================================================
# HELPER: Get volunteer keywords from config
# ==============================================================================

get_volunteer_keywords <- function(config) {
  # Try to load from config, otherwise use defaults
  if (!is.null(config$recognition_config$volunteer_keywords)) {
    return(config$recognition_config$volunteer_keywords)
  }
  
  # Default keywords
  return(list(
    board_terms = c("board", "trustee", "governor"),
    chair_terms = c("chair", "vice chair", "first vice chair", "second vice chair"),
    other_terms = c("treasurer", "volunteer")
  ))
}

# ==============================================================================
# HELPER: Get employee keywords from config
# ==============================================================================

get_employee_keywords <- function(config) {
  # Try to load from config, otherwise use defaults
  if (!is.null(config$recognition_config$employee_keywords)) {
    return(config$recognition_config$employee_keywords)
  }
  
  # Default keywords
  return(list(
    executive_titles = c("ceo", "cfo", "coo", "cno", "cio", "cmo", "cos", "chief"),
    management_titles = c("director of", "manager", "coordinator", "administrator", 
                          "supervisor", "vice president", "vp", "president")
  ))
}

# ==============================================================================
# MODULE 3: DATA QUALITY STATUS ASSIGNMENT
# ==============================================================================

assign_data_status <- function(data) {
  cat("\n=== ASSIGNING DATA STATUS ===\n")
  
  # Determine status based on available fields
  data <- data %>%
    mutate(
      data_status = case_when(
        # Check for error messages first
        !is.na(error_message) ~ "failed",
        # Check robots status
        !is.na(robots_status) & robots_status == "blocked" ~ "robotstxt_blocked",
        !is.na(robots_status) & robots_status == "javascript_required" ~ "javascript_blocked",
        !is.na(robots_status) & robots_status == "blocked_general" ~ "blocked",
        # Check for manual entry
        !is.na(pattern_used) & pattern_used == "manual_entry_required" ~ "manual_entry",
        # Check if data was actually found
        is.na(person_name) | is.na(executive_title) ~ "failed",
        # Check for partial scrapes (could add hospital-specific logic here)
        !is.na(robots_message) & grepl("partial", tolower(robots_message)) ~ "partial_scrape",
        # Otherwise, successfully scraped
        TRUE ~ "scraped"
      )
    )
  
  # Summary
  status_summary <- data %>%
    count(data_status) %>%
    arrange(desc(n))
  
  cat("\nData Status Summary:\n")
  print(status_summary)
  
  return(data)
}

# ==============================================================================
# MODULE 4: OUTPUT GENERATION
# ==============================================================================
# ==============================================================================
# MODULE 4: OUTPUT GENERATION revised
# ==============================================================================

generate_output_datasets <- function(data, output_date = Sys.Date()) {
  cat("\n=== GENERATING OUTPUT DATASETS ===\n")
  
  # Format output date
  date_str <- format(output_date, "%Y-%m-%d")
  
  # Create notes field with validation flags FIRST
  data <- data %>%
    mutate(
      notes = case_when(
        name_length_warning & title_length_warning ~ "name_length_warning, title_length_warning",
        name_length_warning ~ "name_length_warning",
        title_length_warning ~ "title_length_warning",
        TRUE ~ NA_character_
      )
    )
  
  # Split into employees and volunteers
  employees <- data %>%
    filter(person_type == "Employee") %>%
    select(
      hospital_name,
      fac_number = fac,
      hospital_type,
      person_name,
      credentials,
      title = executive_title,
      collection_date = date_gathered,
      data_status,
      source_url = url,
      pattern_used,
      notes
    )
  
  volunteers <- data %>%
    filter(person_type == "Volunteer") %>%
    select(
      hospital_name,
      fac_number = fac,
      hospital_type,
      person_name,
      credentials,
      title = executive_title,
      collection_date = date_gathered,
      data_status,
      source_url = url,
      pattern_used,
      notes
    )
  
  cat("  Employees dataset:", nrow(employees), "records\n")
  cat("  Volunteers dataset:", nrow(volunteers), "records\n")
  
  return(list(
    employees = employees,
    volunteers = volunteers
  ))
}


# ==============================================================================
# HELPER: Save datasets to CSV
# ==============================================================================

save_datasets <- function(datasets, output_folder = DEFAULT_PROCESSED_FOLDER, 
                          output_date = Sys.Date()) {
  
  # Create output folder if it doesn't exist
  if (!dir.exists(output_folder)) {
    dir.create(output_folder, recursive = TRUE)
  }
  
  # Format date for filename
  date_str <- format(output_date, "%Y-%m-%d")
  
  # Save employees
  employees_file <- file.path(output_folder, 
                              paste0("HospitalExecutives_Employees_", date_str, ".csv"))
  write_csv(datasets$employees, employees_file)
  cat("  Saved:", employees_file, "\n")
  
  # Save volunteers
  volunteers_file <- file.path(output_folder, 
                               paste0("HospitalExecutives_Volunteers_", date_str, ".csv"))
  write_csv(datasets$volunteers, volunteers_file)
  cat("  Saved:", volunteers_file, "\n")
  
  return(list(
    employees_file = employees_file,
    volunteers_file = volunteers_file
  ))
}

# ==============================================================================
# MAIN PROCESSING FUNCTION
# ==============================================================================

process_hospital_data <- function(input_file, 
                                  config_file = DEFAULT_CONFIG_FILE,
                                  output_folder = DEFAULT_PROCESSED_FOLDER,
                                  output_date = Sys.Date()) {
  
  cat("\n")
  cat("================================================================================\n")
  cat("  HOSPITAL EXECUTIVE DATA PROCESSING\n")
  cat("================================================================================\n\n")
  
  start_time <- Sys.time()
  
  # Load configuration
  cat("Loading configuration from:", config_file, "\n")
  config <- yaml::read_yaml(config_file)
  
  # Load raw data
  # Load raw data revised
  cat("Loading raw data from:", input_file, "\n")
  raw_data <- read_csv(input_file, show_col_types = FALSE)
  # Convert FAC to character to match YAML format
  raw_data <- raw_data %>%
    mutate(FAC = sprintf("%03d", as.numeric(FAC)))
  cat("  Loaded", nrow(raw_data), "raw records\n\n")
  # Add hospital_type from config
  raw_data <- raw_data %>%
    left_join(
      tibble(
        FAC = sapply(config$hospitals, function(h) h$FAC),
        hospital_type = sapply(config$hospitals, function(h) h$hospital_type %||% "Unknown"),
        url = sapply(config$hospitals, function(h) h$url),
        pattern_used = sapply(config$hospitals, function(h) h$pattern)
      ),
      by = "FAC"
    )
  
  # Step 1: Normalize data
  normalized_data <- normalize_raw_data(raw_data, config)
  
  # Step 2: Classify employees vs volunteers
  classified_data <- classify_person_type(normalized_data, config)
  
  # Step 3: Assign data status
  status_data <- assign_data_status(classified_data)
  
  # Step 4: Generate output datasets
  datasets <- generate_output_datasets(status_data, output_date)
  
  # Step 5: Save to files
  cat("\n=== SAVING OUTPUT FILES ===\n")
  output_files <- save_datasets(datasets, output_folder, output_date)
  
  # Summary
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  cat("\n")
  cat("================================================================================\n")
  cat("  PROCESSING COMPLETE\n")
  cat("================================================================================\n")
  cat("  Duration:", round(duration, 2), "seconds\n")
  cat("  Input records:", nrow(raw_data), "\n")
  cat("  Employees:", nrow(datasets$employees), "\n")
  cat("  Volunteers:", nrow(datasets$volunteers), "\n")
  cat("  Output files:\n")
  cat("    -", basename(output_files$employees_file), "\n")
  cat("    -", basename(output_files$volunteers_file), "\n")
  cat("================================================================================\n\n")
  
  return(list(
    employees = datasets$employees,
    volunteers = datasets$volunteers,
    files = output_files
  ))
}

# ==============================================================================
# VALIDATION HELPER FUNCTION
# ==============================================================================

validate_classification <- function(processed_data, sample_size = 100) {
  cat("\n=== VALIDATION SAMPLE ===\n")
  cat("Generating sample of", sample_size, "records for manual review\n\n")
  
  # Weight toward Large and Teaching hospitals
  sample_data <- processed_data %>%
    mutate(
      weight = case_when(
        hospital_type %in% c("Large Community", "Teaching") ~ 3,
        TRUE ~ 1
      )
    ) %>%
    slice_sample(n = min(sample_size, nrow(.)), weight_by = weight)
  
  # Show sample
  sample_review <- sample_data %>%
    select(hospital_name, hospital_type, person_name, title, person_type, priority_flag) %>%
    arrange(hospital_type, hospital_name)
  
  return(sample_review)
}

# ==============================================================================
# USAGE EXAMPLES
# ==============================================================================

# Example 1: Process most recent scraping output
# result <- process_hospital_data(
#   input_file = "E:/ExecutiveSearchYaml/output/hospital_executives_20251201.csv",
#   config_file = "enhanced_hospitals.yaml",
#   output_folder = "E:/ExecutiveSearchYaml/processed"
# )

# Example 2: Process with specific date
# result <- process_hospital_data(
#   input_file = "E:/ExecutiveSearchYaml/output/all_hospitals_20251201_120000.csv",
#   output_date = as.Date("2025-12-01")
# )

# Example 3: Generate validation sample
# validation_sample <- validate_classification(
#   bind_rows(result$employees, result$volunteers),
#   sample_size = 100
# )
# write_csv(validation_sample, "validation_sample.csv")

cat("\n=== process_hospital_data.R loaded ===\n")
cat("Main function: process_hospital_data(input_file, config_file, output_folder, output_date)\n")
cat("Validation: validate_classification(processed_data, sample_size)\n\n")