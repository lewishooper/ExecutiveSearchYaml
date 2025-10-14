# Hospital Scraper - Quick Reference Card (SIMPLIFIED)

## 🚀 SESSION STARTUP

```r
setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")
```

---

## 📊 STATUS CHECK

```r
source("project_status.R")       # Full project status
```

---

## 🔧 THE WORKFLOW

### Simple 5-Step Process:

```r
# 1. Check what needs work
# Look at next_batch_template.yaml (reference list)

# 2. Analyze hospital structure
helper$analyze_hospital_structure(FAC, "Name", "URL")

# 3. Add config to enhanced_hospitals.yaml
# (manually edit the file)

# 4. Test immediately
quick_test(FAC)

# 5. Fix and repeat until working
# Edit enhanced_hospitals.yaml
quick_test(FAC)
# Mark done='y' in Excel when complete
```

---

## 🧪 TESTING COMMANDS

```r
quick_test(FAC)                  # Test single hospital
test_all_configured_hospitals()  # Test all hospitals
```

---

## 🔍 ANALYSIS COMMANDS

```r
helper$analyze_hospital_structure(FAC, "Name", "URL")
```

---

## 📝 TYPICAL WORKFLOW EXAMPLE

```r
# Configure FAC-665
source("session_startup.R")

# Analyze structure
helper$analyze_hospital_structure(665, "Guelph General", 
                                  "https://www.gghorg.ca/about-ggh/leadership-team/")

# Shows: H2 elements with "Name, Title" format

# Add to enhanced_hospitals.yaml:
# - FAC: "665"
#   name: "GUELPH GENERAL"
#   url: "https://www.gghorg.ca/about-ggh/leadership-team/"
#   pattern: "combined_h2"
#   expected_executives: 6
#   html_structure:
#     combined_element: "h2"
#     separator: ", "
#   status: "needs_testing"

# Test it
quick_test(665)

# If works, update status to "ok" in enhanced_hospitals.yaml
# Mark done='y' in Excel
# Move to next hospital
```

---

## 🎯 KEY FILES

| File | Purpose | When to Use |
|------|---------|-------------|
| `enhanced_hospitals.yaml` | **Master config** | Always - work here! |
| `next_batch_template.yaml` | Reference list | Check what needs work |
| Excel file | Progress tracking | Mark done='y' |

---

## 🛠️ CONFIGURATION TIPS

### Pattern Selection:
- `<h2>Name</h2><h3>Title</h3>` → pattern: "h2_name_h3_title"
- `<h2>Name, Title</h2>` → pattern: "combined_h2", separator: ", "
- `<h2>Name - Title</h2>` → pattern: "combined_h2", separator: " - "
- Table structure → pattern: "table_rows"
- Divs with classes → pattern: "div_classes"

### Common Separators:
- ", " (comma-space)
- " - " (space-dash-space)
- " | " (space-pipe-space)
- " – " (space-endash-space)

---

## 🐛 QUICK TROUBLESHOOTING

| Problem | Solution |
|---------|----------|
| Names rejected (matches_pattern=FALSE) | Add pattern to name_patterns section |
| No executives found | Wrong pattern or separator |
| Found more/fewer than expected | Update expected_executives |
| Cannot open connection | Website down or blocking |

---

## 📋 DAILY CHECKLIST

For each hospital:
- [ ] Check next_batch_template.yaml
- [ ] Run helper$analyze_hospital_structure()
- [ ] Add to enhanced_hospitals.yaml
- [ ] Test with quick_test(FAC)
- [ ] Fix any issues
- [ ] Update status to "ok"
- [ ] Mark done='y' in Excel

---

## 💡 PRO TIPS

1. **Test immediately** - Don't configure 10 before testing
2. **Copy similar configs** - Find working hospital, copy and modify
3. **Use analyze first** - Always check structure before guessing
4. **One file only** - Work in enhanced_hospitals.yaml
5. **Check PATTERN_REGISTRY.md** - Examples of all patterns

---

## 🆘 COMMON PATTERNS

```yaml
# Pattern 1: Sequential different elements
pattern: "h2_name_h3_title"
html_structure:
  name_element: "h2"
  title_element: "h3"

# Pattern 2: Combined in one element
pattern: "combined_h2"
html_structure:
  combined_element: "h2"
  separator: ", "

# Pattern 3: Table
pattern: "table_rows"
html_structure:
  name_column: 1
  title_column: 2

# Pattern 5: Div classes
pattern: "div_classes"
html_structure:
  name_class: "leader-name"
  title_class: "leader-title"
```

---

## 🔄 SESSION WORKFLOW

```r
# Morning
source("session_startup.R")
source("project_status.R")

# Configure 5-10 hospitals
quick_test(FAC)  # for each one

# End of day
source("session_shutdown.R")
```

---

## ⚠️ IMPORTANT NOTES

- **Work in enhanced_hospitals.yaml** - it's the master file
- **next_batch_template.yaml** is just a reference list
- **Don't use merge scripts** - not needed with simplified workflow
- **Test immediately** after configuring each hospital
- **All name_patterns** are in enhanced_hospitals.yaml

---

## 📞 HELP

See detailed docs:
- **SIMPLIFIED_WORKFLOW.md** - Complete workflow guide
- **PATTERN_REGISTRY.md** - All pattern examples
- **SESSION_LOG.md** - Project history

---

**Quick Start:**
```r
setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")
helper$analyze_hospital_structure(FAC, "Name", "URL")
# Add to enhanced_hospitals.yaml
quick_test(FAC)
```

---

**Version:** 2.0 - Simplified (Work Directly in Enhanced)