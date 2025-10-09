# Hospital Scraper Pattern Registry
**Complete Reference Guide for All 11 Patterns**  
Last Updated: 2025-01-08

---

## Pattern Overview

| Pattern # | Pattern Name | Complexity | Common Use | Hospitals Using |
|-----------|-------------|------------|------------|-----------------|
| 1 | h2_name_h3_title | Low | Sequential different elements | FAC 707, 624, 596 |
| 2 | combined_h2 | Low | Name+title in same element | FAC 941, 952, 619, 970 |
| 3 | table_rows | Low | Simple table columns | FAC 661, 781 |
| 4 | h2_name_p_title | Low | Specific H2→P sequence | FAC 953, 632, 947 |
| 5 | div_classes | Medium | CSS class-based | FAC 606, 695, 979, 837, 976 |
| 6 | list_items | Medium | List with separators | FAC 957, 790, 850 |
| 7 | boardcard_gallery | Medium | Card/gallery layouts | FAC 935 |
| 8 | custom_table_nested | High | Complex nested tables | - |
| 9 | field_content_sequential | Medium | Repeating same-class pattern | FAC 939 |
| 10 | nested_list_with_ids | Medium | ID patterns, complex selectors | FAC 827 |
| 11 | qch_mixed_tables | High | Mixed table structures | FAC 777 |

---

## Pattern 1: h2_name_h3_title
**Sequential Different Elements**

### Description
Names and titles are in separate, sequential HTML elements. Name element is followed by title element.

### When to Use
- Names in `<h2>`, titles in `<h3>` (or similar heading combinations)
- Elements appear in predictable sequence on page
- Most common pattern for simple leadership pages

### YAML Structure
```yaml
pattern: "h2_name_h3_title"
html_structure:
  name_element: "h2"      # Can be h1-h6, p, span, div, strong
  title_element: "h3"     # Can be h1-h6, p, span, div, strong
  notes: "h2=Name, h3=Title pattern"
```

### Customization Options
- `name_element`: Any HTML element (h1-h6, p, span, div, strong)
- `title_element`: Any HTML element (h1-h6, p, span, div, strong)
- Works with `missing_people`

### Real Examples
```yaml
# FAC 707 - Ross Memorial Hospital
- FAC: "707"
  name: "Ross Memorial Hospital"
  url: "https://rmh.org/about-ross-memorial/senior-leadership"
  pattern: "h2_name_h3_title"
  expected_executives: 6
  html_structure:
    name_element: "h2"
    title_element: "h3"
    notes: "h2=Name, h3=Title - works well"
```

### HTML Example
```html
<h2>Dr. John Smith</h2>
<h3>Chief Executive Officer</h3>
<h2>Jane Doe</h2>
<h3>Chief Financial Officer</h3>
```

---

## Pattern 2: combined_h2
**Combined Name+Title in Single Element**

### Description
Name and title are in the SAME element, separated by a character/string.

### When to Use
- Format like "John Smith - CEO" or "Jane Doe, President"
- Single element contains both pieces of information
- Consistent separator throughout

### YAML Structure
```yaml
pattern: "combined_h2"
html_structure:
  combined_element: "h2"   # Can be any element
  separator: " - "          # Character(s) separating name from title
  notes: "Name and title together in h2 separated by ' - '"
```

### Customization Options
- `combined_element`: h1-h6, p, div, span, li, td
- `separator`: Any string (` - `, `, `, ` | `, `: `, etc.)
- Works with `missing_people`

### Real Examples
```yaml
# FAC 941 - Humber River Hospital
- FAC: "941"
  name: "Humber River Hospital"
  url: "https://www.hrh.ca/who-we-are/accountability/governance-leadership/"
  pattern: "combined_h2"
  html_structure:
    combined_element: "h3"
    separator: " - "
    notes: "Name and title combined in h3 elements, separated by ' - '"
```

### HTML Example
```html
<h3>Dr. John Smith - Chief Executive Officer</h3>
<h3>Jane Doe - Chief Financial Officer</h3>
```

---

## Pattern 3: table_rows
**Simple Table Structure**

### Description
Names and titles are in table cells, typically in different columns.

### When to Use
- Data organized in HTML tables
- Clear column structure (e.g., Name | Title | Contact)
- Simple table layout without nested elements

### YAML Structure
```yaml
pattern: "table_rows"
html_structure:
  structure_type: "table"
  name_location: "td_column_1"   # or th_column_1
  title_location: "td_column_2"  # or th_column_2
  notes: "Standard table with name/title columns"
```

