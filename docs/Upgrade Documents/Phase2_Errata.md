# Phase 2 Documentation - Errata & Corrections

## Document Formatting Issues

### Issue 1: "Run:" Instruction Treated as Code

**Location:** Phase2_Quick_Start_Guide.md - Step 6 and Step 7

**Problem:**
The documentation shows:
```r
Run:
source("validate_yaml.R")
```

If you copy-paste this directly into R, you'll get:
```
Error in eval(ei, envir) : object 'Run' not found
```

**Explanation:**
"Run:" is meant as an **instruction to the reader**, not R code. When pasted into R, it tries to interpret `Run` as a variable.

**Correct Usage:**
Just run the actual R code without "Run:":
```r
source("validate_yaml.R")
```

**Other Similar Instances in Documentation:**

All of these are instructions, not code - only execute the line(s) after them:

1. **Step 6:**
   ```
   Run:  source("test_phase2_single.R")
   ```
   Should be:
   ```r
   source("test_phase2_single.R")
   ```

2. **Step 7:**
   ```
   Run:  source("validate_yaml.R")
   ```
   Should be:
   ```r
   source("validate_yaml.R")
   ```

3. **Step 10:**
   ```
   Run:  [full test code]
   ```
   Should be: Just run the code block below it

---

## General Documentation Conventions

### Code Blocks

**Documentation Intent vs. Executable Code:**

❌ **Don't copy these parts (they're instructions):**
```
Run:
Run this:
Execute:
In Terminal:
In R Console:
Expected output:
```

