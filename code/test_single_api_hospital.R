# =============================================================================
# SINGLE HOSPITAL API TEST
# Purpose: Test API extraction for one hospital without full batch run
# Author: Skip
# Date: January 16, 2026
# =============================================================================
#rm(list=ls())
project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}
source("code/api_extraction_function.R")
library(httr)
library(jsonlite)
library(base64enc)
library(yaml)

# Load validation if available (optional - will work without it)
if (file.exists("E:/ExecutiveSearchYaml/code/validation_function.R")) {
  source("E:/ExecutiveSearchYaml/code/validation_function.R")
}

# =============================================================================
# BUILT-IN API EXTRACTION FUNCTION
# =============================================================================

extract_executives_from_image <- function(image_path, hospital_name, hospital_type = NA) {
  #
  # Extract executive information from screenshot using Claude API
  #
  
  # Check API key
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if (api_key == "") {
    return(list(
      success = FALSE,
      error_message = "ANTHROPIC_API_KEY not set",
      executives = data.frame(),
      api_cost_estimate = 0,
      quality_score = 0
    ))
  }
  
  # Read and encode image
  tryCatch({
    image_data <- base64encode(image_path)
    file_size <- file.size(image_path)
    
    # Determine media type
    if (grepl("\\.png$", image_path, ignore.case = TRUE)) {
      media_type <- "image/png"
    } else if (grepl("\\.jpe?g$", image_path, ignore.case = TRUE)) {
      media_type <- "image/jpeg"
    } else {
      media_type <- "image/png"  # Default
    }
    
    # Build prompt
    prompt <- sprintf(
      'Extract ALL executive and leadership names and titles from this screenshot of %s leadership page.

For EACH person shown, provide:
- Their full name
- Their exact job title
- Any credentials (MD, PhD, RN, etc.)

Return ONLY a JSON array with this structure:
[
  {"name": "Full Name", "title": "Job Title", "credentials": "MD, PhD"},
  {"name": "Full Name", "title": "Job Title", "credentials": ""}
]

Rules:
- Include ALL executives shown (CEO, CFO, COO, VP, Directors, etc.)
- Include Board members if shown
- Exclude administrative assistants, secretaries unless explicitly executive
- If no credentials shown, use empty string
- Return ONLY the JSON array, no other text',
      hospital_name
    )
    
    # API request body
    request_body <- list(
      model = "claude-sonnet-4-20250514",
      max_tokens = 2000,
      messages = list(
        list(
          role = "user",
          content = list(
            list(
              type = "image",
              source = list(
                type = "base64",
                media_type = media_type,
                data = image_data
              )
            ),
            list(
              type = "text",
              text = prompt
            )
          )
        )
      )
    )
    
    # Make API call
    response <- POST(
      url = "https://api.anthropic.com/v1/messages",
      add_headers(
        "x-api-key" = api_key,
        "anthropic-version" = "2023-06-01",
        "content-type" = "application/json"
      ),
      body = toJSON(request_body, auto_unbox = TRUE),
      encode = "raw"
    )
    
    # Check response
    if (status_code(response) != 200) {
      return(list(
        success = FALSE,
        error_message = sprintf("API error: HTTP %d", status_code(response)),
        executives = data.frame(),
        api_cost_estimate = 0,
        quality_score = 0
      ))
    }
    
    # Parse response
    result <- content(response, "parsed")
    
    # Extract text from response
    if (!is.null(result$content) && length(result$content) > 0) {
      response_text <- result$content[[1]]$text
      
      # Clean JSON (remove markdown fences if present)
      response_text <- gsub("```json\\s*", "", response_text)
      response_text <- gsub("```\\s*$", "", response_text)
      response_text <- trimws(response_text)
      
      # Parse JSON
      executives_list <- fromJSON(response_text, simplifyDataFrame = FALSE)
      
      # Convert to data frame
      if (length(executives_list) > 0) {
        executives_df <- data.frame(
          name = sapply(executives_list, function(x) ifelse(is.null(x$name), NA, x$name)),
          title = sapply(executives_list, function(x) ifelse(is.null(x$title), NA, x$title)),
          credentials = sapply(executives_list, function(x) ifelse(is.null(x$credentials), "", x$credentials)),
          stringsAsFactors = FALSE
        )
        
        # Calculate cost estimate (rough)
        input_tokens <- result$usage$input_tokens
        output_tokens <- result$usage$output_tokens
        cost_estimate <- (input_tokens / 1000000 * 3.00) + (output_tokens / 1000000 * 15.00)
        
        # Simple quality score
        quality_score <- min(100, 50 + (nrow(executives_df) * 5))
        
        return(list(
          success = TRUE,
          executives = executives_df,
          api_cost_estimate = cost_estimate,
          quality_score = quality_score,
          usage = result$usage
        ))
        
      } else {
        return(list(
          success = FALSE,
          error_message = "No executives found in response",
          executives = data.frame(),
          api_cost_estimate = 0,
          quality_score = 0
        ))
      }
      
    } else {
      return(list(
        success = FALSE,
        error_message = "Empty API response",
        executives = data.frame(),
        api_cost_estimate = 0,
        quality_score = 0
      ))
    }
    
  }, error = function(e) {
    return(list(
      success = FALSE,
      error_message = paste("Error:", e$message),
      executives = data.frame(),
      api_cost_estimate = 0,
      quality_score = 0
    ))
  })
}