### Customization Options
- `name_location`: "td_column_X" or "th_column_X" (X = 1, 2, 3, etc.)
- `title_location`: "td_column_X" or "th_column_X"
- Works with `missing_people`

### Real Examples
```yaml
# FAC 661 - Cambridge Memorial Hospital
- FAC: "661"
  name: "Cambridge Memorial Hospital"
  url: "https://www.cmh.org/contacts"
  pattern: "table_rows"
  expected_executives: 5
  html_structure:
    structure_type: "table"
    name_location: "td_column_1"
    title_location: "td_column_2"
    notes: "Table structure, names in col 1, titles in col 2"
```

### HTML Example
```html
<table>
  <tr>
    <td>Dr. John Smith</td>
    <td>Chief Executive Officer</td>
    <td>ext. 1234</td>
  </tr>
  <tr>
    <td>Jane Doe</td>
    <td>Chief Financial Officer</td>
    <td>ext. 5678</td>
  </tr>
</table>
```

---

## Pattern 4: h2_name_p_title
**Specific H2→P Sequential Pattern**

### Description
Name in H2 element, title in the immediately following P element. More strict than Pattern 1.

### When to Use
- Specifically when structure is `<h2>Name</h2>` followed by `<p>Title</p>`
- Need stricter matching than Pattern 1
- Common in blog-style layouts

### YAML Structure
```yaml
pattern: "h2_name_p_title"
html_structure:
  name_element: "h2"    # Fixed as h2
  title_element: "p"    # Fixed as p
  notes: "h2=Name, immediately followed by p=Title"
```

### Customization Options
- Not customizable (fixed h2→p pattern)
- For other combinations, use Pattern 1
- Works with `missing_people`

### Real Examples
```yaml
# FAC 953 - Sunnybrook Health Sciences Centre
- FAC: "953"
  name: "Sunnybrook Health Sciences Centre"
  url: "https://sunnybrook.ca/content/?page=executive-leadership"
  pattern: "h2_name_p_title"
  expected_executives: 8
  html_structure:
    name_element: "h2"
    title_element: "p"
    notes: "h2=Name with credentials, p=Title"
```

### HTML Example
```html
<h2>Dr. John Smith, MD, MSc</h2>
<p>Chief Executive Officer</p>
<h2>Jane Doe, MBA, CPA</h2>
<p>Chief Financial Officer</p>
```

---

## Pattern 5: div_classes
**CSS Class-Based Selection**

### Description
Names and titles are in elements with specific CSS classes.

### When to Use
- HTML uses semantic CSS classes like `class="name"` and `class="title"`
- Modern web design with structured CSS
- Elements have consistent class naming

### YAML Structure
```yaml
pattern: "div_classes"
html_structure:
  name_class: "staff-name"       # CSS class for names (no dot)
  title_class: "staff-title"     # CSS class for titles (no dot)
  container_class: "staff-member" # Optional parent container
  notes: "Names in .staff-name divs, titles in .staff-title divs"
```

### Customization Options
- `name_class`: Any CSS class name (without the `.`)
- `title_class`: Any CSS class name (without the `.`)
- `container_class`: Optional parent container class
- Works with `missing_people`

### Real Examples
```yaml
# FAC 606 - Barrie Royal Victoria Regional Health Centre
- FAC: "606"
  name: "BARRIE ROYAL VICTORIA REG HC"
  url: "https://www.rvh.on.ca/about-rvh/senior-leadership-team/"
  pattern: "div_classes"
  expected_executives: 11
  html_structure:
    name_class: "card-title"
    title_class: "card-subtitle"
    container_class: "card-info"
    notes: "Names in .card-title divs, titles in .card-subtitle divs"

# FAC 695 - Kingston Providence Care Hospital (with missing_people)
- FAC: "695"
  name: "KINGSTON PROVIDENCE CARE HOSPITAL"
  url: "https://providencecare.ca/about-us/senior-leadership-team/"
  pattern: "div_classes"
  html_structure:
    name_class: "mb-name"
    title_class: "mb-position"
    container_class: "mb-item"
    missing_people:
      - name: "Dr. Simon O'Brien"
        title: "Chair, Medical Advisory Committee"
      - name: "Tamás Zsolnay"
        title: "President & CEO, University Hospitals Kingston Foundation"
```

### HTML Example
```html
<div class="staff-member">
  <div class="staff-name">Dr. John Smith</div>
  <div class="staff-title">Chief Executive Officer</div>
</div>
<div class="staff-member">
  <div class="staff-name">Jane Doe</div>
  <div class="staff-title">Chief Financial Officer</div>
</div>
```

---

