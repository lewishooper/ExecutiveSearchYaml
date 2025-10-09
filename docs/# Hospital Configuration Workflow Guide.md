# Hospital Configuration Workflow Guide
**Step-by-Step Guide for Adding New Hospitals to the Executive Search System**

---

## Table of Contents
1. [Quick Start Checklist](#quick-start-checklist)
2. [Detailed Workflow](#detailed-workflow)
3. [Pattern Selection Guide](#pattern-selection-guide)
4. [Troubleshooting Common Issues](#troubleshooting-common-issues)
5. [Quality Control](#quality-control)

---

## Quick Start Checklist

Before you begin, ensure you have:
- [ ] Hospital FAC number
- [ ] Hospital name
- [ ] Leadership page URL
- [ ] R/RStudio environment set up
- [ ] All scripts loaded (`pattern_based_scraper.R`, `hospital_configuration_helper.R`, etc.)

---

## Detailed Workflow

### Step 1: Gather Hospital Information

**What You Need:**
- **FAC Number**: 3-digit facility code (e.g., 777)
- **Hospital Name**: Official name from master list
- **Leadership URL**: Direct link to executive/leadership team page
- **Expected Count**: Approximate number of executives (optional but helpful)

**Example:**
```
FAC: 777
Name: Queensway Carleton Hospital
URL: https://www.qch.on.ca/Leadership
Expected: 9 executives
```

---

### Step 2: Inspect the HTML Structure

#### 2A. Manual Browser Inspection

1. **Open the leadership page** in your browser
2. **Right-click on an executive's name** → Select "Inspect" or "Inspect Element"
3. **Look at the HTML structure** in the developer tools

**What to look for:**
- What HTML tag contains the name? (`<h2>`, `<p>`, `<div>`, `<strong>`, etc.)
- What HTML tag contains the title? 
- Are they in the same element or different elements?
- Are there CSS classes? (e.g., `class="staff-name"`)
- Is it a table structure?
- Is it a list (`<ul>` or `<ol>`)?

**Take notes on:**
```
Names are in: <h2> tags
Titles are in: <h3> tags
Pattern: Sequential different elements
```

#### 2B. Automated Analysis

Use the helper tool to analyze automatically:

```r
source("hospital_configuration_helper.R")
helper <- HospitalConfigHelper()

# Analyze the structure
helper$analyze_hospital_structure(
  fac = 777,
  name = "Queensway Carleton Hospital",
  url = "https://www.qch.on.ca/Leadership"
)
```

**The tool will show you:**
- Element counts (H1, H2, H3, P, tables, lists)
- Sample content from each element type
- Common CSS classes found
- **Suggested pattern** based on structure
- **Sample YAML configuration** to use

**Review the output** and note the suggested pattern.

---

### Step 3: Select the Appropriate Pattern

Use the **Pattern Selection Decision Tree** from the Pattern Registry:

```
Are name and title in SAME element?
├─ YES → Pattern 2 (combined_h2)
└─ NO → Continue...

Is it a table structure?
├─ YES →
│  ├─ Simple columns? → Pattern 3 (table_rows)
│  ├─ Nested elements? → Pattern 8 (custom_table_nested)
│  └─ Mixed formats? → Pattern 11 (qch_mixed_tables)
└─ NO → Continue...

Are they in list items (ul/ol)?
├─ YES → Pattern 6 (list_items)
└─ NO → Continue...

Do elements have CSS classes?
├─ YES →
│  ├─ Different classes? → Pattern 5 (div_classes)
│  └─ Same class, sequential? → Pattern 9 (field_content_sequential)
└─ NO → Continue...

Do elements have ID patterns?
├─ YES → Pattern 10 (nested_list_with_ids)
└─ NO → Continue...

Is it a gallery/card layout?
├─ YES → Pattern 7 (boardcard_gallery)
└─ NO → Continue...

Is it specifically H2→P or P→P?
├─ YES → Pattern 4 (h2_name_p_title)
└─ NO → Pattern 1 (h2_name_h3_title) with custom elements
```

**Common Patterns by Frequency:**
1. **Pattern 1** (h2_name_h3_title) - 15% of hospitals
2. **Pattern 2** (combined_h2) - 20% of hospitals
3. **Pattern 5** (div_classes) - 23% of hospitals

Refer to the **Pattern Registry** for detailed examples of each pattern.

---

### Step 4: Create YAML Configuration

Add the hospital to your `enhanced_hospitals.yaml` file.

#### Template Selection

Choose the appropriate template based on your pattern:

**Pattern 1 Template (h2_name_h3_title):**
```yaml
- FAC: "XXX"
  name: "Hospital Name"
  url: "https://hospital.com/leadership"
  pattern: "h2_name_h3_title"
  expected_executives: 6
  html_structure:
    name_element: "h2"
    title_element: "h3"
    notes: "h2=Name, h3=Title pattern"
  status: "needs_testing"
```

**Pattern 2 Template (combined_h2):**
```yaml
- FAC: "XXX"
  name: "Hospital Name"
  url: "https://hospital.com/leadership"
  pattern: "combined_h2"
  expected_executives: 6
  html_structure:
    combined_element: "h2"
    separator: " - "
    notes: "Name and title together separated by ' - '"
  status: "needs_testing"
```

**Pattern 5 Template (div_classes):**
```yaml
- FAC: "XXX"
  name: "Hospital Name"
  url: "https://hospital.com/leadership"
  pattern: "div_classes"
  expected_executives: 6
  html_structure:
    name_class: "staff-name"
    title_class: "staff-title"
    container_class: "staff-member"
    notes: "Names in .staff-name, titles in .staff-title"
  status: "needs_testing"
```

**See Pattern Registry** for templates for all 11 patterns.

#### Key Fields to Configure:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| FAC | Yes | 3-digit facility code | "777" |
| name | Yes | Hospital name | "Queensway Carleton Hospital" |
| url | Yes | Leadership page URL | "https://..." |
| pattern | Yes | Pattern type | "h2_name_h3_title" |
| expected_executives | Recommended | Number of expected executives | 6 |
| html_structure | Yes | Pattern-specific config | See templates |
| notes | Optional | Additional notes | "Works well" |
| status | Optional | Current status | "needs_testing" |

---

### Step 5: Test the Configuration

#### 5A. Quick Test (Recommended First)

Test just this one hospital:

```r
source("pattern_based_scraper.R")
quick_test(777)  # Use your FAC number
```

**Expected Output:**
```
=== TESTING FAC-777 ===
Hospital: Queensway Carleton Hospital
URL: https://www.qch.on.ca/Leadership
Pattern: qch_mixed_tables
Expected executives: 9
=======================================

Scraping...
  Success: 9 executives found

=== RESULTS ===
✓ SUCCESS: 9 executives found
✓ COMPLETE: Found expected number of executives (9)

Executives Found:
 1. Dr. Andrew Falconer           → President & CEO
 2. Dr. Katalin Kovacs            → Chief of Staff
 3. Cameron Best                  → Vice President Corporate...
 [etc...]
```

#### 5B. Detailed Test with Helper

If quick test fails or gives unexpected results:

```r
# Use the helper's test function for more details
helper$test_hospital_config(
  fac = 777,
  name = "Queensway Carleton Hospital",
  url = "https://www.qch.on.ca/Leadership",
  pattern = "qch_mixed_tables"
)
```

---

### Step 6: Evaluate Results

#### Success Criteria:

✅ **Complete Success:**
- Found count = Expected count
- All names are valid (proper capitalization, real names)
- All titles are valid (contain executive keywords)
- No duplicate entries

⚠️ **Partial Success:**
- Found count < Expected count
- Consider using `missing_people` for remaining executives

❌ **Failure:**
- Found count = 0
- Invalid names/titles captured
- Error messages

---

### Step 7: Handle Special Cases

#### 7A. Missing People

If some executives aren't captured by the scraper, add them manually:

```yaml
- FAC: "XXX"
  name: "Hospital Name"
  url: "https://hospital.com/leadership"
  pattern: "div_classes"
  expected_executives: 6
  html_structure:
    name_class: "staff-name"
    title_class: "staff-title"
    missing_people:                    # ← Add this section
      - name: "Dr. Jane Smith"
        title: "Chief of Staff"
      - name: "Bob Johnson"
        title: "Vice President, Operations"
  status: "configured"
```

**When to use missing_people:**
- Executives in different HTML sections
- People with non-standard name formatting
- Executives in image-only sections
- Known executives not on the scraped page

#### 7B. Accented Names

Accented names are **automatically handled** by the system:
- Gisèle Larocque ✅
- José García ✅
- François Dubois ✅

No special configuration needed!

#### 7C. Website Blocks Scraping

Some hospitals block automated access:

```yaml
- FAC: "927"
  name: "Windsor Hotel Dieu Grace"
  url: "https://www.hdgh.org/leadership"
  pattern: "manual_entry_required"
  html_structure:
    notes: "Website blocks automated scraping"
  status: "blocked_by_site"
  known_executives:
    - name: "Bill Marra"
      title: "President and CEO"
    # ... list all manually
```

#### 7D. Multiple Sections on Page

If page has both "Senior Administration" and "Medical Leadership":

**Option 1:** Configure to scrape only relevant section
- Pattern 11 (qch_mixed_tables) does this automatically
- Pattern 8 (custom_table_nested) can be configured for this

**Option 2:** Scrape all, then filter manually
- Less ideal but works for simple cases

---

### Step 8: Update Status

Once tested and working, update the status field:

```yaml
status: "configured"  # Working perfectly
status: "ok"          # Working with minor issues
status: "needs_testing"  # Just added, not tested yet
status: "needs_configuration"  # Needs work
status: "blocked_by_site"  # Can't scrape
```

---

### Step 9: Document Findings

Add helpful notes to your configuration:

```yaml
notes: "h2=Name with credentials, p=Title. Works perfectly."
notes: "Table 1 uses divs, Tables 2-3 use p tags for titles"
notes: "Excludes Medical Leadership section automatically"
notes: "Requires missing_people for CEO (not on main page)"
```

**Good notes include:**
- What makes this hospital unique
- Why you chose this pattern
- Any quirks or special handling
- Why some executives might be in missing_people

---

### Step 10: Commit to Configuration

1. **Save** `enhanced_hospitals.yaml`
2. **Test again** with `quick_test(FAC)`
3. **Run full test suite** to ensure you didn't break anything:
   ```r
   source("test_all_configured_hospitals.R")
   results <- test_all_configured_hospitals()
   ```

---

## Pattern Selection Guide

### Quick Pattern Finder

**I see this structure → Use this pattern:**

| HTML Structure | Pattern | Pattern Number |
|----------------|---------|----------------|
| `<h2>Name</h2><h3>Title</h3>` | h2_name_h3_title | 1 |
| `<h3>Name - Title</h3>` | combined_h2 | 2 |
| Table with Name/Title columns | table_rows | 3 |
| `<h2>Name</h2><p>Title</p>` | h2_name_p_title | 4 |
| `<div class="name">` `<div class="title">` | div_classes | 5 |
| `<li>Name \| Title</li>` | list_items | 6 |
| `<div class="card">Name, Title</div>` | boardcard_gallery | 7 |
| Complex nested tables | custom_table_nested | 8 |
| Same class, repeating pattern | field_content_sequential | 9 |
| Elements with ID patterns | nested_list_with_ids | 10 |
| Mixed table formats | qch_mixed_tables | 11 |

### Pattern Customization Examples

**Pattern 1 - Different Elements:**
```yaml
# Use h3 and h4 instead of h2 and h3
html_structure:
  name_element: "h3"
  title_element: "h4"
```

**Pattern 2 - Different Separator:**
```yaml
# Pipe separator instead of dash
html_structure:
  combined_element: "h3"
  separator: " | "
```

**Pattern 6 - Comma Separator:**
```yaml
# Handle "Name, Title" format in lists
html_structure:
  list_type: "ul"
  format: "combined"
  separator: ", "
```

---

## Troubleshooting Common Issues

### Issue 1: No Results Found

**Symptoms:**
- `quick_test(FAC)` returns 0 executives
- "No executives found" message

**Diagnosis Steps:**
1. Check if URL is accessible in browser
2. Verify HTML structure hasn't changed
3. Run `helper$analyze_hospital_structure()` to inspect

**Common Causes:**
- Wrong pattern selected
- Website structure changed
- Website requires JavaScript (can't scrape)
- Wrong CSS selectors/element types

**Solutions:**
- Try different pattern
- Update YAML configuration
- Use `missing_people` or `manual_entry_required`

---

### Issue 2: Partial Results

**Symptoms:**
- Found 3 of 6 expected executives
- Some executives missing

**Diagnosis:**
```r
# Enable verbose mode to see what's rejected
quick_test(FAC)  # Look for "DEBUG: Rejected" messages
```

**Common Causes:**
- Names don't match validation patterns (accents, hyphens, etc.)
- Titles don't contain executive keywords
- Some executives in different HTML structure
- Separator character mismatch

**Solutions:**
```yaml
# Add missing people manually
html_structure:
  # ... existing config ...
  missing_people:
    - name: "Missing Executive Name"
      title: "Their Title"
```

---

### Issue 3: Wrong Data Captured

**Symptoms:**
- Captures board members instead of executives
- Captures navigation menu items
- Captures non-executive names

**Diagnosis:**
- Review captured names/titles
- Check if pattern is too broad

**Solutions:**
- Use more specific pattern (e.g., Pattern 5 with exact CSS classes)
- Add filters to exclude certain sections
- Use Pattern 11 for mixed content pages

---

### Issue 4: Duplicate Entries

**Symptoms:**
- Same person appears multiple times
- Person appears in both scraped results and missing_people

**Solutions:**
- Remove from `missing_people` if scraper finds them
- Check if person appears in multiple sections of page
- Duplicate removal is automatic in most patterns

---

### Issue 5: Special Characters/Encoding

**Symptoms:**
- Names with accents show as garbage characters (Ã¨ instead of è)
- Ampersands show as `&amp;`

**Solutions:**
- System handles this automatically via `normalize_text()`
- If issues persist, check R's locale settings:
  ```r
  Sys.setlocale("LC_ALL", "en_US.UTF-8")
  ```

---

## Quality Control

### Validation Checklist

Before marking a hospital as "configured", verify:

- [ ] **Correct FAC number** (3 digits, matches master list)
- [ ] **Correct hospital name** (official name)
- [ ] **Working URL** (accessible, not 404)
- [ ] **Appropriate pattern** (matches HTML structure)
- [ ] **All expected executives found** (or documented in missing_people)
- [ ] **Valid names** (proper capitalization, no HTML tags)
- [ ] **Valid titles** (contain executive keywords)
- [ ] **No duplicates** (each person appears once)
- [ ] **Status updated** (from "needs_testing" to "configured")
- [ ] **Notes added** (document any quirks or special handling)

### Periodic Maintenance

**Monthly:**
- Run full test suite to catch website changes
- Update any hospitals showing errors
- Verify missing_people are still at hospital

**Quarterly:**
- Review and update expected_executives counts
- Check for new executives on websites
- Verify URLs still work

**Annually:**
- Full audit of all hospitals
- Update pattern configurations if needed
- Document any new patterns discovered

---

## Quick Reference: Common Commands

```r
# Load all tools
setwd("E:/ExecutiveSearchYaml/code/")
source("pattern_based_scraper.R")
source("hospital_configuration_helper.R")
source("quick_test_single.R")
source("test_all_configured_hospitals.R")

# Analyze new hospital
helper <- HospitalConfigHelper()
helper$analyze_hospital_structure(FAC, "Name", "URL")

# Test single hospital
quick_test(FAC)

# Test specific configuration
helper$test_hospital_config(FAC, "Name", "URL", "pattern_name")

# Check configuration status (no scraping)
status <- check_configuration_status()

# Full test of all hospitals
results <- test_all_configured_hospitals()

# Show available FACs in YAML
show_available_facs()

# View pattern guide
helper$show_pattern_guide()
```

---

## Tips for Success

### Do's ✅
- Always test with `quick_test()` before committing
- Document unusual configurations in notes
- Use `missing_people` when appropriate
- Keep expected_executives counts up to date
- Test after making any changes
- Use descriptive notes in YAML

### Don'ts ❌
- Don't skip the analysis step
- Don't assume pattern without testing
- Don't hardcode data if scraping is possible
- Don't forget to update status field
- Don't leave TODO notes without follow-up
- Don't commit untested configurations

### Best Practices 🌟
1. **Start simple** - Try Pattern 1 or 2 first
2. **Test incrementally** - One hospital at a time
3. **Document everything** - Future you will thank you
4. **Use helper tools** - They save time and catch issues
5. **Keep patterns consistent** - Don't reinvent if existing pattern works
6. **Monitor for changes** - Websites update, configurations break

---

## Workflow Summary (TL;DR)

```
1. Gather Info (FAC, Name, URL)
   ↓
2. Inspect HTML (Browser or helper tool)
   ↓
3. Select Pattern (Use decision tree)
   ↓
4. Create YAML Config (Use template)
   ↓
5. Test Configuration (quick_test)
   ↓
6. Evaluate Results (Complete/Partial/Failed)
   ↓
7. Handle Special Cases (missing_people, etc.)
   ↓
8. Update Status (mark as "configured")
   ↓
9. Document Findings (add notes)
   ↓
10. Commit Configuration (save and final test)
```

**Average time per hospital:** 5-15 minutes

---

## Getting Help

**If stuck:**
1. Review Pattern Registry for examples
2. Use `helper$analyze_hospital_structure()` to inspect HTML
3. Check existing similar hospitals in YAML
4. Try `helper$show_pattern_guide()` for pattern overview
5. Test with different patterns if first doesn't work

**Common Resources:**
- `PATTERN_REGISTRY.md` - Complete pattern documentation
- `enhanced_hospitals.yaml` - All configured examples
- `hospital_configuration_helper.R` - Analysis tools
- `test_all_configured_hospitals.R` - Testing suite

---

**Version:** 1.0  
**Last Updated:** 2025-01-08  
**Maintainer:** Executive Search System