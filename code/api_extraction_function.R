# =============================================================================
# API EXTRACTION FUNCTION
# Claude API Screenshot Extraction - Phase 0 Prototype
# =============================================================================
# 
# Purpose: Send hospital leadership page screenshots to Claude API and extract
#          executive names and titles in structured JSON format
#
# Author: Skip (with Claude assistance)
# Date: January 9, 2026
# Version: 1.0
#
# Dependencies: httr, jsonlite, base64enc
# =============================================================================

library(httr)
library(jsonlite)
library(base64enc)

# =============================================================================
# EXTRACTION PROMPT
# =============================================================================

# Structured prompt for Claude API to extract executives from screenshot
EXECUTIVE_EXTRACTION_PROMPT <- '
You are analyzing a hospital leadership webpage screenshot. Your task is to extract ALL people and their titles visible in this image.

CRITICAL: Return ONLY a JSON array. No preamble, no explanation, no markdown code fences, no extra text.

Required JSON format:
[
  {"name": "Dr. John Smith, MD, MBA", "title": "Chief Executive Officer"},
  {"name": "Sarah Johnson, RN", "title": "Vice President, Patient Care, PhD"},
  {"name": "Robert Brown", "title": "Board Chair"}
]

EXTRACTION RULES:
1. Include ALL people shown on this leadership/executive page with any title or role
2. Extract the FULL name exactly as written (include middle initials, Dr., etc.)
3. Extract the COMPLETE title including any department/area information shown
4. CRITICAL - Credentials handling:
   - Credentials (MD, PhD, RN, MBA, etc.) may appear with the NAME, with the TITLE, or BOTH
   - Include credentials WHEREVER they appear in the original
   - Examples:
     * Name has credentials: "Dr. Jane Doe, MD, MBA" + Title: "Chief Executive Officer"
     * Title has credentials: Name: "Jane Doe" + Title: "Chief Executive Officer, MD, MBA"
     * Both have credentials: "Dr. Jane Doe, MD" + "Chief Medical Officer, FRCPC"
   - Extract exactly as shown - do not move or reorganize credentials
5. Do NOT extract contact information (email addresses, phone numbers, office locations)
6. Include board members, administrative assistants, and all staff shown on the page
7. Be INCLUSIVE - if someone is listed on this leadership page, extract them

IMPORTANT: Return ONLY the JSON array with NO additional text before or after.
'

# =============================================================================
# MAIN FUNCTION: extract_executives_from_screenshot
# =============================================================================

#' Extract Executives from Hospital Leadership Screenshot
#' 
#' Sends a screenshot to Claude API and extracts executive names and titles
#' in structured JSON format.
#'
#' @param screenshot_file Character. Full path to screenshot PNG file
#' @param api_key Character. Claude API key. Default: reads from environment variable
#' @param model Character. Claude model to use. Default: "claude-sonnet-4-20250514"
#' @param max_tokens Numeric. Maximum tokens for response. Default: 2000
#' @param temperature Numeric. Temperature (0 = deterministic). Default: 0.0
#' @param verbose Logical. Print detailed logging. Default: TRUE
#' @param max_retries Numeric. Number of retry attempts on failure. Default: 2
#'
#' @return List with:
#'   - success: Logical indicating if extraction succeeded
#'   - executives: Data frame with columns: name, title (if successful)
#'   - raw_response: Raw API response text (for debugging)
#'   - error_message: Error description (if failed)
#'   - api_cost_estimate: Estimated cost in USD (if successful)
#'   - timestamp: When extraction was performed
#'
#' @examples
#' result <- extract_executives_from_screenshot(
#'   screenshot_file = "E:/ExecutiveSearchYaml/temp/screenshot.png"
#' )
#' 
#' if (result$success) {
#'   print(result$executives)
#' }