## Pattern 6: list_items
**List with Separators**

### Description
Names and titles are in list items (ul/ol), combined with separator.

### When to Use
- Executives in `<ul>` or `<ol>` lists
- Format: "Name | Title" or "Name - Title" in each `<li>`
- Consistent separator throughout

### YAML Structure
```yaml
pattern: "list_items"
html_structure:
  list_type: "ul"        # ul or ol
  format: "combined"     # combined or sequential
  separator: " | "       # Separator string (handles flexible whitespace)
  notes: "Names and titles in li elements with separator"
```

### Customization Options
- `list_type`: "ul" or "ol"
- `format`: "combined" (name-title in same li) or "sequential" (separate lis)
- `separator`: Any string - automatically handles whitespace variations
- Works with `missing_people`

### Real Examples
```yaml
# FAC 790 - St Catharines Hotel Dieu
- FAC: "790"
  name: "ST CATHARINES HOTEL DIEU"
  url: "https://www.hoteldieushaver.org/site/team"
  pattern: "list_items"
  expected_executives: 5
  html_structure:
    list_type: "ul"
    format: "combined"
    separator: " | "
    notes: "List items with pipe separator. Format: Name | Title | email"

# FAC 957 - Belleville Quinte Health Care
- FAC: "957"
  name: "BELLEVILLE QUINTE HEALTH CARE"
  url: "https://quintehealth.ca/about-quinte-health/leadership/"
  pattern: "list_items"
  html_structure:
    list_type: "ul"
    format: "combined"
    separator: ", "
    notes: "Names and titles in li elements separated by ', '"
```

### HTML Example
```html
<ul>
  <li>Dr. John Smith | Chief Executive Officer | email</li>
  <li>Jane Doe | Chief Financial Officer | email</li>
  <li>Bob Johnson | Chief Medical Officer | email</li>
</ul>
```

---

## Pattern 7: boardcard_gallery
**Card/Gallery Layouts**

### Description
Executives in card or gallery layout with specific div class, name and title separated by comma.

### When to Use
- Gallery or card-based visual layouts
- Combined name-title text in card containers
- Common in modern responsive designs

### YAML Structure
```yaml
pattern: "boardcard_gallery"
html_structure:
  container_class: "boardcard"     # CSS class of card container
  text_format: "name_comma_title"
  separator: ","                    # Usually comma
  notes: "Gallery cards with combined name,title format"
```

### Customization Options
- `container_class`: CSS class of the card/gallery container
- `separator`: Character separating name from title (usually comma)
- Works with `missing_people`

### Real Examples
```yaml
# FAC 935 - Thunder Bay Regional Health Sciences Centre
- FAC: "935"
  name: "Thunder Bay Regional Health Sciences Centre"
  url: "https://tbrhsc.net/tbrhsc/senior-leadership-council/"
  pattern: "boardcard_gallery"
  expected_executives: 8
  html_structure:
    container_class: "boardcard"
    text_format: "name_comma_title"
    separator: ","
    notes: "Gallery of senior leaders, CEO needs manual addition"
    missing_people:
      - name: "Dr. Rhonda Crocker Ellacott"
        title: "President and CEO"
```

### HTML Example
```html
<div class="boardcard">
  Dr. John Smith, Chief Executive Officer. Leading the organization...
</div>
<div class="boardcard">
  Jane Doe, Chief Financial Officer. Responsible for financial...
</div>
```

---

## Pattern 8: custom_table_nested
**Complex Nested Tables**

### Description
Table structure with nested elements inside cells (like p inside td, div inside td).

### When to Use
- Complex table structures with nested HTML
- Names and titles buried in nested tags
- Requires specific CSS selectors

### YAML Structure
```yaml
pattern: "custom_table_nested"
html_structure:
  structure_type: "table_with_nested_elements"
  name_selector: "td p strong"                      # Full CSS selector
  title_selector: "td div[style*='text-align']"    # Full CSS selector
  container: "td"                                   # Parent element
  notes: "Complex table with nested p/div elements in cells"
```

### Customization Options
- `name_selector`: Full CSS selector (can include attributes, styles)
- `title_selector`: Full CSS selector
- `container`: Parent element containing both
- Works with `missing_people`

### Real Examples
```yaml
# Currently no hospitals use this exact pattern
# Pattern 11 (qch_mixed_tables) replaced it for FAC 777
```

### HTML Example
```html
<table>
  <tr>
    <td>
      <p style="text-align: left">
        <strong>Dr. John Smith</strong>
      </p>
      <div style="text-align: left">Chief Executive Officer</div>
    </td>
  </tr>
</table>
```