# =============================================================================
# MAIN FUNCTION: Test Single API Hospital
# =============================================================================

test_single_api_hospital <- function(fac_number, 
                                     screenshot_dir = "E:/ExecutiveSearchYaml/temp/screenshots",
                                     yaml_file = "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml") {
  
  cat("\n")
  cat("╔═══════════════════════════════════════════════╗\n")
  cat("║   SINGLE HOSPITAL API TEST                    ║\n")
  cat("╚═══════════════════════════════════════════════╝\n\n")
  
  # Check API key
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if (api_key == "") {
    stop("ERROR: ANTHROPIC_API_KEY not set.")
  }
  
  # Format FAC number
  fac_formatted <- sprintf("%03d", as.numeric(fac_number))
  
  cat(sprintf("Testing FAC-%s\n", fac_formatted))
  cat("─────────────────────────────────────────────────\n\n")
  
  # Load YAML to get hospital metadata
  yaml_config <- read_yaml(yaml_file)
  hospitals_list <- yaml_config$hospitals
  
  # Find hospital in YAML
  hospital_info <- NULL
  for (h in hospitals_list) {
    if (sprintf("%03d", as.numeric(h$FAC)) == fac_formatted) {
      hospital_info <- h
      break
    }
  }
  
  if (is.null(hospital_info)) {
    stop(sprintf("ERROR: FAC-%s not found in YAML configuration", fac_formatted))
  }
  
  cat(sprintf("Hospital: %s\n", hospital_info$name))
  cat(sprintf("Pattern: %s\n", hospital_info$pattern))
  cat(sprintf("URL: %s\n\n", hospital_info$url))
  
  # Find screenshot file
  screenshot_pattern <- sprintf("FAC-%s_.*\\.png$", fac_number)
  screenshot_files <- list.files(
    screenshot_dir,
    pattern = screenshot_pattern,
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  if (length(screenshot_files) == 0) {
    stop(sprintf("ERROR: No screenshot found for FAC-%s in %s\nExpected filename format: FAC-%s_YYYYMMDD.png", 
                 fac_formatted, screenshot_dir, fac_number))
  }
  
  if (length(screenshot_files) > 1) {
    cat("Multiple screenshots found. Using most recent:\n")
    file_info <- file.info(screenshot_files)
    screenshot_file <- rownames(file_info)[which.max(file_info$mtime)]
  } else {
    screenshot_file <- screenshot_files[1]
  }
  
  cat(sprintf("Screenshot: %s (%.1f KB)\n", basename(screenshot_file), file.size(screenshot_file) / 1024))
  cat(sprintf("Estimated cost: $0.003\n\n"))
  
  # Confirm
  cat("Press ENTER to proceed with API call or Ctrl+C to cancel...\n")
  readline()
  
  cat("\nProcessing...\n")
  cat("─────────────────────────────────────────────────\n\n")
  
  # Extract executives via API
  result <- extract_executives_from_image(
    image_path = screenshot_file,
    hospital_name = hospital_info$name,
    hospital_type = ifelse(!is.null(hospital_info$hospital_type), hospital_info$hospital_type, NA)
  )
  
  # Display results
  cat("\n")
  cat("╔═══════════════════════════════════════════════╗\n")
  cat("║              EXTRACTION RESULTS               ║\n")
  cat("╚═══════════════════════════════════════════════╝\n\n")
  
  if (result$success) {
    cat("✓ SUCCESS\n\n")
    
    executives <- result$executives
    cat(sprintf("Executives found: %d\n", nrow(executives)))
    cat(sprintf("API cost: $%.4f\n", result$api_cost_estimate))
    cat(sprintf("Quality score: %.2f\n\n", result$quality_score))
    
    if (nrow(executives) > 0) {
      cat("EXTRACTED EXECUTIVES:\n")
      cat("─────────────────────────────────────────────────\n")
      for (i in 1:nrow(executives)) {
        cat(sprintf("%2d. %s\n", i, executives$name[i]))
        cat(sprintf("    %s\n", executives$title[i]))
        if (!is.na(executives$credentials[i]) && executives$credentials[i] != "") {
          cat(sprintf("    Credentials: %s\n", executives$credentials[i]))
        }
        cat("\n")
      }
    }
    
    # Create standardized output matching pattern_based_scraper format
    output_df <- data.frame(
      FAC = fac_formatted,
      hospital_name = hospital_info$name,
      hospital_type = ifelse(!is.null(hospital_info$hospital_type), hospital_info$hospital_type, NA),
      executive_name = executives$name,
      executive_title = executives$title,
      date_gathered = Sys.Date(),
      source_url = hospital_info$url,
      pattern_used = "api_screenshot",
      data_status = "api_screenshot",
      robots_status = "api_method",
      robots_message = "Screenshot-based extraction",
      stringsAsFactors = FALSE
    )
    
    cat("STANDARDIZED OUTPUT:\n")
    cat("─────────────────────────────────────────────────\n")
    print(output_df[, c("FAC", "hospital_name", "executive_name", "executive_title")])
    cat("\n")
    
    return(list(
      success = TRUE,
      data = output_df,
      raw_result = result
    ))
    
  } else {
    cat("✗ FAILED\n\n")
    cat(sprintf("Error: %s\n", result$error_message))
    
    return(list(
      success = FALSE,
      error = result$error_message
    ))
  }
}

# =============================================================================
# USAGE EXAMPLES AND INSTRUCTIONS
# =============================================================================

cat("\n")
cat("═══════════════════════════════════════════════\n")
cat("  SINGLE HOSPITAL API TEST - LOADED\n")
cat("═══════════════════════════════════════════════\n\n")
cat("USAGE:\n")
cat("  result <- test_single_api_hospital(FAC_NUMBER)\n\n")
cat("EXAMPLE:\n")
cat("  # Test Pembroke (adjust FAC number)\n")
cat("  result <- test_single_api_hospital(935)\n\n")
cat("  # If successful:\n")
cat("  View(result$data)\n")
cat("  write.csv(result$data, 'output/temp/pembroke_test.csv', row.names=FALSE)\n\n")
cat("PREREQUISITES:\n")
cat("  1. Screenshot must exist in: E:/ExecutiveSearchYaml/temp/screenshots/\n")
cat("  2. Filename format: FAC-XXX_YYYYMMDD.png\n")
cat("  3. ANTHROPIC_API_KEY environment variable set\n\n")
cat("═══════════════════════════════════════════════\n\n")

# Quick test helper function
quick_api_test <- function(fac) {
  result <- test_single_api_hospital(fac)
  if (result$success) {
    cat("\n✓ Test successful! Data available in result$data\n")
    cat("To save: write.csv(result$data, 'your_filename.csv', row.names=FALSE)\n\n")
  }
  return(result)
}

results<-quick_api_test(763)
results$data

write.csv(results$data,
          "E:/ExecutiveSearchYaml/output/temp/pembroke_recovery_2026-01-01.csv",
          row.names = FALSE)
