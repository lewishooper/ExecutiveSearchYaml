# Hospital Scraper - Pattern Quick Reference Guide

| **Pattern** | **HTML Structure Items (copy/paste into YAML)** | **Elements in the Structure** | **FAC & Hospital Examples** |
|-------------|------------------------------------------------|-------------------------------|----------------------------|
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
| **p_with_bold_and_br** | container_element:<br>name_format:<br>separator: | "p", "div"<br>"bold_text" (in strong)<br>"br" | FAC-975 Wingham |
| **manual_entry_required** | reason:<br>manual_people: | "site_blocks_scraping"<br>List of name/title pairs | FAC-947 Pembroke<br>FAC-927 Orillia |

**Print in landscape mode for best viewing**