extract_executives_from_screenshot <- function(
  screenshot_file,
  api_key = Sys.getenv("ANTHROPIC_API_KEY"),
  model = "claude-sonnet-4-20250514",
  max_tokens = 2000,
  temperature = 0.0,
  verbose = TRUE,
  max_retries = 2
) {
  
  # Validate inputs
  if (missing(screenshot_file) || !file.exists(screenshot_file)) {
    stop("screenshot_file must be a valid file path")
  }
  
  if (api_key == "") {
    stop("API key not found. Set ANTHROPIC_API_KEY environment variable or pass api_key parameter")
  }
  
  # Initialize result object
  result <- list(
    success = FALSE,
    executives = NULL,
    raw_response = NULL,
    error_message = NULL,
    api_cost_estimate = NULL,
    timestamp = Sys.time()
  )
  
  # Read and encode screenshot
  if (verbose) {
    cat(sprintf("[%s] Reading screenshot...\n", format(Sys.time(), "%H:%M:%S")))
    cat("  File:", screenshot_file, "\n")
    cat("  Size:", round(file.size(screenshot_file) / 1024, 1), "KB\n")
  }
  
  # Read image file
  img_data <- readBin(screenshot_file, "raw", file.size(screenshot_file))
  
  # Encode to base64
  img_base64 <- base64encode(img_data)
  
  if (verbose) {
    cat(sprintf("  Encoded size: %.1f KB\n", nchar(img_base64) / 1024))
  }
  
  # Retry loop
  for (attempt in 1:max_retries) {
    
    if (verbose && attempt > 1) {
      cat(sprintf("\nRetry attempt %d of %d\n", attempt - 1, max_retries - 1))
    }
    
    tryCatch({
      
      # Prepare API request
      if (verbose) {
        cat(sprintf("[%s] Sending to Claude API...\n", format(Sys.time(), "%H:%M:%S")))
        cat("  Model:", model, "\n")
        cat("  Max tokens:", max_tokens, "\n")
      }
      
      # Build request body
      request_body <- list(
        model = model,
        max_tokens = max_tokens,
        temperature = temperature,
        messages = list(
          list(
            role = "user",
            content = list(
              list(
                type = "image",
                source = list(
                  type = "base64",
                  media_type = "image/png",
                  data = img_base64
                )
              ),
              list(
                type = "text",
                text = EXECUTIVE_EXTRACTION_PROMPT
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
      
      # Check HTTP status
      if (status_code(response) != 200) {
        error_content <- content(response, "text", encoding = "UTF-8")
        stop(sprintf("API error (HTTP %d): %s", status_code(response), error_content))
      }
      
      # Parse response
      if (verbose) {
        cat(sprintf("[%s] Parsing response...\n", format(Sys.time(), "%H:%M:%S")))
      }
      
      response_data <- content(response, "parsed")
      
      # Extract text from response
      if (is.null(response_data$content) || length(response_data$content) == 0) {
        stop("API response has no content")
      }
      
      response_text <- response_data$content[[1]]$text
      result$raw_response <- response_text
      
      if (verbose) {
        cat("  Response length:", nchar(response_text), "characters\n")
        cat("  Response preview:", substr(response_text, 1, 100), "...\n")
      }
      
      # Clean response (remove any markdown code fences or preamble)
      cleaned_text <- response_text
      
      # Remove markdown code fences if present
      cleaned_text <- gsub("```json\\s*", "", cleaned_text)
      cleaned_text <- gsub("```\\s*", "", cleaned_text)
      
      # Remove any text before the first [ or {
      cleaned_text <- sub("^.*?([\\[\\{])", "\\1", cleaned_text)
      
      # Remove any text after the last ] or }
      cleaned_text <- sub("([\\]\\}]).*$", "\\1", cleaned_text)
      
      cleaned_text <- trimws(cleaned_text)
      
      if (verbose) {
        cat("  Cleaned response:", substr(cleaned_text, 1, 100), "...\n")
      }
      
      # Parse JSON
      if (verbose) {
        cat(sprintf("[%s] Parsing JSON...\n", format(Sys.time(), "%H:%M:%S")))
      }
      
      executives_list <- fromJSON(cleaned_text, simplifyDataFrame = TRUE)
      
      # Convert to data frame if it's a list
      if (is.list(executives_list) && !is.data.frame(executives_list)) {
        executives_df <- do.call(rbind, lapply(executives_list, function(x) {
          data.frame(
            name = ifelse(is.null(x$name), NA, x$name),
            title = ifelse(is.null(x$title), NA, x$title),
            stringsAsFactors = FALSE
          )
        }))
      } else if (is.data.frame(executives_list)) {
        executives_df <- executives_list
      } else {
        stop("Unexpected JSON structure returned by API")
      }
      
      # Validate data frame
      if (!all(c("name", "title") %in% names(executives_df))) {
        stop("JSON response missing required 'name' or 'title' fields")
      }
      
      if (verbose) {
        cat(sprintf("  Extracted %d executives\n", nrow(executives_df)))
      }
      
      # Estimate API cost
      # Rough estimate: ~$0.003 per image + tokens
      # This is approximate - actual cost depends on usage tier
      estimated_cost <- 0.003
      result$api_cost_estimate <- estimated_cost
      
      # Success!
      if (verbose) {
        cat(sprintf("[%s] âœ“ SUCCESS!\n", format(Sys.time(), "%H:%M:%S")))
        cat("  Executives extracted:", nrow(executives_df), "\n")
        cat("  Estimated cost: $", sprintf("%.4f", estimated_cost), "\n\n")
      }
      
      # Update result
      result$success <- TRUE
      result$executives <- executives_df
      result$error_message <- NULL
      
      # Success - break out of retry loop
      break
      
    }, error = function(e) {
      
      # Log error
      error_msg <- e$message
      if (verbose) {
        cat(sprintf("[%s] âœ— ERROR: %s\n", 
                   format(Sys.time(), "%H:%M:%S"),
                   error_msg))
      }
      
      # Update result with error
      result$error_message <- error_msg
      
      # If this was the last attempt, keep the error
      if (attempt == max_retries) {
        if (verbose) {
          cat("\nâœ— All retry attempts failed\n")
          cat("Final error:", error_msg, "\n\n")
        }
      }
      
    })
    
    # If successful, no need to retry
    if (result$success) {
      break
    }
    
    # Wait before retrying (exponential backoff)
    if (attempt < max_retries) {
      wait_time <- 2^attempt
      if (verbose) cat(sprintf("Waiting %d seconds before retry...\n", wait_time))
      Sys.sleep(wait_time)
    }
    
  }
  
  return(result)
}

# =============================================================================
# HELPER FUNCTION: batch_extract_executives
# =============================================================================

#' Batch Extract Executives from Multiple Screenshots
#'
#' @param screenshot_files Character vector. Paths to screenshot files
#' @param hospital_info Data frame with FAC and name columns (optional)
#' @param verbose Print progress
#'
#' @return Data frame with extraction results

batch_extract_executives <- function(
  screenshot_files,
  hospital_info = NULL,
  verbose = TRUE
) {
  
  cat("\n========================================\n")
  cat("BATCH API EXTRACTION\n")
  cat("========================================\n")
  cat("Total screenshots:", length(screenshot_files), "\n\n")
  
  all_results <- list()
  
  for (i in seq_along(screenshot_files)) {
    
    screenshot_file <- screenshot_files[i]
    
    cat(sprintf("\n[%d/%d] Processing: %s\n", 
                i, length(screenshot_files), 
                basename(screenshot_file)))
    cat("----------------------------------------\n")
    
    # Extract executives
    result <- extract_executives_from_screenshot(
      screenshot_file = screenshot_file,
      verbose = verbose
    )
    
    # Add hospital info if provided
    if (!is.null(hospital_info) && i <= nrow(hospital_info)) {
      if (result$success) {
        result$executives$FAC <- hospital_info$FAC[i]
        result$executives$hospital_name <- hospital_info$name[i]
      }
    }
    
    all_results[[i]] <- result
    
    # Brief pause between API calls
    if (i < length(screenshot_files)) {
      Sys.sleep(2)
    }
  }
  
  # Combine all successful extractions
  successful_results <- all_results[sapply(all_results, function(x) x$success)]
  
  if (length(successful_results) > 0) {
    combined_df <- do.call(rbind, lapply(successful_results, function(x) x$executives))
  } else {
    combined_df <- data.frame()
  }
  
  # Summary
  cat("\n========================================\n")
  cat("BATCH EXTRACTION SUMMARY\n")
  cat("========================================\n")
  cat("Total attempted:", length(all_results), "\n")
  cat("Successful:", sum(sapply(all_results, function(x) x$success)), "\n")
  cat("Failed:", sum(!sapply(all_results, function(x) x$success)), "\n")
  cat("Total executives extracted:", nrow(combined_df), "\n")
  
  total_cost <- sum(sapply(all_results, function(x) {
    ifelse(is.null(x$api_cost_estimate), 0, x$api_cost_estimate)
  }))
  cat("Total estimated cost: $", sprintf("%.4f", total_cost), "\n\n")
  
  return(combined_df)
}

# =============================================================================
# TEST FUNCTION
# =============================================================================

#' Test API Extraction Function
#'
#' Captures a test screenshot and extracts executives from it

test_api_extraction <- function() {
  
  cat("\n========================================\n")
  cat("TESTING API EXTRACTION FUNCTION\n")
  cat("========================================\n\n")
  
  # Check API key
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if (api_key == "") {
    cat("âœ— ERROR: ANTHROPIC_API_KEY not set\n")
    cat("Please set your API key and restart R\n\n")
    return(invisible(FALSE))
  }
  
  cat("âœ“ API key found\n\n")
  
  # Test 1: Capture screenshot first
  cat("STEP 1: Capturing test screenshot\n")
  cat("----------------------------------------\n")
  
  # Source the screenshot function if not already loaded
  if (!exists("capture_hospital_screenshot")) {
    cat("Loading screenshot capture function...\n")
    source("E:/ExecutiveSearchYaml/code/screenshot_capture_function.R")
  }
  
  # Capture Mount Sinai leadership page
  screenshot_result <- capture_hospital_screenshot(
    url = "https://www.sinaihealth.ca/about/leadership/",
    delay = 6,
    verbose = TRUE
  )
  
  if (!screenshot_result$success) {
    cat("\nâœ— Screenshot capture failed\n")
    cat("Error:", screenshot_result$error_message, "\n\n")
    return(invisible(FALSE))
  }
  
  cat("\nâœ“ Screenshot captured successfully\n\n")
  
  # Test 2: Extract executives
  cat("STEP 2: Extracting executives via API\n")
  cat("----------------------------------------\n")
  
  extraction_result <- extract_executives_from_screenshot(
    screenshot_file = screenshot_result$output_file,
    verbose = TRUE
  )
  
  if (!extraction_result$success) {
    cat("\nâœ— API extraction failed\n")
    cat("Error:", extraction_result$error_message, "\n\n")
    return(invisible(FALSE))
  }
  
  # Display results
  cat("\n========================================\n")
  cat("EXTRACTION RESULTS\n")
  cat("========================================\n\n")
  
  cat("Executives extracted:\n")
  print(extraction_result$executives)
  
  cat("\n")
  cat("Total executives:", nrow(extraction_result$executives), "\n")
  cat("Estimated cost: $", sprintf("%.4f", extraction_result$api_cost_estimate), "\n")
  
  cat("\n========================================\n")
  cat("TEST COMPLETE\n")
  cat("========================================\n")
  cat("âœ“ API extraction is working!\n\n")
  
  return(invisible(extraction_result))
}

# =============================================================================
# USAGE EXAMPLES
# =============================================================================

# Example 1: Extract from existing screenshot
if (FALSE) {
  result <- extract_executives_from_screenshot(
    screenshot_file = "E:/ExecutiveSearchYaml/temp/screenshot.png"
  )
  
  if (result$success) {
    print(result$executives)
  }
}

# Example 2: Full pipeline - capture and extract
if (FALSE) {
  # Capture screenshot
  screenshot_result <- capture_hospital_screenshot(
    url = "https://www.sinaihealth.ca/about/leadership/",
    delay = 6
  )
  
  # Extract executives
  if (screenshot_result$success) {
    extraction_result <- extract_executives_from_screenshot(
      screenshot_file = screenshot_result$output_file
    )
    
    if (extraction_result$success) {
      print(extraction_result$executives)
    }
  }
}

# Example 3: Run test
if (FALSE) {
  test_result <- test_api_extraction()
}

# =============================================================================
# END OF SCRIPT
# =============================================================================

cat("\nâœ“ API extraction function loaded successfully!\n")
cat("\nQuick Start:\n")
cat("  result <- extract_executives_from_screenshot(screenshot_file = '...')\n")
cat("\nRun test:\n")
cat("  test_api_extraction()\n\n")
