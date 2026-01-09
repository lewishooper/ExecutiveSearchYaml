# TROUBLESHOOTING GUIDE
# Claude API Screenshot Extraction - Environment Setup

## Common Issues and Solutions

### ISSUE 1: chromote package won't install
**Symptoms:**
- Error: "package 'chromote' is not available"
- Installation fails with compilation errors

**Solutions:**
A. Try installing from GitHub (development version):
```r
install.packages("remotes")
remotes::install_github("rstudio/chromote")
```

B. Alternative: Use RSelenium instead:
```r
install.packages("RSelenium")
# Note: Requires Java installation
```

C. Check R version:
```r
R.version.string  # Should be R 4.0 or higher
```

---

### ISSUE 2: Chrome/Chromium not found
**Symptoms:**
- Error: "Could not find Chrome/Chromium browser"
- chromote::ChromoteSession$new() fails

**Solutions:**
A. Install Google Chrome:
   - Download from: https://www.google.com/chrome/
   - Install normally
   - Restart R

B. Tell chromote where Chrome is located:
```r
# Windows common locations:
chrome_path <- "C:/Program Files/Google/Chrome/Application/chrome.exe"
# Or:
chrome_path <- "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"

# Set path
Sys.setenv(CHROMOTE_CHROME = chrome_path)

# Test
browser <- chromote::ChromoteSession$new()
browser$close()
```

C. Check if Chrome is in PATH:
```r
# Windows
system("where chrome", intern = TRUE)
```

---

### ISSUE 3: Screenshot capture fails
**Symptoms:**
- Browser opens but screenshot fails
- "Page not loaded" errors
- Blank screenshots

**Solutions:**
A. Increase wait time:
```r
browser$Page$navigate(url)
Sys.sleep(5)  # Increase from 2 to 5 seconds
screenshot <- browser$screenshot()
```

B. Wait for specific element:
```r
browser$Page$navigate(url)
# Wait for page load event
browser$Page$loadEventFired()
screenshot <- browser$screenshot()
```

C. Use viewport screenshot instead of fullpage:
```r
screenshot <- browser$screenshot(
  selector = "body",  # Capture body element
  cliprect = list(x = 0, y = 0, width = 1280, height = 1024)
)
```

---

### ISSUE 4: Claude API key not working
**Symptoms:**
- 401 Unauthorized error
- "Invalid API key" message
- API calls fail

**Solutions:**
A. Verify API key format:
```r
api_key <- Sys.getenv("ANTHROPIC_API_KEY")
cat("Key starts with:", substr(api_key, 1, 10), "\n")
# Should start with: sk-ant-api
```

B. Check .Renviron file:
```r
# Find your .Renviron location
file.path(Sys.getenv("HOME"), ".Renviron")

# Open and verify
file.edit(file.path(Sys.getenv("HOME"), ".Renviron"))
# Should contain line: ANTHROPIC_API_KEY=sk-ant-api...
```

C. Restart R session:
- Important! .Renviron is only read on R startup
- In RStudio: Session → Restart R
- Verify: `Sys.getenv("ANTHROPIC_API_KEY")`

D. Set temporarily for testing:
```r
Sys.setenv(ANTHROPIC_API_KEY = "your_key_here")
# Test API call
```

---

### ISSUE 5: API rate limits
**Symptoms:**
- 429 Too Many Requests error
- "Rate limit exceeded" message

**Solutions:**
A. Check your plan limits at: https://console.anthropic.com/

B. Add delays between API calls:
```r
Sys.sleep(1)  # Wait 1 second between calls
```

C. Implement exponential backoff:
```r
for (attempt in 1:3) {
  result <- try(call_api())
  if (!inherits(result, "try-error")) break
  Sys.sleep(2^attempt)  # 2, 4, 8 seconds
}
```

---

### ISSUE 6: Network/firewall issues
**Symptoms:**
- Connection timeouts
- "Could not resolve host" errors
- SSL/TLS errors

**Solutions:**
A. Test basic connectivity:
```r
# Test Chrome
chromote::ChromoteSession$new()$Page$navigate("https://www.google.com")

# Test API endpoint
httr::GET("https://api.anthropic.com/v1/messages")
```

B. Check firewall settings:
- Allow R.exe through Windows Firewall
- Allow chrome.exe through firewall
- Check corporate proxy settings

C. Configure proxy (if needed):
```r
httr::set_config(httr::use_proxy(
  url = "proxy.company.com",
  port = 8080
))
```

---

### ISSUE 7: Memory issues with large screenshots
**Symptoms:**
- R crashes during screenshot
- "Cannot allocate memory" errors

**Solutions:**
A. Reduce screenshot resolution:
```r
# Set viewport size before screenshot
browser$Browser$setWindowBounds(
  windowId = 1,
  bounds = list(width = 1280, height = 1024)
)
```

B. Clear memory between screenshots:
```r
screenshot <- browser$screenshot()
# Process screenshot
rm(screenshot)
gc()  # Force garbage collection
```

C. Process screenshots in batches:
```r
# Don't process all 20 hospitals at once
# Process 5 at a time, clean up between batches
```

---

### ISSUE 8: .Renviron file issues
**Symptoms:**
- API key not persisting
- File not found errors

**Solutions:**
A. Create .Renviron manually:
```r
# Create file
file.create(file.path(Sys.getenv("HOME"), ".Renviron"))

# Open in editor
file.edit(file.path(Sys.getenv("HOME"), ".Renviron"))

# Add line:
# ANTHROPIC_API_KEY=your_key_here

# Save and restart R
```

B. Check HOME directory:
```r
Sys.getenv("HOME")
# Should point to your user directory
# Windows: C:/Users/YourName
```

C. Alternative: Use .Rprofile instead:
```r
# Edit .Rprofile
file.edit(file.path(Sys.getenv("HOME"), ".Rprofile"))

# Add line:
# Sys.setenv(ANTHROPIC_API_KEY = "your_key_here")

# Save and restart R
```

---

## Testing Commands

Quick commands to verify each component:

```r
# 1. Check package installation
"chromote" %in% installed.packages()[, "Package"]

# 2. Test browser
browser <- chromote::ChromoteSession$new()
browser$close()

# 3. Check API key
Sys.getenv("ANTHROPIC_API_KEY")

# 4. Test API connection
httr::POST(
  "https://api.anthropic.com/v1/messages",
  httr::add_headers(
    "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
    "anthropic-version" = "2023-06-01"
  )
)

# 5. Full screenshot test
source("E:/ExecutiveSearchYaml/code/setup_environment.R")
```

---

## Getting Help

If issues persist:

1. **Gather diagnostic info:**
```r
# System info
Sys.info()

# R version
R.version.string

# Package versions
packageVersion("chromote")
packageVersion("httr")

# Chrome location
Sys.which("chrome")
```

2. **Check logs:**
- RStudio: View → Show Console Output
- Look for error messages with stack traces

3. **Ask Claude with:**
- Exact error message
- Code that caused the error
- System info from above
- What you've already tried

---

## Quick Start After Setup

Once environment is working:

```r
# Test the full pipeline on one hospital
source("E:/ExecutiveSearchYaml/code/prototype_screenshot_extraction.R")

# Run on single test hospital
result <- extract_executives_screenshot(
  fac = "927",
  name = "Toronto Mount Sinai",
  url = "https://www.sinaihealth.ca/about/leadership/"
)

print(result)
```

---

**Last Updated:** January 8, 2026  
**For:** Phase 0 - Prototype Development