✅ **Do copy these parts (they're actual code):**
```r
# Anything that looks like valid R or bash code
source("file.R")
git commit -m "message"
```

### How to Identify Instructions vs Code

**Instructions (don't run):**
- Starts with "Run:", "Execute:", "Type:", "Enter:"
- Contains explanatory text in plain English
- Describes what to do, not what to execute

**Code (do run):**
- Formatted in code block (gray background in markdown)
- Starts with valid R/bash syntax
- Contains actual commands like `source()`, `git`, etc.

---

## Corrected Step 6 (Test with One Hospital)

Create test script: `test_phase2_single.R`

```r
# Test Phase 2 changes with a single hospital
library(rvest)
library(dplyr)
library(stringr)
library(yaml)

# Load the updated scraper
source("pattern_based_scraper.R")
scraper <- PatternBasedScraper()

# Load config
config <- scraper$load_config("enhanced_hospitals.yaml")

# Test with FAC 969 (Ontario Shores - has known issue)
hospital_969 <- config$hospitals[[which(sapply(config$hospitals, function(h) h$FAC == "969"))]]

cat("\n=== TESTING FAC 969 - Ontario Shores ===\n")
cat("Expected issue: Daniel Mueller title not recognized\n")
cat("Expected solution: Hospital override with additional keywords\n\n")

result <- scraper$scrape_hospital(hospital_969)

cat("\n=== RESULTS ===\n")
print(result)

cat("\n=== CHECKING FOR OVERRIDES ===\n")
fac_key <- "FAC_969"
if (!is.null(config$hospital_overrides[[fac_key]])) {
  cat("Overrides found for FAC 969:\n")
  print(config$hospital_overrides[[fac_key]])
} else {
  cat("No overrides found for FAC 969\n")
}
```

**To execute this script, run:**
```r
source("test_phase2_single.R")
```

---

## Corrected Step 7 (Validate YAML Loading)

Create validation script: `validate_yaml.R`

```r
# Validate Phase 2 YAML additions
library(yaml)

cat("=== VALIDATING YAML STRUCTURE ===\n\n")

# Try to load config
tryCatch({
  config <- yaml::read_yaml("enhanced_hospitals.yaml")
  cat("✓ YAML loads successfully\n\n")
  
  # Check for new sections
  if (!is.null(config$recognition_config)) {
    cat("✓ recognition_config section found\n")
    
    # Check title_keywords
    if (!is.null(config$recognition_config$title_keywords)) {
      cat("  ✓ title_keywords found\n")
      cat("    - Primary keywords:", 
          length(config$recognition_config$title_keywords$primary), "\n")
      cat("    - Secondary keywords:", 
          length(config$recognition_config$title_keywords$secondary), "\n")
      cat("    - Medical keywords:", 
          length(config$recognition_config$title_keywords$medical_specific), "\n")
    } else {
      cat("  ✗ title_keywords MISSING\n")
    }
    
    # Check exclusions
    if (!is.null(config$recognition_config$name_exclusions)) {
      cat("  ✓ name_exclusions found:", 
          length(config$recognition_config$name_exclusions), "patterns\n")
    } else {
      cat("  ✗ name_exclusions MISSING\n")
    }
    
    if (!is.null(config$recognition_config$title_exclusions)) {
      cat("  ✓ title_exclusions found:", 
          length(config$recognition_config$title_exclusions), "patterns\n")
    } else {
      cat("  ✗ title_exclusions MISSING\n")
    }
  } else {
    cat("✗ recognition_config section MISSING\n")
  }
  
  # Check hospital_overrides
  if (!is.null(config$hospital_overrides)) {
    cat("\n✓ hospital_overrides section found\n")
    cat("  Overrides configured for", length(config$hospital_overrides), "hospitals\n")
    cat("  Hospitals with overrides:", 
        paste(names(config$hospital_overrides), collapse=", "), "\n")
  } else {
    cat("\n✗ hospital_overrides section MISSING\n")
  }
  
  cat("\n=== VALIDATION COMPLETE ===\n")
  
}, error = function(e) {
  cat("✗ ERROR loading YAML:\n")
  cat(e$message, "\n")
  cat("\nCheck YAML syntax and indentation\n")
})
```

**To execute this script, run:**
```r
source("validate_yaml.R")
```

---

## Other Minor Corrections

### Issue 2: Missing Comma in Example Code

**Location:** Phase2_Quick_Start_Guide.md - hospital_overrides example

**Original:**
```yaml
FAC_969:
  additional_title_keywords:
    - "Physician-in-Chief"
    - "Research Chair"
  notes: "Complex multi-part title with 'and' connector"
```

**Should include (optional but clearer):**
```yaml
FAC_969:
  additional_title_keywords:
    - "Physician-in-Chief"
    - "Research Chair"
  notes: "Complex multi-part title with 'and' connector"
```

This is actually correct as-is. No change needed.

---

### Issue 3: File Path Consistency

Throughout documentation, file paths are shown as:
- `E:/ExecutiveSearchYaml/code2/`

If your actual path is different, adjust accordingly in all commands. For example:
- Your path might be: `C:/Users/YourName/Documents/ExecutiveSearchYaml/code2/`
- Or: `~/Documents/ExecutiveSearchYaml/code2/` on Mac/Linux

---

## Quick Reference: How to Use the Documentation

### When You See Code in Documentation:

**Skip these (instructions only):**
```
Step 1:
Run:
Execute:
Type:
Expected output:
```

**Copy and run these:**
```r
source("script.R")
config <- read_yaml("file.yaml")
```

```bash
git commit -m "message"
cd /path/to/folder
```

### Example from Documentation:

```
Step 6: Test with One Hospital

Create test script: test_phase2_single.R

[CODE BLOCK - Copy this]

Run:                           ← DON'T COPY THIS LINE
source("test_phase2_single.R") ← COPY AND RUN THIS LINE
```

Should be executed as:
```r
source("test_phase2_single.R")
```

---

## Testing Your Understanding

**Which of these should you execute?**

1. `Run: git status`
   - ❌ No - "Run:" is instruction
   - ✅ Execute: `git status`

2. `source("validate_yaml.R")`
   - ✅ Yes - This is actual code

3. `Expected output: YAML loads successfully`
   - ❌ No - This describes what you should see

4. `# Load config`
   - ✅ Yes, but it's just a comment (won't do anything)

5. `config <- read_yaml("file.yaml")`
   - ✅ Yes - This is actual code

---

## Still Confused?

**Simple rule:** 
If it looks like valid R or bash code (with proper syntax), run it.
If it's plain English explanation, it's just instruction.

**When in doubt:**
- Try running it in R
- If you get "object not found" or "unexpected symbol", it was probably an instruction, not code
- Look for the actual code in the block below the instruction

---

## Summary

**The Issue:**
Documentation used "Run:" as a reader instruction, which should not be copied into R.

**The Fix:**
Only execute the actual code lines, not the instructional text.

**Current Status:**
✅ You already figured this out correctly by running just `source("validate_yaml.R")`

**Going Forward:**
Skip any plain English instructions like "Run:", "Execute:", "Type:", etc. and only run the actual code.

---

## Questions?

If you encounter any other similar issues:
1. Check if it's an instruction (plain English) vs. code (R syntax)
2. Try running just the code part without instruction words
3. Reference this errata document

---

**Thank you for catching this!** Your careful attention to detail is exactly what makes Phase 2 successful. 🎯

---

*Errata Version: 1.0*
*Date: November 6, 2025*
*Reported by: User during Phase 2 implementation*
