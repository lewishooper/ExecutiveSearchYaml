# =============================================================================
# SCREENSHOT CAPTURE FUNCTION - WEBSHOT2 VERSION
# Claude API Screenshot Extraction - Phase 0 Prototype
# =============================================================================
# 
# Purpose: Capture full-page screenshots of hospital leadership webpages
#          using webshot2 package (more reliable than chromote)
#
# Author: Skip (with Claude assistance)
# Date: January 9, 2026
# Version: 2.0 - Rebuilt with webshot2
#
# Dependencies: webshot2
# =============================================================================

library(webshot2)

# =============================================================================
# MAIN FUNCTION: capture_hospital_screenshot
# =============================================================================

#' Capture Screenshot of Hospital Leadership Page
#' 
#' Uses webshot2 to capture a full-page screenshot of a hospital's leadership page.
#'
#' @param url Character. The URL of the hospital's leadership page
#' @param output_file Character. Full path where screenshot should be saved
#'                    Default: NULL (auto-generates filename in temp directory)
#' @param delay Numeric. Seconds to wait for page load. Default: 5
#' @param vwidth Numeric. Browser viewport width in pixels. Default: 1280
#' @param vheight Numeric. Browser viewport height in pixels. Default: 1024
#' @param zoom Numeric. Zoom factor (1.0 = 100%). Default: 1
#' @param verbose Logical. Print detailed logging messages. Default: TRUE
#' @param max_retries Numeric. Number of retry attempts on failure. Default: 2
#'
#' @return List with:
#'   - success: Logical indicating if capture succeeded
#'   - output_file: Path to saved screenshot (if successful)
#'   - file_size: Size of screenshot in bytes (if successful)
#'   - error_message: Error description (if failed)
#'   - timestamp: When screenshot was captured
#'   - url: URL that was captured
#'
#' @examples
#' # Basic usage
#' result <- capture_hospital_screenshot(
#'   url = "https://www.sinaihealth.ca/about/leadership/"
#' )
#' 
#' # With custom settings
#' result <- capture_hospital_screenshot(
#'   url = "https://example.com/leadership",
#'   output_file = "E:/ExecutiveSearchYaml/temp/test.png",
#'   delay = 8,
#'   verbose = TRUE
#' )