---

## Pattern 9: field_content_sequential
**Sequential Same-Class Elements**

### Description
All data in the same CSS class, appearing in a predictable sequential pattern with fixed step interval.

### When to Use
- Website dumps all data into same CSS class
- Predictable repeating pattern (Name, Title, Empty, Name, Title, Empty...)
- Need to skip specific number of elements

### YAML Structure
```yaml
pattern: "field_content_sequential"
html_structure:
  element_selector: ".field-content"      # CSS selector for repeating elements
  pattern_type: "sequential_every_3"     # Description of pattern
  start_index: 3                          # Which element to start from (1-based)
  notes: "Pattern: skip first N, then Name, Title, Empty, repeat"
```

### Customization Options
- `element_selector`: CSS selector for the repeating elements
- `pattern_type`: Description (for documentation)
- `start_index`: Which element to start from
- Pattern logic: starts at `start_index`, takes name at i, title at i+1, skips to i+3
- Works with `missing_people`

### Real Examples
```yaml
# FAC 939 - Toronto Holland Bloorview Kids
- FAC: "939"
  name: "TORONTO HOLLAND BLOORVIEW KIDS"
  url: "https://hollandbloorview.ca/about-us/hospital-executive-leadership-team"
  pattern: "field_content_sequential"
  expected_executives: 8
  html_structure:
    element_selector: ".field-content"
    pattern_type: "sequential_every_3"
    start_index: 3
    notes: "All data in .field-content. Pattern: skip first 2, then Name, Title, Empty, repeat"
```

### HTML Example
```html
<div class="field-content">Header Text</div>
<div class="field-content">Other Info</div>
<div class="field-content">Dr. John Smith</div>       <!-- Start here (index 3) -->
<div class="field-content">Chief Executive Officer</div>
<div class="field-content"></div>                     <!-- Empty -->
<div class="field-content">Jane Doe</div>
<div class="field-content">Chief Financial Officer</div>
<div class="field-content"></div>
```

---

## Pattern 10: nested_list_with_ids
**ID-Based Sequential Pairing**

### Description
Names and titles in separate elements identified by ID patterns or specific selectors, paired sequentially.

### When to Use
- Elements have ID patterns (e.g., `id="t-1"`, `id="t-2"`)
- Need complex CSS selectors
- Elements appear in same sequential order
- More powerful than simple class matching

### YAML Structure
```yaml
pattern: "nested_list_with_ids"
html_structure:
  name_selector: "div[id^='t-']"       # CSS selector (ID pattern)
  title_selector: "span[id^='d-']"     # CSS selector (ID pattern)
  container: "li.column"               # Optional parent container
  notes: "Names and titles in elements with ID patterns, sequentially paired"
```

### Customization Options
- `name_selector`: Any CSS selector (ID patterns, classes, attributes)
- `title_selector`: Any CSS selector
- `container`: Optional parent container
- Pairing logic: name[1] with title[1], name[2] with title[2], etc.
- Works with `missing_people`

### Real Examples
```yaml
# FAC 827 - Toronto Baycrest Centre for Geriatric Care
- FAC: "827"
  name: "TORONTO BAYCREST CTR GERIATRIC CARE"
  url: "https://www.baycrest.org/Baycrest-Hospital-Executive-Team"
  pattern: "nested_list_with_ids"
  expected_executives: 5
  html_structure:
    name_selector: "div[id^='t-']"
    title_selector: "span[id^='d-']"
    container: "li.column"
    notes: "Names in div IDs starting with 't-', titles in span IDs starting with 'd-'"
```

### HTML Example
```html
<ul>
  <li class="column">
    <div id="t-0">Dr. John Smith</div>
    <span id="d-0">Chief Executive Officer</span>
  </li>
  <li class="column">
    <div id="t-1">Jane Doe</div>
    <span id="d-1">Chief Financial Officer</span>
  </li>
</ul>
```

---

## Pattern 11: qch_mixed_tables
**Mixed Table Structures (QCH-Style)**

### Description
Tables use different formats - some use divs, some use p tags for titles. Handles inconsistent HTML within same page.

### When to Use
- Multiple tables with different internal structures
- Some tables use `<div>` for titles, others use `<p>`
- Need to process only first N tables
- Complex multi-format pages

### YAML Structure
```yaml
pattern: "qch_mixed_tables"
html_structure:
  notes: "Mixed table structure - handles both div and p tag formats for titles"
```

### Customization Options
- Automatically processes first 3 non-breadcrumb tables
- Handles both `<div style="text-align">` and `<p>` for titles
- Skips breadcrumb tables with `role="presentation"`
- Works with `missing_people`

