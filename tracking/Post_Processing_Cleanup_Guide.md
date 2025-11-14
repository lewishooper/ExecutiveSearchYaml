# Post-Processing Cleanup Guide for Hospital Executive Scraping
## Note November 14, 2025
We may wish to rethink how we deal with exectuive titles here. 
For small hospitals Directors and managers who are on the leadership page may need to be left there.
The hospital has decided to include them as "leaders"  on their leadership page. They are paid leadership??
Board members/board directors could be trimmed off in post processing as they are "volunteers"
The issue of Executive assistants ?? not sure about 
Clean up may be divided into two purpose categories.  
1) for purposes of a paper on turn over
2) for b2b   who would be interested
## Purpose
This document provides systematic guidance for cleaning scraped executive data to remove non-executive personnel captured during the scraping process. The goal is to minimize manual post-processing work for monthly/quarterly monitoring runs.

## Overview
The scraping process intentionally casts a wide net to avoid missing legitimate executives. As a result, certain categories of personnel are regularly captured and need to be filtered out in post-processing.

---

## Cleanup Categories

### 1. Board Members

**Description:** Board of Directors members who are not part of the executive management team.

**Common Titles to Remove:**
- Chair / Chairperson / Board Chair
- Vice Chair / Vice-Chair
- Treasurer / Board Treasurer  
- Secretary / Board Secretary
- Director (when clearly board-related)
- Board Member
- Trustee / Board Trustee
- President (when it's a board position, not CEO)

**Regex Pattern:**
```regex
^(Board\s+)?(Chair(person)?|Vice[\s-]Chair|Treasurer|Secretary|Director|Member|Trustee|President\s+of\s+(the\s+)?Board)$
```

**Advanced Pattern (includes compound titles):**
```regex
(Board\s+(Chair|Vice[\s-]Chair|Treasurer|Secretary|Member|Director|Trustee))|((Chair|Treasurer|Secretary)\s+of\s+(the\s+)?Board)|(President\s+of\s+.+\s+(Board|Services))
```

**Examples from Scraped Data:**
- FAC 592 (Napanee): "Chair", "Vice Chair", "Treasurer", "Secretary/President & CEO"
  - Keep: "Secretary/President & CEO" (dual role with executive function)
  - Remove: "Chair", "Vice Chair", "Treasurer" when standalone
- FAC 592: "President of Volunteer Services" - Remove (board/volunteer role)

**Special Cases:**
- **"Secretary/President & CEO"** - KEEP (executive function)
- **"President of [Department]"** - Context dependent; review if unclear

---

### 2. Executive Assistants

**Description:** Administrative support staff to executives, not executives themselves.

**Common Titles to Remove:**
- Executive Assistant
- Administrative Assistant  
- Executive Assistant to [Title]
- Administrative Assistant to [Title]
- Assistant to the CEO/President/VP

**Regex Pattern:**
```regex
(Executive|Administrative)\s+Assistant(\s+(to|&))?
```

**Examples from Scraped Data:**
- FAC 968 (Huntsville): "Executive Assistant - Tammy Tkachuk" embedded in CEO's entry
- FAC 955 (Grey Bruce): "Loni Zuppinger, Executive Assistant & Board Liaison"
- FAC 955: "Marta Monck, Administrative Assistant to VP Medical Affairs, Chief of Medical Staff"

**Special Cases:**
- May appear as separate entries or embedded within executive entries
- Often includes names that need to be stripped from executive title fields

---

### 3. Managers

**Description:** Mid-level management positions below the executive level.

**Titles to Remove:**
- Manager (without VP/Chief/Director prefix)
- Senior Manager
- Department Manager
- [Department] Manager

**Titles to KEEP:**
- General Manager (often executive level)
- Chief [anything] (C-suite)
- VP [anything] (executive level)
- Director when combined with executive functions

**Regex Pattern (to REMOVE):**
```regex
^(Senior\s+)?Manager(\s+of|\s+,)?\s+(?!General)
```

**Regex Pattern (to KEEP):**
```regex
(General\s+Manager)|(Chief\s+)|(VP\s+)|(Vice\s+President)
```

**Examples:**
- Remove: "Manager, Operations", "Senior Manager, Finance", "Department Manager"
- Keep: "General Manager", "Chief Operating Officer", "VP, Corporate Services"

**Special Cases:**
- "Manager" appearing in complex multi-part titles may need manual review
- Regional/Site Managers are typically not executives

---

### 4. Medical Department Heads

**Description:** Department-specific medical chiefs who are not part of the executive leadership team.

**Common Titles to Remove:**
- Chief, [Medical Department]
- Director & Chief, [Medical Department]  
- Chief of [Specialty Service]
- President of Medical Staff (often ex-officio, not executive)
- Department heads for specific clinical services

**Titles to KEEP:**
- Chief of Staff (hospital-wide medical leader)
- Chief Medical Officer (CMO)
- Vice President of Medical Affairs / VP Medical Affairs
- Chief Nursing Officer / Chief Nursing Executive (CNO/CNE)
- Any chief role with "Vice President" in title

**Regex Pattern (to REMOVE):**
```regex
(Director\s+(&|and)\s+)?Chief(,\s+|\s+of\s+)(Surgery|Emergency|Obstetrics|Family\s+Medicine|Internal\s+Medicine|Diagnostic\s+Imaging|Laboratory|Radiology|Pathology|Anesthesia|Pediatrics|Psychiatry)
```

**Pattern for Medical Staff Officers (context dependent):**
```regex
(President|Vice\s+President|Secretary)\s+of\s+Medical\s+Staff
```

**Examples from Scraped Data:**
- FAC 968 (Huntsville) - REMOVE these department chiefs:
  - Dr. Kirsten Jewell, "Interim Director & Chief, Emergency Medicine"
  - Dr. Hector Roldan, "Chief, Surgery"  
  - Dr. Sheena Branigan, "Director & Chief, Obstetrics"
  - Dr. Cole Krensky, "Chief, Family Medicine, SMMH"
  - Dr. Melanie Mar, "Chief, Family Medicine, HDMH"
  - Dr. Jason Blaichman, "Director & Chief, Diagnostic Imaging"
  - Dr. Khal Salem, "Chief, Internal Medicine"
  - Dr. David Johnstone, "Chair, Pharmacy & Therapeutics"
  - Dr. Nick Biasutti, "Chief Medical Information Officer" (borderline - may keep)
  - Dr. John Penswick, "Director, Laboratory Medicine"

- FAC 968 (Huntsville) - KEEP these executive medical leaders:
  - Dr. Khaled Abdel-Razek, "Chief of Staff" (hospital-wide)
  
- FAC 968 - Medical Staff Officers (REVIEW/LIKELY REMOVE):
  - Dr. Helen Dempster, "President" (of Medical Staff)
  - Dr. Rohit Gupta, "Vice President/Secretary" (of Medical Staff)

**Special Cases:**
- "Chief Medical Information Officer" - Borderline case; often C-suite, review context
- "Chief Medical Officer" vs "Chief of Medical Staff" - Both typically executive level, KEEP
- Medical Staff President/VP - Usually ex-officio board members, not executives - REMOVE

---

## Special Cleanup Issues

### Issue: Contaminated Title Fields

**Problem:** Title fields may contain information about other people (assistants, contact info) embedded in the same HTML element.

**Examples:**
- FAC 955: Dr. Cornelius Van Zyl
  - Scraped title: "Chief of Medical Staff |BR| Marta Monck, Administrative Assistant to VP Medical Affairs, Chief of Medical Staff |BR| (519) 376-2121 Ext. 2807"
  - Clean title: "Chief of Medical Staff"

**Cleanup Pattern:**
```regex
# Remove everything after |BR| marker
^([^|]+)(\|BR\|.*)$
# Keep only: $1

# Remove phone numbers
\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}(\s+Ext\.?\s+\d+)?

# Remove "Email [Name]" prefixes from names
^Email\s+(.+)$
# Keep only: $1
```

**Implementation Note:**
- Strip phone numbers and extensions from title fields
- Remove text after |BR| markers in titles
- Remove "Email " prefix from names (FAC 968)

---

## Recommended Post-Processing Workflow

### Step 1: Automated Filtering
Apply regex patterns to automatically remove:
1. Board members (high confidence patterns)
2. Executive/Administrative Assistants
3. Managers (excluding General Manager)
4. Department-specific medical chiefs

### Step 2: Title Field Cleanup
1. Strip phone numbers and extensions
2. Remove text after |BR| markers
3. Remove "Email " prefixes from names
4. Trim whitespace

### Step 3: Manual Review (Minimal)
Review these edge cases:
- Medical Staff Presidents/VPs (usually remove)
- Secretary/President dual roles (usually keep)
- Chief Medical Information Officer (context dependent)
- Any "Director" titles (some are executive, some are department level)
- Complex multi-part titles

### Step 4: Validation
- Check that expected_executives count is reasonable after cleanup
- Flag hospitals where actual count differs significantly from expected
- Review any titles containing both executive and non-executive keywords

---

## R Implementation Skeleton

```r
# Post-processing cleanup function
clean_executive_data <- function(exec_df) {
  
  # 1. Remove board members
  board_pattern <- "(Board\\s+)?(Chair(person)?|Vice[\\s-]Chair|Treasurer|Secretary(?!.*CEO)|Board\\s+Member|Trustee)"
  exec_df <- exec_df %>%
    filter(!grepl(board_pattern, title, ignore.case = TRUE) | 
           grepl("CEO|President.*CEO", title, ignore.case = TRUE))
  
  # 2. Remove executive assistants
  assistant_pattern <- "(Executive|Administrative)\\s+Assistant"
  exec_df <- exec_df %>%
    filter(!grepl(assistant_pattern, title, ignore.case = TRUE))
  
  # 3. Remove non-executive managers
  manager_pattern <- "^(Senior\\s+)?Manager(?!.*General)"
  exec_df <- exec_df %>%
    filter(!grepl(manager_pattern, title, ignore.case = TRUE))
  
  # 4. Remove medical department heads
  dept_chief_pattern <- "Chief(,\\s+|\\s+of\\s+)(Surgery|Emergency|Obstetrics|Family\\s+Medicine|Internal\\s+Medicine|Diagnostic|Laboratory|Radiology)"
  exec_df <- exec_df %>%
    filter(!grepl(dept_chief_pattern, title, ignore.case = TRUE))
  
  # 5. Clean title fields
  exec_df <- exec_df %>%
    mutate(
      # Remove content after |BR| markers
      title = gsub("\\|BR\\|.*$", "", title),
      # Remove phone numbers
      title = gsub("\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}(\\s+Ext\\.?\\s+\\d+)?", "", title),
      # Remove "Email " prefix from names
      name = gsub("^Email\\s+", "", name),
      # Trim whitespace
      title = trimws(title),
      name = trimws(name)
    )
  
  return(exec_df)
}
```

---

## Notes for Future Enhancements

1. **Learning from patterns:** As more hospitals are processed, update regex patterns based on new examples
2. **Hospital-specific overrides:** Some hospitals may need custom cleanup rules in YAML
3. **Confidence scoring:** Consider adding confidence scores to identify records needing manual review
4. **Change detection:** For quarterly runs, flag new executives or title changes for validation
5. **Board member detection:** May want to keep board members in a separate dataset for governance analysis

---

## Document History
- Created: November 2025
- Based on: FAC 592 (Napanee), FAC 968 (Huntsville), FAC 955 (Grey Bruce)
- Purpose: Minimize manual post-processing for quarterly executive monitoring runs