capture_hospital_screenshot <- function(
  url,
  output_file = NULL,
  delay = 5,
  vwidth = 1280,
  vheight = 1024,
  zoom = 1,
  verbose = TRUE,
  max_retries = 2
) {
  
  # Validate inputs
  if (missing(url) || is.null(url) || url == "") {
    stop("url parameter is required and cannot be empty")
  }
  
  # Auto-generate output filename if not provided
  if (is.null(output_file)) {
    # Create temp directory if it doesn't exist
    temp_dir <- "E:/ExecutiveSearchYaml/temp"
    if (!dir.exists(temp_dir)) {
      dir.create(temp_dir, recursive = TRUE)
      if (verbose) cat("Created temp directory:", temp_dir, "\n")
    }
    
    # Generate filename with timestamp
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_file <- file.path(temp_dir, paste0("screenshot_", timestamp, ".png"))
  }
  
  # Ensure output directory exists
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    if (verbose) cat("Created output directory:", output_dir, "\n")
  }
  
  # Initialize result object
  result <- list(
    success = FALSE,
    output_file = NULL,
    file_size = NULL,
    error_message = NULL,
    timestamp = Sys.time(),
    url = url
  )
  
  # Retry loop
  for (attempt in 1:max_retries) {
    
    if (verbose && attempt > 1) {
      cat(sprintf("\nRetry attempt %d of %d\n", attempt - 1, max_retries - 1))
    }
    
    tryCatch({
      
      if (verbose) {
        cat(sprintf("[%s] Capturing screenshot...\n", format(Sys.time(), "%H:%M:%S")))
        cat("  URL:", url, "\n")
        cat("  Viewport:", vwidth, "x", vheight, "\n")
        cat("  Delay:", delay, "seconds\n")
      }
      
      # Capture screenshot using webshot2
      webshot2::webshot(
        url = url,
        file = output_file,
        vwidth = vwidth,
        vheight = vheight,
        delay = delay,
        zoom = zoom
      )
      
      # Verify file was created
      if (!file.exists(output_file)) {
        stop("Screenshot file was not created")
      }
      
      file_size <- file.size(output_file)
      
      if (file_size == 0) {
        stop("Screenshot file is empty (0 bytes)")
      }
      
      # Validate minimum file size (real screenshots should be at least 1KB)
      if (file_size < 1000) {
        stop(sprintf("Screenshot file too small (%d bytes) - likely invalid or blank page", file_size))
      }
      
      # Success!
      if (verbose) {
        cat(sprintf("[%s] ✓ SUCCESS!\n", format(Sys.time(), "%H:%M:%S")))
        cat("  Output file:", output_file, "\n")
        cat("  File size:", format(file_size, big.mark = ","), "bytes\n")
        cat("  File size:", round(file_size / 1024, 1), "KB\n\n")
      }
      
      # Update result object
      result$success <- TRUE
      result$output_file <- output_file
      result$file_size <- file_size
      result$error_message <- NULL
      
      # Success - break out of retry loop
      break
      
    }, error = function(e) {
      
      # Log error
      error_msg <- e$message
      if (verbose) {
        cat(sprintf("[%s] ✗ ERROR: %s\n", 
                   format(Sys.time(), "%H:%M:%S"),
                   error_msg))
      }
      
      # Update result with error
      result$error_message <- error_msg
      
      # If this was the last attempt, keep the error
      if (attempt == max_retries) {
        if (verbose) {
          cat("\n✗ All retry attempts failed\n")
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
      wait_time <- 2^attempt  # 2, 4, 8 seconds
      if (verbose) cat(sprintf("Waiting %d seconds before retry...\n", wait_time))
      Sys.sleep(wait_time)
    }
    
  }
  
  return(result)
}

# =============================================================================
# HELPER FUNCTION: batch_capture_screenshots
# =============================================================================

#' Batch Capture Screenshots for Multiple Hospitals
#' 
#' Captures screenshots for a list of hospitals, with progress reporting
#' and error handling.
#'
#' @param hospitals_df Data frame with columns: FAC, name, url
#' @param output_dir Directory where screenshots will be saved
#' @param delay Seconds to wait for each page load
#' @param verbose Print progress messages
#'
#' @return Data frame with capture results for each hospital

batch_capture_screenshots <- function(
  hospitals_df,
  output_dir = "E:/ExecutiveSearchYaml/temp/screenshots",
  delay = 5,
  verbose = TRUE
) {
  
  # Ensure output directory exists
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Initialize results
  results <- list()
  
  cat("\n========================================\n")
  cat("BATCH SCREENSHOT CAPTURE\n")
  cat("========================================\n")
  cat("Total hospitals:", nrow(hospitals_df), "\n")
  cat("Output directory:", output_dir, "\n\n")
  
  # Process each hospital
  for (i in 1:nrow(hospitals_df)) {
    
    hospital <- hospitals_df[i, ]
    
    cat(sprintf("\n[%d/%d] Processing FAC-%s: %s\n", 
                i, nrow(hospitals_df), 
                hospital$FAC, hospital$name))
    cat("----------------------------------------\n")
    
    # Generate output filename
    output_file <- file.path(
      output_dir,
      paste0("FAC-", hospital$FAC, "_", 
             format(Sys.Date(), "%Y%m%d"), ".png")
    )
    
    # Capture screenshot
    result <- capture_hospital_screenshot(
      url = hospital$url,
      output_file = output_file,
      delay = delay,
      verbose = verbose
    )
    
    # Add hospital info to result
    result$FAC <- hospital$FAC
    result$hospital_name <- hospital$name
    
    # Store result
    results[[i]] <- result
    
    # Brief pause between hospitals
    if (i < nrow(hospitals_df)) {
      Sys.sleep(2)
    }
  }
  
  # Convert to data frame
  results_df <- do.call(rbind, lapply(results, function(r) {
    data.frame(
      FAC = r$FAC,
      hospital_name = r$hospital_name,
      success = r$success,
      output_file = ifelse(is.null(r$output_file), NA, r$output_file),
      file_size = ifelse(is.null(r$file_size), NA, r$file_size),
      error_message = ifelse(is.null(r$error_message), NA, r$error_message),
      timestamp = as.character(r$timestamp),
      stringsAsFactors = FALSE
    )
  }))
  
  # Summary
  cat("\n========================================\n")
  cat("BATCH CAPTURE SUMMARY\n")
  cat("========================================\n")
  cat("Total attempted:", nrow(results_df), "\n")
  cat("Successful:", sum(results_df$success), "\n")
  cat("Failed:", sum(!results_df$success), "\n")
  
  if (any(!results_df$success)) {
    cat("\nFailed hospitals:\n")
    failed <- results_df[!results_df$success, ]
    for (i in 1:nrow(failed)) {
      cat(sprintf("  - FAC-%s: %s\n", failed$FAC[i], failed$error_message[i]))
    }
  }
  
  cat("\n")
  
  return(results_df)
}

# =============================================================================
# TEST FUNCTION
# =============================================================================

#' Test Screenshot Capture Function
#' 
#' Runs basic tests on the screenshot capture function

test_screenshot_capture <- function() {
  
  cat("\n========================================\n")
  cat("TESTING SCREENSHOT CAPTURE FUNCTION\n")
  cat("========================================\n\n")
  
  # Test 1: Simple example.com
  cat("TEST 1: Simple webpage (example.com)\n")
  cat("----------------------------------------\n")
  result1 <- capture_hospital_screenshot(
    url = "https://www.example.com",
    delay = 3,
    verbose = TRUE
  )
  
  cat("\nTest 1 Result:", ifelse(result1$success, "✓ PASS", "✗ FAIL"), "\n")
  if (result1$success) {
    cat("File size:", round(result1$file_size / 1024, 1), "KB\n")
  }
  
  # Test 2: Hospital website (Mount Sinai)
  cat("\n\nTEST 2: Hospital leadership page\n")
  cat("----------------------------------------\n")
  result2 <- capture_hospital_screenshot(
    url = "https://www.sinaihealth.ca/about/leadership/",
    delay = 6,
    verbose = TRUE
  )
  
  cat("\nTest 2 Result:", ifelse(result2$success, "✓ PASS", "✗ FAIL"), "\n")
  if (result2$success) {
    cat("File size:", round(result2$file_size / 1024, 1), "KB\n")
  }
  
  # Test 3: Error handling (invalid URL)
  cat("\n\nTEST 3: Error handling (invalid URL)\n")
  cat("----------------------------------------\n")
  result3 <- capture_hospital_screenshot(
    url = "https://this-domain-does-not-exist-12345.com",
    delay = 3,
    verbose = TRUE,
    max_retries = 1
  )
  
  cat("\nTest 3 Result:", ifelse(!result3$success, "✓ PASS (error handled)", "✗ FAIL"), "\n")
  
  # Summary
  cat("\n========================================\n")
  cat("TEST SUMMARY\n")
  cat("========================================\n")
  cat("Test 1 (Simple page):", ifelse(result1$success, "✓ PASS", "✗ FAIL"), "\n")
  cat("Test 2 (Hospital page):", ifelse(result2$success, "✓ PASS", "✗ FAIL"), "\n")
  cat("Test 3 (Error handling):", ifelse(!result3$success, "✓ PASS", "✗ FAIL"), "\n")
  
  tests_passed <- sum(c(result1$success, result2$success, !result3$success))
  cat("\nTotal:", tests_passed, "/ 3 tests passed\n")
  
  if (tests_passed >= 2) {
    cat("\n✓ Screenshot capture is working!\n")
    cat("Ready to proceed to API extraction.\n\n")
  } else {
    cat("\n✗ Screenshot capture needs troubleshooting.\n\n")
  }
  
  # Return test results
  invisible(list(
    test1 = result1,
    test2 = result2,
    test3 = result3,
    all_passed = tests_passed == 3
  ))
}

# =============================================================================
# USAGE EXAMPLES
# =============================================================================

# Example 1: Capture single hospital
if (FALSE) {
  result <- capture_hospital_screenshot(
    url = "https://www.sinaihealth.ca/about/leadership/"
  )
  
  if (result$success) {
    cat("Screenshot saved to:", result$output_file, "\n")
    shell.exec(result$output_file)  # Open to view
  }
}

# Example 2: Capture with custom settings
if (FALSE) {
  result <- capture_hospital_screenshot(
    url = "https://www.sinaihealth.ca/about/leadership/",
    output_file = "E:/ExecutiveSearchYaml/temp/sinai_test.png",
    delay = 8,
    vwidth = 1920,
    vheight = 1080,
    verbose = TRUE
  )
}

# Example 3: Batch capture
if (FALSE) {
  # Create test data frame
  test_hospitals <- data.frame(
    FAC = c("927", "966", "974"),
    name = c("Toronto Mount Sinai", "Sarnia Bluewater", "North Bay Regional"),
    url = c(
      "https://www.sinaihealth.ca/about/leadership/",
      "https://www.bluewaterhealth.ca/about/leadership",
      "https://www.nbrhc.on.ca/about-us/leadership-team"
    ),
    stringsAsFactors = FALSE
  )
  
  results <- batch_capture_screenshots(
    hospitals_df = test_hospitals,
    delay = 6,
    verbose = TRUE
  )
  
  print(results)
}

# Example 4: Run tests
if (FALSE) {
  test_results <- test_screenshot_capture()
}

# =============================================================================
# END OF SCRIPT
# =============================================================================

cat("\n✓ Screenshot capture function loaded successfully! (webshot2 version)\n")
cat("\nQuick Start:\n")
cat("  result <- capture_hospital_screenshot(url = 'https://...')\n")
cat("\nRun tests:\n")
cat("  test_screenshot_capture()\n\n")
