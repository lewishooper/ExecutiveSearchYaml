# Process Hospital Data - User Documentation

**Script**: `process_hospital_data.R`  
**Version**: 1.0  
**Date**: November 24, 2025  
**Purpose**: Post-processing pipeline for hospital executive data

---

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Quick Start Guide](#quick-start-guide)
4. [Module Descriptions](#module-descriptions)
5. [Function Reference](#function-reference)
6. [Output Files](#output-files)
7. [Configuration](#configuration)
8. [Troubleshooting](#troubleshooting)
9. [Examples](#examples)

---

## Overview

### What It Does

`process_hospital_data.R` transforms raw scraper output into clean, classified datasets suitable for analysis and reporting. It takes the output from `pattern_based_scraper.R` and:

1. **Normalizes** data (encoding, formatting, cleaning)
2. **Extracts** credentials from names (MD, PhD, RN, etc.)
3. **Classifies** people as Employees or Volunteers
4. **Flags** priority positions (CEOs and Board Chairs)
5. **Generates** two separate output files (Employees and Volunteers)

### When to Use It

Run this script **after** completing web scraping with `pattern_based_scraper.R`:

```
pattern_based_scraper.R  →  hospital_executives.csv
         ↓
process_hospital_data.R  →  Employees.csv + Volunteers.csv
```

**Typical schedule**: Monthly, on the 1st of each month after scraping

---

## System Requirements

### R Packages

```r
library(tidyverse)   # Data manipulation
library(lubridate)   # Date handling
library(stringr)     # String operations
library(yaml)        # Configuration files
library(stringi)     # Unicode handling
```

### File Dependencies

**Required Input Files:**
- Raw scraper output: `hospital_executives.csv`
- Configuration: `enhanced_hospitals.yaml`

**Output Directory:**
- Default: `E:/ExecutiveSearchYaml/processed/`
- Must have write permissions

---

## Quick Start Guide

### Basic Usage

```r
# Load the script
source("process_hospital_data.R")

# Run with defaults
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"
)

# Access output
employees <- result$employees
volunteers <- result$volunteers
```

### Common Use Cases

**1. Monthly Processing**

```r
# Process latest scraping results
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv",
  config_file = "enhanced_hospitals.yaml",
  output_folder = "E:/ExecutiveSearchYaml/processed",
  output_date = Sys.Date()
)
```

**2. Reprocess Historical Data**

```r
# Process old data with specific date
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives_2025-10-01.csv",
  output_date = as.Date("2025-10-01")
)
```

**3. Generate Validation Sample**

```r
# After processing, get sample for manual review
validation <- validate_classification(
  bind_rows(result$employees, result$volunteers),
  sample_size = 100
)

# Save for review
write_csv(validation, "validation_sample.csv")
```

---

## Module Descriptions

### Module 1: Data Normalization

**Function**: `normalize_raw_data()`

**Purpose**: Clean and standardize raw scraper output

**What It Does:**
- Standardizes field names (lowercase, underscores)
- Formats FAC numbers (3 digits with leading zeros)
- Handles missing values
- Normalizes UTF-8 encoding for French names
- Cleans HTML entities (&nbsp;, &amp;)
- Standardizes Unicode characters and apostrophes
- **Extracts credentials** from names (MD, PhD, RN, MBA, etc.)
- **Removes credentials** from person names
- Validates name/title lengths (flags if >50 or >100 characters)

**Credential Patterns Supported** (70+ patterns):
- **Medical**: MD, MBBS, DO, FRCPC, FRCSC, CCFP, MB, ChB, MRCP
- **Nursing**: RN, BScN, MScN, MN, NP, CNS, MHScN, MHSc, CCE
- **Academic**: PhD, Ph.D, DPhil, EdD, MSc, MBA, MA, MPA, MHA, MPH, BCom, BHSci
- **Professional**: CPA, CGA, CMA, CFA, CFP, CHE, FACHE, GSC, CET, ABC, FCCHL, FCMBES
- **Health Admin**: CHE, CHFP, CMPE, FACMPE
- **Allied Health**: OT, PT, PharmD, DDS, DMD, OD, AuD, RRT
- **Legal**: JD, LLB, LLM, QC, KC
- **Other**: PEng, P.Eng, PE, FRSC

**Output Columns Added:**
- `person_name` - Name with credentials removed
- `credentials` - Extracted credentials (comma-separated)
- `name_length_warning` - TRUE if name >50 characters
- `title_length_warning` - TRUE if title >100 characters

---

### Module 2: Employee/Volunteer Classification

**Function**: `classify_person_type()`

**Purpose**: Classify each person as Employee or Volunteer based on title

**Classification Logic:**

#### Volunteer Rules (checked FIRST)

A person is classified as **Volunteer** if their title matches:

1. **Board-related terms**: "Board", "Trustee", "Governor"
2. **Director alone**: Just "Director" with no other words
3. **Chair positions**:
   - "Board Chair", "Vice Chair", "First Vice Chair", "Second Vice Chair"
   - "Chair" by itself (standalone)
   - "Past Chair", "Past Board Chair"
   - Committee chairs: "Chair, [Committee Name] Committee"
4. **Treasurer** (in board context)
5. **Explicit volunteer**: Contains "volunteer"

#### Employee Override Patterns

These patterns **prevent** volunteer classification even if "board" appears:
- "President"
- "CEO" or "Chief Executive Officer"
- "Chief Executive"
- "Executive Director"
- "Executive Assistant"
- "Assistant to the CEO/President"

#### Medical/Operational Chair Exceptions

These chair positions are **Employees**, not volunteers:
- "Chair, Medical Advisory Committee"
- "Chair, Pharmacy and Therapeutics"
- "Chair, Department [of X]"

#### Default Classification

If no volunteer rules match → **Employee**

**Important**: Each person is classified as **EITHER** Employee **OR** Volunteer, never both.

---

### Module 3: Priority Flagging

**Function**: `is_priority_position()`

**Purpose**: Flag high-priority positions for special attention

**Priority Positions** (flagged TRUE):
1. **CEOs**: "Chief Executive Officer" or "CEO"
2. **Board Chairs**: "Board Chair", "Chairperson", "Chair of Board", or standalone "Chair"

**Exclusions**: 
- "Assistant" positions are never flagged (e.g., "Executive Assistant to the CEO")

**All other positions**: flagged FALSE

**Output**: `priority_flag` column (TRUE/FALSE)

**Usage:**
- Employees: Identifies CEO positions for executive tracking
- Volunteers: Identifies Board Chair positions for governance monitoring

---

### Module 4: Data Status Assignment

**Function**: `assign_data_status()`

**Purpose**: Categorize data collection outcome

**Status Codes:**

| Status | Meaning | Action Needed |
|--------|---------|---------------|
| `scraped` | Successfully collected | None - ready to use |
| `manual_entry` | Manually entered data | None - verified |
| `failed` | Scraping failed | Investigate and retry |
| `robotstxt_blocked` | Blocked by robots.txt | Respect blocking |
| `javascript_blocked` | Requires JavaScript | Consider alternative |
| `blocked` | General site blocking | Consider alternative |
| `partial_scrape` | Incomplete data | May need follow-up |

**Logic:**
1. Checks for error messages first
2. Checks robots.txt status
3. Checks if data actually found
4. Defaults to "scraped" if successful

---

### Module 5: Output Generation

**Function**: `generate_output_datasets()`

**Purpose**: Split data into Employee and Volunteer datasets

**Output Structure:**

Both files have identical column structure:

| Column | Description | Example |
|--------|-------------|---------|
| `hospital_name` | Hospital name | "Toronto General Hospital" |
| `fac_number` | FAC code (3 digits) | "948" |
| `hospital_type` | Hospital category | "Teaching Hospital" |
| `person_name` | Name (no credentials) | "Dr. Sarah Smith" |
| `credentials` | Extracted credentials | "MD, MBA" |
| `title` | Position title | "Chief Executive Officer" |
| `collection_date` | Date scraped | "2025-11-24" |
| `priority_flag` | Priority position? | TRUE/FALSE |
| `data_status` | Collection status | "scraped" |
| `source_url` | Hospital URL | "https://..." |
| `pattern_used` | Scraping pattern | "h2_name_p_title" |
| `notes` | Validation warnings | "name_length_warning" |

**File Naming:**
- Employees: `HospitalExecutives_Employees_YYYY-MM-DD.csv`
- Volunteers: `HospitalExecutives_Volunteers_YYYY-MM-DD.csv`

---

## Function Reference

### Main Function

```r
process_hospital_data(
  input_file,                    # Required: Path to raw scraper output
  config_file = "enhanced_hospitals.yaml",  # YAML configuration
  output_folder = "E:/ExecutiveSearchYaml/processed",  # Output directory
  output_date = Sys.Date()       # Date for file naming
)
```

**Returns**: List with three elements:
- `$employees` - Employee data frame
- `$volunteers` - Volunteer data frame
- `$files` - List of output file paths

### Helper Functions

#### `normalize_raw_data(raw_data, config)`
Cleans and standardizes input data

#### `classify_person_type(data, config)`
Classifies people as Employee or Volunteer

#### `is_volunteer(title, keywords = NULL)`
Checks if a title matches volunteer criteria

#### `is_priority_position(title)`
Checks if position should be flagged as priority

#### `assign_data_status(data)`
Assigns status codes based on collection outcome

#### `generate_output_datasets(data, output_date)`
Splits into Employee and Volunteer datasets

#### `save_datasets(datasets, output_folder, output_date)`
Writes CSV files to disk

#### `validate_classification(processed_data, sample_size = 100)`
Generates validation sample for manual review

### Credential Functions

#### `extract_credentials(name)`
Finds and extracts credentials from names

```r
# Example
extract_credentials("Dr. John Smith, MD, PhD")
# Returns: "MD, PhD"
```

#### `remove_credentials(name)`
Removes credentials, leaving clean name

```r
# Example
remove_credentials("Dr. John Smith, MD, PhD")
# Returns: "Dr. John Smith"
```

### Unicode Functions

#### `normalize_unicode(text)`
Standardizes Unicode characters and apostrophes

```r
# Example
normalize_unicode("Hôpital Montfort")  # Various Unicode forms
# Returns: Consistent UTF-8 representation
```

---

## Output Files

### File Locations

**Default Output Directory:**
```
E:/ExecutiveSearchYaml/processed/
```

**Generated Files:**
```
HospitalExecutives_Employees_2025-11-24.csv
HospitalExecutives_Volunteers_2025-11-24.csv
```

### File Format

- **Format**: CSV (comma-separated values)
- **Encoding**: UTF-8 (supports French accented characters)
- **Line endings**: Platform-specific
- **Header row**: Yes (column names in first row)

### Expected Volumes

Based on 119 configured hospitals:

| Dataset | Typical Count | Description |
|---------|---------------|-------------|
| Employees | 900-1,100 | Staff executives |
| Volunteers | 100-150 | Board members |
| **Total** | **1,000-1,250** | All people |

**Priority Breakdown:**
- CEO-level: ~15% of employees (130-165)
- Board Chairs: ~15-20% of volunteers (15-30)

---

## Configuration

### YAML Configuration File

The script reads `enhanced_hospitals.yaml` for:

1. **Hospital information**:
   - FAC number
   - Hospital name
   - Hospital type
   - Source URL
   - Pattern used

2. **Classification keywords** (optional):
   - Volunteer title patterns
   - Employee title patterns

### Customizing Credential Patterns

To add new credential patterns, edit lines 30-65 in `process_hospital_data.R`:

```r
CREDENTIAL_PATTERNS <- c(
  # Medical
  "MD", "MBBS", "DO", "FRCPC",
  # Add your new patterns here
  "YourNewCredential",
  # ...
)
```

### Adjusting Length Thresholds

Edit lines 25-26:

```r
MAX_NAME_LENGTH <- 50   # Characters
MAX_TITLE_LENGTH <- 100  # Characters
```

---

## Troubleshooting

### Common Issues

#### Issue: "File not found"

**Symptoms**: Error message about missing input file

**Solutions**:
1. Check file path is correct
2. Verify file exists in specified location
3. Check for typos in filename
4. Use absolute paths, not relative

```r
# Good
input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"

# May cause issues
input_file = "../output/hospital_executives.csv"
```

#### Issue: "Missing required columns"

**Symptoms**: Error about missing FAC, hospital_name, etc.

**Solutions**:
1. Verify input file is from pattern_based_scraper.R
2. Check column names match expected format
3. Don't manually edit the raw scraper output

**Required columns:**
- `FAC`
- `hospital_name`
- `executive_name`
- `executive_title`
- `date_gathered`

#### Issue: Unexpected classification results

**Symptoms**: Employees classified as volunteers or vice versa

**Solutions**:
1. Review the specific titles causing issues
2. Check classification rules in Module 2
3. Consider if hospital-specific overrides needed
4. Generate validation sample to identify patterns

```r
# Generate sample to review
validation <- validate_classification(
  bind_rows(result$employees, result$volunteers),
  sample_size = 100
)
View(validation)
```

#### Issue: Credentials not extracted

**Symptoms**: `credentials` column is empty for people with degrees

**Solutions**:
1. Check if credential format matches patterns
2. Verify credential is in CREDENTIAL_PATTERNS list
3. Add missing patterns if needed
4. Test extraction:

```r
extract_credentials("Dr. John Smith, MD, PhD")
# Should return: "MD, PhD"
```

#### Issue: Unicode/encoding problems

**Symptoms**: French names display incorrectly (Ã©, Ã , etc.)

**Solutions**:
1. Verify input file is UTF-8 encoded
2. Check console/viewer supports UTF-8
3. Review normalize_unicode() function
4. Test with specific names:

```r
normalize_unicode("Hôpital Montfort")
```

#### Issue: Priority flags incorrect

**Symptoms**: Non-CEOs flagged or CEOs not flagged

**Solutions**:
1. Check for "assistant" in title (excluded from priority)
2. Verify CEO/Board Chair title format matches patterns
3. Test specific title:

```r
is_priority_position("Chief Executive Officer")  # Should be TRUE
is_priority_position("Executive Assistant to the CEO")  # Should be FALSE
```

### Error Messages

#### "Missing required columns: X, Y, Z"

**Cause**: Input file doesn't have required columns

**Fix**: Use correct input file from pattern_based_scraper.R

#### "Cannot write to output folder"

**Cause**: No write permissions or folder doesn't exist

**Fix**: 
1. Create output folder
2. Check permissions
3. Try different folder

#### "YAML configuration not found"

**Cause**: enhanced_hospitals.yaml file missing

**Fix**: Ensure YAML file is in working directory or provide full path

---

## Examples

### Example 1: Basic Monthly Processing

```r
# Load script
source("process_hospital_data.R")

# Process current month
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"
)

# Check results
cat("Employees:", nrow(result$employees), "\n")
cat("Volunteers:", nrow(result$volunteers), "\n")
cat("Priority employees:", sum(result$employees$priority_flag), "\n")
cat("Priority volunteers:", sum(result$volunteers$priority_flag), "\n")
```

### Example 2: Generate Validation Sample

```r
# Process data
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"
)

# Combine both datasets
all_data <- bind_rows(result$employees, result$volunteers)

# Generate weighted sample (favors Teaching & Large hospitals)
validation_sample <- validate_classification(all_data, sample_size = 100)

# Save for manual review
write_csv(validation_sample, "validation_review_2025-11-24.csv")

# Review in Excel or RStudio
View(validation_sample)
```

### Example 3: Check Priority Flagging

```r
# Process data
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"
)

# Check employee priorities
employee_priorities <- result$employees %>%
  filter(priority_flag == TRUE) %>%
  select(hospital_name, person_name, title)

cat("Priority Employees:\n")
print(employee_priorities)

# Check volunteer priorities  
volunteer_priorities <- result$volunteers %>%
  filter(priority_flag == TRUE) %>%
  select(hospital_name, person_name, title)

cat("\nPriority Volunteers:\n")
print(volunteer_priorities)
```

### Example 4: Check Credential Extraction

```r
# Process data
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"
)

# Find people with credentials
with_credentials <- result$employees %>%
  filter(!is.na(credentials)) %>%
  select(person_name, credentials, title, hospital_name)

cat("Found", nrow(with_credentials), "employees with credentials\n")
View(with_credentials)

# Check specific credential types
md_count <- sum(grepl("MD", result$employees$credentials, ignore.case = TRUE), na.rm = TRUE)
phd_count <- sum(grepl("PhD", result$employees$credentials, ignore.case = TRUE), na.rm = TRUE)
rn_count <- sum(grepl("RN", result$employees$credentials, ignore.case = TRUE), na.rm = TRUE)

cat("MDs:", md_count, "\n")
cat("PhDs:", phd_count, "\n")
cat("RNs:", rn_count, "\n")
```

### Example 5: Review Data Status

```r
# Process data
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"
)

# Combine datasets
all_data <- bind_rows(result$employees, result$volunteers)

# Summarize status codes
status_summary <- all_data %>%
  count(data_status) %>%
  arrange(desc(n))

print(status_summary)

# Check specific status
blocked_hospitals <- all_data %>%
  filter(data_status == "robotstxt_blocked") %>%
  distinct(hospital_name, source_url)

cat("\nBlocked hospitals:", nrow(blocked_hospitals), "\n")
print(blocked_hospitals)
```

### Example 6: Historical Comparison

```r
# Process current month
current <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives_2025-11-01.csv",
  output_date = as.Date("2025-11-01")
)

# Process previous month
previous <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives_2025-10-01.csv",
  output_date = as.Date("2025-10-01")
)

# Compare counts
cat("November employees:", nrow(current$employees), "\n")
cat("October employees:", nrow(previous$employees), "\n")
cat("Change:", nrow(current$employees) - nrow(previous$employees), "\n")
```

---

## Best Practices

### 1. Run After Each Scraping Session

Process data immediately after scraping while issues are fresh:

```r
# Scrape
source("pattern_based_scraper.R")
# ... scraping code ...

# Process immediately
source("process_hospital_data.R")
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/hospital_executives.csv"
)
```

### 2. Always Generate Validation Samples

Review a sample after each processing run:

```r
validation <- validate_classification(
  bind_rows(result$employees, result$volunteers),
  sample_size = 100
)
write_csv(validation, paste0("validation_", Sys.Date(), ".csv"))
```

### 3. Archive Output Files

Keep dated copies for historical analysis:

```r
# Processed files are already dated
# But consider copying to archive folder
file.copy(
  result$files$employees_file,
  "E:/ExecutiveSearchYaml/archive/employees_2025-11-24.csv"
)
```

### 4. Document Unusual Classifications

Keep notes on edge cases for future reference:

```r
# Save problematic records for review
edge_cases <- result$employees %>%
  filter(title_length_warning | name_length_warning)

write_csv(edge_cases, "edge_cases_for_review.csv")
```

### 5. Test New Credential Patterns

Before adding to CREDENTIAL_PATTERNS, test extraction:

```r
# Test pattern
test_name <- "Dr. John Smith, YourNewCredential"
extract_credentials(test_name)
# Verify it extracts correctly
```

---

## Performance Notes

### Processing Speed

**Typical performance** (119 hospitals):
- Processing time: 5-15 seconds
- Depends on: Number of records, system specs

**Factors affecting speed**:
- Input file size
- Number of Unicode transformations needed
- Disk I/O speed

### Memory Usage

**Typical memory footprint**:
- ~50-100 MB for 1,000-1,500 records
- Scales linearly with record count

**Memory efficient**: Processes datasets up to 10,000+ records without issues

---

## Version History

### Version 1.0 (November 24, 2025)
- Initial release
- Supports 70+ credential patterns
- Employee/Volunteer classification
- Priority flagging for CEOs and Board Chairs
- Unicode normalization for French names
- Full validation and quality checks

---

## Support & Contact

### Getting Help

1. **Check this documentation** for common issues
2. **Review SESSION_LOG.md** for recent changes
3. **Generate validation sample** to identify patterns
4. **Test specific functions** in isolation

### Reporting Issues

When reporting issues, include:
- Error message (full text)
- Input file sample (first few rows)
- R version and package versions
- Expected vs actual behavior

---

## Appendix A: Column Descriptions

### Input Columns (from pattern_based_scraper.R)

| Column | Type | Description |
|--------|------|-------------|
| `FAC` | Character | Hospital facility code |
| `hospital_name` | Character | Hospital full name |
| `executive_name` | Character | Person's name (may include credentials) |
| `executive_title` | Character | Position title |
| `date_gathered` | Date | Scraping date |
| `url` | Character | Source URL |
| `pattern` | Character | Scraping pattern used |
| `robots_status` | Character | robots.txt status |
| `robots_message` | Character | robots.txt details |
| `error_message` | Character | Any error encountered |

### Output Columns (generated by process_hospital_data.R)

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `hospital_name` | Character | Hospital name | "Toronto General" |
| `fac_number` | Character | FAC (3 digits) | "948" |
| `hospital_type` | Character | Hospital category | "Teaching Hospital" |
| `person_name` | Character | Name without credentials | "Dr. Sarah Smith" |
| `credentials` | Character | Comma-separated credentials | "MD, MBA" |
| `title` | Character | Position title | "CEO" |
| `collection_date` | Date | When scraped | "2025-11-24" |
| `priority_flag` | Logical | Is priority position? | TRUE/FALSE |
| `data_status` | Character | Collection outcome | "scraped" |
| `source_url` | Character | Hospital URL | "https://..." |
| `pattern_used` | Character | Scraping pattern | "h2_name_p_title" |
| `notes` | Character | Validation warnings | "name_length_warning" |

---

## Appendix B: Classification Decision Tree

```
For each person:
│
├─ Check title for "assistant" → Employee (not priority)
│
├─ Check title for employee override patterns:
│  │  - "president", "CEO", "chief executive", etc.
│  └─ Yes → Employee
│
├─ Check for board terms:
│  │  - "board", "trustee", "governor"
│  └─ Yes → Volunteer
│
├─ Check if "Director" alone (no other words)
│  └─ Yes → Volunteer
│
├─ Check for chair patterns:
│  ├─ Medical/Operational chair → Employee
│  └─ Board chair patterns → Volunteer
│
├─ Check standalone "Chair" → Volunteer
│
├─ Check for "volunteer" in title → Volunteer
│
└─ Default → Employee
```

---

**End of Documentation**
