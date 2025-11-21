
# Hospital Scraper - Pattern Quick Reference Guide
★ **UPDATED: Added 'reversed' Parameter Support (Oct 2025)** ★

*Generated from enhanced_hospitals.yaml | Total Patterns: 13 | Total Hospitals: 62*

## Pattern Overview

| Pattern | HTML Structure Items | Elements in the Structure | FAC & Hospital Examples |
|---------|---------------------|--------------------------|-------------------------|
| `combined_h2`<br>NEW: reversed support | `combined_element:`<br>`separator:`<br>`reversed: true/false`<br>`notes:` | p, h2, h3, span<br>:, \|, ,, " - "<br>**NEW: Use 'reversed: true' for Title:Name format**<br>Combined text with separator | FAC-665 GUELPH GENERAL (normal)<br>FAC-941 CHATHAM-KENT (normal)<br>FAC-967 CORNWALL COMMUNITY (reversed)<br>FAC-600 ATIKOKAN GENERAL |
| `h2_name_p_title`<br>NEW: reversed support | `name_element:`<br>`title_element:`<br>`reversed: true/false`<br>`notes:` | h2, h3, p<br>p, h3, h4<br>**NEW: Use 'reversed: true' for Title→Name sequence**<br>Sequential elements with name then title (or reversed) | FAC-646 DEEP RIVER (reversed)<br>FAC-965 SAULT STE MARIE (normal)<br>FAC-962 ST CATHARINES NIAGARA (normal)<br>FAC-953 HANOVER (normal) |
| `boardcard_gallery` | `container_class:`<br>`text_format:`<br>`separator:`<br>`notes:` | boardcard<br>name_comma_title<br>,<br>Gallery of senior leaders | FAC-935 THUNDER BAY REGIONAL |
| `div_classes` | `name_class:`<br>`title_class:`<br>`container_class:`<br>`notes:` | name, tm-name, title<br>position, tm-primary-title<br>team-member, staff-member<br>CSS class-based extraction | FAC-931 PARRY SOUND WEST PARRY<br>FAC-745 ORILLIA SOLDIERS'<br>FAC-736 NEWMARKET SOUTHLAKE<br>FAC-699 KITCHENER ST MARY'S |
| `field_content_sequential` | `element_selector:`<br>`pattern_type:`<br>`start_index:`<br>`notes:` | .field-content<br>sequential_every_3<br>3<br>Sequential field elements | FAC-939 TORONTO HOLLAND BLOORVIEW |
| `h2_combined_complex` | `notes:` | Complex H2 with name, credentials, and title combined | FAC-975 MISSISSAUGA TRILLIUM |
| `h2_name_h3_title` | `name_element:`<br>`title_element:`<br>`notes:` | h2<br>h3<br>Sequential H2→H3 pattern | FAC-940 COBOURG NORTHUMBERLAND<br>FAC-605 TORONTO ST. JOSEPH'S<br>FAC-707 ROSS MEMORIAL |
| `list_items` | `list_type:`<br>`format:`<br>`separator:`<br>`notes:` | ul, ol<br>combined<br>\|, ,<br>List items with separator | FAC-930 WRHN-KITCHENER GRAND RIVER<br>FAC-957 BELLEVILLE QUINTE<br>FAC-790 ST CATHARINES HOTEL DIEU |
| `manual_entry_required` | `notes:`<br>`executives:` | For blocked sites or irregular structures<br>Manual list of name/title pairs | FAC-966 SARNIA BLUEWATER<br>FAC-950 HALTON HEALTHCARE<br>FAC-916 HEADWATERS (convertible) |
| `nested_list_with_ids` | `name_selector:`<br>`title_selector:`<br>`container_class:`<br>`notes:` | span.name, div[id^='t-']<br>span.position, span[id^='d-']<br>li.column<br>ID or class-based selectors | FAC-718 BURLINGTON JOSEPH BRANT<br>FAC-701 RICHMOND HILL MACKENZIE<br>FAC-827 PETERBOROUGH REGIONAL |
| `p_with_bold_and_br` | `container_selector:`<br>`notes:` | p<br>strong, p b<br>Bold name with BR separator for title | FAC-660 WINDSOR REGIONAL |
| `qch_mixed_tables` | `notes:` | Mixed table formats with varying structures | FAC-777 QUINTE HEALTHCARE |
| `table_rows` | `name_column:`<br>`title_column:`<br>`notes:` | 1, 2 (varies)<br>2, 3 (varies)<br>Standard table with name/title in columns | FAC-661 NORTH BAY<br>FAC-781 OWEN SOUND |
| `custom_table_nested` | `table_selector:`<br>`notes:` | Complex nested table structure | FAC-971 SCARBOROUGH HEALTH NETWORK |

## NEW FEATURE: Reversed Parameter

The 'reversed' parameter is now available for `combined_h2` and `h2_name_p_title` patterns.

Use `reversed: true` when the title appears before the name in the HTML.

### Examples:

- **combined_h2 reversed**: `<p>President & CEO:John Smith</p>` (Title:Name)
- **h2_name_p_title reversed**: `<p>CEO</p><p>John Smith</p>` (Title→Name)

Defaults to `false` for backward compatibility. All existing hospitals continue working unchanged.

---

**Generated**: October 2025 | **Version**: 1.1 | **Hospitals Automated**: 62 | **Manual**: 11 (15.1%) | **Reversed Parameter**: 2 hospitals (FAC-646, FAC-967)

