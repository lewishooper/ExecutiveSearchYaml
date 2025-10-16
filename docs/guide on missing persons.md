# Future Work - Quick Reference

## When to Use What

### ✅ Use `missing_people` when:
- Pattern WORKS for most executives
- Only 1-3 people missing
- Names don't match regex patterns
- Add under `html_structure:`
```yaml
html_structure:
  name_class: "name"
  title_class: "title"
  missing_people:
    - name: "John Smith"
      title: "CEO"
```

### ✅ Use `manual_entry_required` when:
- Pattern DOESN'T work at all
- JavaScript-loaded content
- Site blocks scraping (403)
- Titles in prose paragraphs
```yaml
pattern: "manual_entry_required"
status: "blocked_by_site"  # or "javascript_blocked" or "manual_entry"
known_executives:
  - name: "John Smith"
    title: "CEO"
```

## Action Thresholds

| Count | Action |
|-------|--------|
| 1-2 | Document, use temp solution |
| 3-4 | Investigate pattern |
| 5+ | Build new pattern/solution |
| 10+ | HIGH PRIORITY |

## Monthly Tasks
- [ ] Run test_all_configured_hospitals()
- [ ] Check manual_entry hospitals for updates
- [ ] Update known_executives if changed
- [ ] Review FUTURE_WORK.md status

## Quarterly Tasks  
- [ ] Review all missing_people entries
- [ ] Add new name_patterns for common issues
- [ ] Re-test affected hospitals
- [ ] Update tracking spreadsheet
- [ ] Check if thresholds reached

## See Full Documentation
- FUTURE_WORK.md - Complete details
- FUTURE_WORK_TRACKING.xlsx - Tracking data