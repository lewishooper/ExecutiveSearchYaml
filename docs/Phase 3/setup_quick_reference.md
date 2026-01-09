# QUICK REFERENCE CARD
# Claude API Screenshot Extraction - Environment Setup

## One-Command Setup

```r
source("E:/ExecutiveSearchYaml/code/setup_environment.R")
```

This will:
1. ✓ Install required packages
2. ✓ Test Chrome browser
3. ✓ Test screenshot capture
4. ✓ Guide API key setup
5. ✓ Test API connection

---

## Manual Setup Steps

### 1. Install Packages (2 minutes)
```r
install.packages(c("httr", "jsonlite", "yaml", "rvest", "dplyr", "chromote"))
```

### 2. Test Browser (1 minute)
```r
library(chromote)
browser <- ChromoteSession$new()
browser$close()
```

### 3. Get API Key (10 minutes)
1. Go to: https://console.anthropic.com/
2. Create account / Sign in
3. Navigate to: API Keys
4. Create new key (starts with `sk-ant-api...`)
5. Copy key

### 4. Store API Key (2 minutes)
```r
# Edit .Renviron file
file.edit(file.path(Sys.getenv("HOME"), ".Renviron"))

# Add this line:
ANTHROPIC_API_KEY=sk-ant-api-your-key-here

# Save, close, restart R
```

### 5. Verify Setup (1 minute)
```r
# Check API key loaded
Sys.getenv("ANTHROPIC_API_KEY")

# Test API
httr::POST(
  "https://api.anthropic.com/v1/messages",
  httr::add_headers(
    "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
    "anthropic-version" = "2023-06-01",
    "content-type" = "application/json"
  ),
  body = '{"model":"claude-sonnet-4-20250514","max_tokens":100,"messages":[{"role":"user","content":"Say OK"}]}',
  encode = "raw"
)
```

---

## Package Versions

**Required:**
- R >= 4.0
- chromote >= 0.2.0
- httr >= 1.4.0
- jsonlite >= 1.8.0

**Check versions:**
```r
packageVersion("chromote")
```

---

## Common Commands

### Screenshot Capture
```r
library(chromote)

# Start browser
browser <- ChromoteSession$new()

# Navigate
browser$Page$navigate("https://example.com")
Sys.sleep(2)

# Capture
screenshot <- browser$screenshot()

# Save
writeBin(screenshot, "output.png")

# Close
browser$close()
```

### API Call (Text)
```r
library(httr)
library(jsonlite)

response <- POST(
  "https://api.anthropic.com/v1/messages",
  add_headers(
    "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
    "anthropic-version" = "2023-06-01",
    "content-type" = "application/json"
  ),
  body = toJSON(list(
    model = "claude-sonnet-4-20250514",
    max_tokens = 1000,
    messages = list(
      list(role = "user", content = "Your prompt here")
    )
  ), auto_unbox = TRUE)
)

result <- content(response, "parsed")
cat(result$content[[1]]$text)
```

### API Call (Image)
```r
library(base64enc)

# Read screenshot
img_data <- readBin("screenshot.png", "raw", file.size("screenshot.png"))

# Encode to base64
img_base64 <- base64encode(img_data)

# API call with image
response <- POST(
  "https://api.anthropic.com/v1/messages",
  add_headers(
    "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
    "anthropic-version" = "2023-06-01",
    "content-type" = "application/json"
  ),
  body = toJSON(list(
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
              media_type = "image/png",
              data = img_base64
            )
          ),
          list(
            type = "text",
            text = "Extract executives from this image"
          )
        )
      )
    )
  ), auto_unbox = TRUE)
)
```

---

## File Locations

**Setup Script:**
`E:/ExecutiveSearchYaml/code/setup_environment.R`

**Troubleshooting Guide:**
`E:/ExecutiveSearchYaml/docs/setup_troubleshooting.md`

**Test Screenshot:**
`E:/ExecutiveSearchYaml/temp/test_screenshot.png`

**API Key Storage:**
`~/.Renviron` (Windows: `C:/Users/YourName/.Renviron`)

---

## Troubleshooting Quick Fixes

**Browser won't start:**
```r
Sys.setenv(CHROMOTE_CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe")
```

**API key not found:**
```r
# Restart R, then:
Sys.getenv("ANTHROPIC_API_KEY")

# If empty, set temporarily:
Sys.setenv(ANTHROPIC_API_KEY = "your-key")
```

**Package install fails:**
```r
# Try different mirror
install.packages("chromote", repos = "https://cloud.r-project.org/")

# Or from GitHub
remotes::install_github("rstudio/chromote")
```

---

## Next Steps After Setup

**Phase 0 - Prototype (Week 1-2):**
1. ✓ Environment setup complete
2. → Develop screenshot capture function
3. → Develop API extraction function
4. → Test on FAC-927 (Toronto Mount Sinai)
5. → Validate results

**Ready to proceed?**
Run: `source("E:/ExecutiveSearchYaml/code/prototype_screenshot_extraction.R")`

---

## Support Resources

**Anthropic Console:**
https://console.anthropic.com/

**Claude API Docs:**
https://docs.anthropic.com/

**chromote Documentation:**
https://github.com/rstudio/chromote

**Project Discussion Paper:**
`E:/ExecutiveSearchYaml/docs/Claude_API_Screenshot_Extraction_Discussion.md`

---

**Setup Time:** ~30-45 minutes (with API account creation)  
**Last Updated:** January 8, 2026