### Real Examples
```yaml
# FAC 777 - Queensway Carleton Hospital
- FAC: "777"
  name: "Queensway Carleton Hospital"
  url: "https://www.qch.on.ca/Leadership"
  pattern: "qch_mixed_tables"
  expected_executives: 9
  html_structure:
    notes: "Mixed table structure - Table 1 uses divs, Tables 2-3 use p tags for titles"
```

### HTML Example
```html
<!-- Table 1: Uses divs -->
<table>
  <tr>
    <td>
      <p><strong>Dr. John Smith</strong></p>
      <div style="text-align: left">Chief Executive Officer</div>
    </td>
  </tr>
</table>

<!-- Table 2: Uses p tags -->
<table>
  <tr>
    <td>
      <p><strong>Jane Doe</strong></p>
      <p>Chief Financial Officer</p>
    </td>
  </tr>
</table>
```

---

## Pattern Selection Decision Tree

```
Start Here
│
├─ Are name and title in SAME element?
│  ├─ YES → Pattern 2 (combined_h2)
│  └─ NO → Continue...
│
├─ Is it a table structure?
│  ├─ YES →
│  │  ├─ Simple columns? → Pattern 3 (table_rows)
│  │  ├─ Nested elements? → Pattern 8 (custom_table_nested)
│  │  └─ Mixed formats? → Pattern 11 (qch_mixed_tables)
│  └─ NO → Continue...
│
├─ Are they in list items (ul/ol)?
│  ├─ YES → Pattern 6 (list_items)
│  └─ NO → Continue...
│
├─ Do elements have CSS classes?
│  ├─ YES →
│  │  ├─ Different classes? → Pattern 5 (div_classes)
│  │  └─ Same class, sequential? → Pattern 9 (field_content_sequential)
│  └─ NO → Continue...
│
├─ Do elements have ID patterns?
│  ├─ YES → Pattern 10 (nested_list_with_ids)
│  └─ NO → Continue...
│
├─ Is it a gallery/card layout?
│  ├─ YES → Pattern 7 (boardcard_gallery)
│  └─ NO → Continue...
│
├─ Is it specifically H2→P?
│  ├─ YES → Pattern 4 (h2_name_p_title)
│  └─ NO → Pattern 1 (h2_name_h3_title) with custom elements
```

---

## Special Features

### Missing People Support
All patterns support the `missing_people` feature to manually add executives not captured by scraping:

```yaml
html_structure:
  # ... pattern-specific config ...
  missing_people:
    - name: "Dr. Jane Smith"
      title: "Chief of Staff"
    - name: "Bob Johnson"
      title: "Vice President, Operations"
```

### Accented Name Support
All patterns automatically handle international names with accented characters:
- Gisèle → Recognized
- José → Recognized
- François → Recognized
- Tamás → Recognized

Powered by `normalize_name_for_matching()` function and `accented_names` patterns in YAML.

---

## Pattern Testing

### Test Single Hospital
```r
source("pattern_based_scraper.R")
quick_test(FAC_NUMBER)
```

### Test All Hospitals
```r
source("test_10_hospitals.R")
results <- test_all_hospitals_from_yaml()
```

### Analyze Hospital Structure
```r
source("hospital_configuration_helper.R")
helper <- HospitalConfigHelper()
helper$analyze_hospital_structure(FAC, "Hospital Name", "URL")
```

---

## Common Troubleshooting

### No Results Found
1. Check if URL is accessible
2. Use `helper$analyze_hospital_structure()` to inspect HTML
3. Verify pattern matches actual structure
4. Check if names/titles match validation patterns

### Partial Results
1. Check `expected_executives` vs actual count
2. Look for `missing_people` in YAML comments
3. Verify separator characters (exact match required)
4. Check for whitespace issues (non-breaking spaces)

### Wrong Pattern Selected
1. Use Pattern Selection Decision Tree
2. Inspect actual HTML with browser dev tools
3. Try `helper$show_pattern_guide()` for examples
4. Test with `helper$test_hospital_config()`

---

## Version History

- **v1.0** (2025-01-08): Initial registry with 11 patterns
  - Patterns 1-10: Original patterns
  - Pattern 11: QCH-style mixed tables added
  - Accented name support added
  - missing_people support standardized across all patterns

---

## Next Steps

1. **Configure remaining hospitals** using appropriate patterns
2. **Test all configured hospitals** to ensure consistency
3. **Document hospital-specific quirks** in YAML notes
4. **Monitor for website changes** that require pattern updates