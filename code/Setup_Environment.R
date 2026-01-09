# ENVIRONMENT SETUP GUIDE
# Claude API Screenshot Extraction - Phase 0: Prototype
# Date: January 8, 2026
# Estimated Time: 2-3 hours
#

# =============================================================================
# STEP 1: INSTALL REQUIRED R PACKAGES (5-10 minutes)
# =============================================================================

cat("\n========================================\n")
cat("STEP 1: INSTALLING R PACKAGES\n")
cat("========================================\n\n")

# Check what's already installed
required_packages <- c("httr", "jsonlite", "yaml", "rvest", "dplyr", "chromote")
installed_packages <- installed.packages()[, "Package"]

cat("Checking installed packages...\n\n")

for (pkg in required_packages) {
  if (pkg %in% installed_packages) {
    cat(sprintf("✓ %s - already installed\n", pkg))
  } else {
    cat(sprintf("✗ %s - NEEDS INSTALLATION\n", pkg))
  }
}

cat("\n")

# Install missing packages
to_install <- setdiff(required_packages, installed_packages)

if (length(to_install) > 0) {
  cat("Installing missing packages:", paste(to_install, collapse = ", "), "\n\n")
  
  for (pkg in to_install) {
    cat(sprintf("Installing %s...\n", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    cat(sprintf("✓ %s installed\n\n", pkg))
  }
  
  cat("All packages installed successfully!\n\n")
} else {
  cat("All required packages already installed!\n\n")
}

# Load packages to verify
cat("Loading packages to verify installation...\n")
library(httr)
library(jsonlite)
library(yaml)
library(rvest)
library(dplyr)
library(chromote)

cat("✓ All packages loaded successfully!\n\n")

# =============================================================================
# STEP 2: VERIFY CHROME/CHROMIUM INSTALLATION (5 minutes)
# =============================================================================

cat("\n========================================\n")
cat("STEP 2: VERIFY CHROME BROWSER\n")
cat("========================================\n\n")

# chromote will find Chrome automatically, but let's verify
tryCatch({
  cat("Attempting to locate Chrome/Chromium...\n")
  
  # Create a temporary ChromoteSession to test
  test_browser <- chromote::ChromoteSession$new()
  
  cat("✓ Chrome/Chromium found and working!\n")
  cat("✓ Browser automation ready\n\n")
  
  # Close the test session
  test_browser$close()
  
}, error = function(e) {
  cat("\n✗ ERROR: Chrome/Chromium not found or not working\n")
  cat("Error message:", e$message, "\n\n")
  cat("TROUBLESHOOTING:\n")
  cat("1. Install Google Chrome from: https://www.google.com/chrome/\n")
  cat("2. OR install Chromium browser\n")
  cat("3. Restart R after installation\n")
  cat("4. Try running this script again\n\n")
})

# =============================================================================
# STEP 3: TEST SCREENSHOT CAPTURE (10-15 minutes)
# =============================================================================

cat("\n========================================\n")
cat("STEP 3: TEST SCREENSHOT CAPTURE\n")
cat("========================================\n\n")

# Create test screenshot function
test_screenshot_capture <- function(url = "https://www.example.com", 
                                    output_file = "E:/ExecutiveSearchYaml/temp/test_screenshot.png") {
  
  cat("Testing screenshot capture on:", url, "\n")
  
  # Ensure temp directory exists
  temp_dir <- dirname(output_file)
  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
    cat("Created temp directory:", temp_dir, "\n")
  }
  
  tryCatch({
    # Create browser session
    cat("1. Launching browser...\n")
    browser <- chromote::ChromoteSession$new()
    
    # Navigate to URL
    cat("2. Navigating to URL...\n")
    browser$Page$navigate(url)
    
    # Wait for page to load
    cat("3. Waiting for page load...\n")
    Sys.sleep(2)  # Simple wait - we'll make this smarter later
    
    # Take screenshot
    cat("4. Capturing screenshot...\n")
    screenshot <- browser$screenshot()
    
    # Save to file
    cat("5. Saving screenshot...\n")
    writeBin(screenshot, output_file)
    
    # Close browser
    cat("6. Closing browser...\n")
    browser$close()
    
    cat("\n✓ SUCCESS!\n")
    cat("Screenshot saved to:", output_file, "\n")
    cat("File size:", file.size(output_file), "bytes\n\n")
    
    return(TRUE)
    
  }, error = function(e) {
    cat("\n✗ ERROR during screenshot capture\n")
    cat("Error message:", e$message, "\n\n")
    return(FALSE)
  })
}

# Run the test
cat("Running screenshot test...\n\n")
screenshot_success <- test_screenshot_capture()

if (screenshot_success) {
  cat("Screenshot test completed successfully!\n")
  cat("You can view the screenshot at: E:/ExecutiveSearchYaml/temp/test_screenshot.png\n\n")
} else {
  cat("Screenshot test failed. Please review error messages above.\n\n")
}

# =============================================================================
# STEP 4: CLAUDE API CREDENTIAL SETUP (15-20 minutes)
# =============================================================================

cat("\n========================================\n")
cat("STEP 4: CLAUDE API SETUP\n")
cat("========================================\n\n")

cat("To use Claude API, you need:\n")
cat("1. An Anthropic API account\n")
cat("2. An API key\n")
cat("3. The API key stored securely in R\n\n")

cat("SETUP INSTRUCTIONS:\n")
cat("-------------------\n")
cat("1. Go to: https://console.anthropic.com/\n")
cat("2. Sign up or log in\n")
cat("3. Navigate to: API Keys section\n")
cat("4. Create a new API key\n")
cat("5. Copy the API key (starts with 'sk-ant-...')\n\n")

cat("STORING YOUR API KEY:\n")
cat("---------------------\n")
cat("For security, we'll store it in your R environment file.\n\n")

# Check if API key already exists
current_key <- Sys.getenv("ANTHROPIC_API_KEY")

if (current_key != "") {
  cat("✓ API key found in environment!\n")
  cat("Key preview:", substr(current_key, 1, 15), "...\n\n")
  cat("To update it, continue below. To keep it, skip this step.\n\n")
} else {
  cat("✗ No API key found in environment\n\n")
}

cat("Do you want to set up your API key now? (y/n): ")
setup_key <- readline()

if (tolower(trimws(setup_key)) == "y") {
  cat("\nEnter your Claude API key: ")
  api_key <- readline()
  
  # Add to .Renviron file
  renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
  
  # Read existing content
  if (file.exists(renviron_path)) {
    renviron_content <- readLines(renviron_path)
  } else {
    renviron_content <- character(0)
  }
  
  # Remove any existing ANTHROPIC_API_KEY line
  renviron_content <- renviron_content[!grepl("^ANTHROPIC_API_KEY=", renviron_content)]
  
  # Add new key
  renviron_content <- c(renviron_content, paste0("ANTHROPIC_API_KEY=", api_key))
  
  # Write back
  writeLines(renviron_content, renviron_path)
  
  cat("\n✓ API key saved to .Renviron\n")
  cat("✓ Restart R for changes to take effect\n\n")
  
  cat("IMPORTANT: After restarting R, run:\n")
  cat("  Sys.getenv('ANTHROPIC_API_KEY')\n")
  cat("to verify the key is loaded.\n\n")
  
} else {
  cat("\nSkipping API key setup.\n")
  cat("You can set it manually by adding this line to your .Renviron file:\n")
  cat("  ANTHROPIC_API_KEY=your_key_here\n\n")
}

# =============================================================================
# STEP 5: TEST CLAUDE API CONNECTION (10 minutes)
# =============================================================================

cat("\n========================================\n")
cat("STEP 5: TEST CLAUDE API CONNECTION\n")
cat("========================================\n\n")

# Simple API test function
test_claude_api <- function() {
  
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  
  if (api_key == "") {
    cat("✗ No API key found\n")
    cat("Please set ANTHROPIC_API_KEY environment variable\n")
    cat("Then restart R and try again.\n\n")
    return(FALSE)
  }
  
  cat("Testing Claude API connection...\n")
  
  tryCatch({
    # Simple text test
    response <- httr::POST(
      url = "https://api.anthropic.com/v1/messages",
      httr::add_headers(
        "x-api-key" = api_key,
        "anthropic-version" = "2023-06-01",
        "content-type" = "application/json"
      ),
      body = jsonlite::toJSON(list(
        model = "claude-sonnet-4-20250514",
        max_tokens = 100,
        messages = list(
          list(role = "user", content = "Reply with just the word 'SUCCESS' if you can read this.")
        )
      ), auto_unbox = TRUE),
      encode = "json"
    )
    
    if (httr::status_code(response) == 200) {
      result <- httr::content(response, "parsed")
      cat("\n✓ API CONNECTION SUCCESSFUL!\n")
      cat("Claude responded:", result$content[[1]]$text, "\n\n")
      return(TRUE)
    } else {
      cat("\n✗ API ERROR\n")
      cat("Status code:", httr::status_code(response), "\n")
      cat("Response:", httr::content(response, "text"), "\n\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("\n✗ CONNECTION ERROR\n")
    cat("Error:", e$message, "\n\n")
    return(FALSE)
  })
}

# Only test if API key is present
if (Sys.getenv("ANTHROPIC_API_KEY") != "") {
  cat("Running API connection test...\n\n")
  api_success <- test_claude_api()
  
  if (api_success) {
    cat("✓ Claude API is ready to use!\n\n")
  } else {
    cat("API test failed. Please check:\n")
    cat("1. API key is correct\n")
    cat("2. You have API credits available\n")
    cat("3. Internet connection is working\n\n")
  }
} else {
  cat("Skipping API test - no API key found.\n")
  cat("Set up your API key and restart R, then run:\n")
  cat("  test_claude_api()\n\n")
}

# =============================================================================
# SETUP SUMMARY
# =============================================================================

cat("\n========================================\n")
cat("ENVIRONMENT SETUP SUMMARY\n")
cat("========================================\n\n")

cat("Checklist:\n")
cat("[ ] 1. R packages installed (httr, jsonlite, yaml, rvest, dplyr, chromote)\n")
cat("[ ] 2. Chrome/Chromium browser installed and working\n")
cat("[ ] 3. Screenshot capture tested successfully\n")
cat("[ ] 4. Claude API key obtained and stored\n")
cat("[ ] 5. API connection tested successfully\n\n")

cat("Next Steps:\n")
cat("-----------\n")
cat("If all checks passed:\n")
cat("  → Ready to proceed to Step 3: Prototype Development\n\n")
cat("If any checks failed:\n")
cat("  → Review error messages above\n")
cat("  → Fix issues and re-run this script\n")
cat("  → Ask Claude for troubleshooting help\n\n")

cat("Files created:\n")
cat("  - E:/ExecutiveSearchYaml/temp/test_screenshot.png (test screenshot)\n")
cat("  - ~/.Renviron (API key storage, if configured)\n\n")

cat("========================================\n")
cat("SETUP COMPLETE!\n")
cat("========================================\n\n")