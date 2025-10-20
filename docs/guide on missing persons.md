# Hospital Scraper - Pattern Quick Reference Guide

| **Pattern** | **HTML Structure Items (labels)** | **Elements in the Structure** | **FAC & Hospital** |
|-------------|-----------------------------------|-------------------------------|-------------------|
| **h2_name_h3_title** | name_element:<br>title_element: | h2, h3, h4, p, strong, span<br>h3, h4, p, span, div | FAC-707 Ross Memorial<br>FAC-624 Campbellford<br>FAC-596 Stevenson |
| **combined_h2** | combined_element:<br>separator: | h2, h3, p, li, div, span<br>" - ", ", ", " \| " | FAC-941 Brockville<br>FAC-952 Southlake<br>FAC-619 Smith Falls |
| **table_rows** | structure_type:<br>name_location:<br>title_location: | "table"<br>td_column_1, td_column_2<br>td_column_2, td_column_3 | FAC-661 Espanola<br>FAC-781 St. Joseph's TB |
| **h2_name_p_title** | name_element:<br>title_element: | h2 (fixed)<br>p (fixed) | FAC-953 Headwaters<br>FAC-632 St. Mary's KW<br>FAC-932 Elizabeth Bruyère |
| **div_classes** | name_class:<br>title_class:<br>container_class: | "staff-name", "exec-name"<br>"staff-title", "position"<br>"staff-member" (optional) | FAC-606 Queensway Carleton<br>FAC-695 Arnprior<br>FAC-905 Hamilton HS |
| **list_items** | list_type:<br>format:<br>separator: | "ul", "ol"<br>"combined"<br>" \| ", " - ", ", " | FAC-957 Hanover<br>FAC-790 Grey Bruce<br>FAC-850 Runnymede |
| **boardcard_gallery** | container_class:<br>text_format:<br>separator: | "boardcard", "team-card"<br>"name_comma_title"<br>",", " - " | FAC-935 Kemptville |
| **custom_table_nested** | structure_type:<br>name_selector:<br>title_selector:<br>container: | "table_with_nested_elements"<br>"td p[style*='left']"<br>"td div[style*='left']"<br>"td" | (No current examples) |
| **field_content_sequential** | element_selector:<br>pattern_type:<br>start_index: | ".field-content", ".bio-item"<br>"sequential_every_3"<br>3, 1, 5 (number) | FAC-939 Holland Bloorview |
| **nested_list_with_ids** | name_selector:<br>title_selector:<br>container: | "div[id^='t-']", "#name-"<br>"span[id^='d-']", "#title-"<br>"li.column" (optional) | FAC-827 Baycrest |
| **qch_mixed_tables** | table_type:<br>name_table_selector:<br>title_table_selector: | "two_table_format"<br>"table:nth-of-type(1)"<br>"table:nth-of-type(2)" | FAC-777 Queensway Carleton |
| **p_with_bold_and_br** | container_element:<br>name_format:<br>separator: | "p", "div"<br>"bold_text" (in <strong>)<br>"br" | FAC-975 Wingham |
| **manual_entry_required** | reason:<br>manual_people: | "site_blocks_scraping"<br>List of name/title pairs | FAC-947 Pembroke<br>FAC-927 Orillia |

---

## Copy-Paste Examples

### Pattern 1: h2_name_h3_title
```yaml
pattern: "h2_name_h3_title"
html_structure:
  name_element: "h2"
  title_element: "h3"
```

### Pattern 2: combined_h2
```yaml
pattern: "combined_h2"
html_structure:
  combined_element: "h2"
  separator: " - "
```

### Pattern 3: table_rows
```yaml
pattern: "table_rows"
html_structure:
  structure_type: "table"
  name_location: "td_column_1"
  title_location: "td_column_2"
```

### Pattern 4: h2_name_p_title
```yaml
pattern: "h2_name_p_title"
html_structure:
  name_element: "h2"
  title_element: "p"
```

### Pattern 5: div_classes
```yaml
pattern: "div_classes"
html_structure:
  name_class: "staff-name"
  title_class: "staff-title"
  container_class: "staff-member"
```

### Pattern 6: list_items
```yaml
pattern: "list_items"
html_structure:
  list_type: "ul"
  format: "combined"
  separator: " | "
```

### Pattern 7: boardcard_gallery
```yaml
pattern: "boardcard_gallery"
html_structure:
  container_class: "boardcard"
  text_format: "name_comma_title"
  separator: ","
```

### Pattern 8: custom_table_nested
```yaml
pattern: "custom_table_nested"
html_structure:
  structure_type: "table_with_nested_elements"
  name_selector: "td p[style*='text-align: left']"
  title_selector: "td div[style*='text-align: left']"
  container: "td"
```

### Pattern 9: field_content_sequential
```yaml
pattern: "field_content_sequential"
html_structure:
  element_selector: ".field-content"
  pattern_type: "sequential_every_3"
  start_index: 3
```

### Pattern 10: nested_list_with_ids
```yaml
pattern: "nested_list_with_ids"
html_structure:
  name_selector: "div[id^='t-']"
  title_selector: "span[id^='d-']"
  container: "li.column"
```

### Pattern 11: qch_mixed_tables
```yaml
pattern: "qch_mixed_tables"
html_structure:
  table_type: "two_table_format"
  name_table_selector: "table:nth-of-type(1)"
  title_table_selector: "table:nth-of-type(2)"
```

### Pattern 12: p_with_bold_and_br
```yaml
pattern: "p_with_bold_and_br"
html_structure:
  container_element: "p"
  name_format: "bold_text"
  separator: "br"
```

### Pattern 13: manual_entry_required
```yaml
pattern: "manual_entry_required"
html_structure:
  reason: "site_blocks_scraping"
missing_people:
  - name: "John Smith"
    title: "President and CEO"
```

---

## Quick Selection Guide

**Look at the HTML:**
- Same element, combined text? → **combined_h2**
- Different elements in sequence? → **h2_name_h3_title** or **h2_name_p_title**
- Table structure? → **table_rows**
- CSS classes? → **div_classes**
- List with separator? → **list_items**
- Same class repeating? → **field_content_sequential**
- Nothing works? → **manual_entry_required**

---

**Usage:** Find your pattern in the table, scroll down to copy-paste examples, paste into YAML, adjust values to match your HTML.

**Save this file as:** `PATTERN_QUICK_REFERENCE.md` in your `E:/ExecutiveSearchYaml/code/` directory