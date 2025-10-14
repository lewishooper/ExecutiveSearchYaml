# Hospital Scraper - SIMPLIFIED Workflow

## 🎯 Key Insight

**Work directly in `enhanced_hospitals.yaml` from the start!**

There's no need to maintain separate configs in two files. Use `next_batch_template.yaml` as a **reference list only**, then configure and test everything directly in the main file.

---

## ✅ THE SIMPLIFIED WORKFLOW

### Daily Process

```r
# === STEP 1: START SESSION ===
setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")

# === STEP 2: PICK A HOSPITAL ===
# Look at next_batch_template.yaml to see what needs configuring

# === STEP 3: CONFIGURE DIRECTLY IN enhanced_hospitals.yaml ===
# Copy the hospital template from next_batch to enhanced_hospitals.yaml
# OR just create a new entry directly in enhanced_hospitals.yaml

# === STEP 4: TEST IMMEDIATELY ===
quick_test(665)  # Uses enhanced_hospitals.yaml with all name_patterns

# === STEP 5: FIX AND ITERATE ===
# Make changes directly in enhanced_hospitals.yaml
quick_test(665)  # Test again
# Repeat until working

# === STEP 6: MARK COMPLETE ===
# Update Excel with done='y'
# Optionally remove from next_batch_template.yaml
```

---

## 📋 Why This Is Better

### Old Workflow Problems:
❌ Maintain configs in two files  
❌ `test_next_batch.R` doesn't have name_patterns  
❌ Need to copy name_patterns to next_batch  
❌ Need merge script to move configs  
❌ Risk of configs getting out of sync  
❌ Extra complexity with status tracking  

### New Workflow Benefits:
✅ **One source of truth** - only `enhanced_hospitals.yaml`  
✅ **All patterns available** - name_patterns already there  
✅ **Familiar commands** - use `quick_test(FAC)` you already know  
✅ **No syncing** - no merge needed  
✅ **Simpler** - fewer scripts, less confusion  
✅ **Faster** - configure and test immediately  

---

## 📝 Step-by-Step Example

### Configuring FAC-665 (Guelph General)

**1. Look at next_batch_template.yaml:**
```yaml
- FAC: "665"
  name: "GUELPH GENERAL"
  url: "https://www.gghorg.ca/about-ggh/leadership-team/"
  pattern: "combined_h2"  # Update as needed
  expected_executives: 6
  html_structure:
    combined_element: "h2"
    separator: ", "
  status: "needs_testing"
```

**2. Copy this to enhanced_hospitals.yaml:**

Open `enhanced_hospitals.yaml` and add at the end:

```yaml
hospitals:
  # ... existing hospitals ...
  
  - FAC: "665"
    name: "GUELPH GENERAL"
    url: "https://www.gghorg.ca/about-ggh/leadership-team/"
    pattern: "combined_h2"
    expected_executives: 6
    html_structure:
      combined_element: "h2"
      separator: ", "
    status: "needs_testing"
```

**3. Test immediately:**
```r
quick_test(665)
```

**4. Fix any issues in enhanced_hospitals.yaml and test again:**
```r
quick_test(665)
```

**5. When working, update status:**
```yaml
status: "ok"  # or "configured"
```

**6. Mark in Excel as done='y'**

Done! Move to next hospital.

---

## 🔧 Using next_batch_template.yaml

### What It's Good For:

1. **Reference list** of hospitals that need configuration
2. **URL tracking** for hospitals
3. **Initial notes** about patterns/structure
4. **Progress tracking** (which are done)

### What It's NOT For:

❌ Active testing  
❌ Maintaining full configurations  
❌ Source of truth for patterns  

### How to Use It:

Think of `next_batch_template.yaml` as your **TODO list** and **scratch pad**:

- Look at it to see what needs work
- Copy basic info from it
- Add notes about what you discover
- Mark status as you complete hospitals
- **But do all real work in enhanced_hospitals.yaml**

---

## 📊 File Purposes Clarified

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `enhanced_hospitals.yaml` | **Master configuration** - all hospitals | Every time you configure/test |
| `next_batch_template.yaml` | **TODO list** - tracking next batch | Reference only, rarely update |
| Excel master file | **Progress tracking** - done='y' marks | After each hospital completes |

---

## 🚀 Complete Session Example

```r
# Morning: Configure 5 hospitals

setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")

# Check project status
source("project_status.R")

# Look at next_batch_template.yaml - pick FAC-665

# Add FAC-665 to enhanced_hospitals.yaml
# (manually edit the file)

# Test it
quick_test(665)
# Output: Names rejected - need to check separator

# Fix separator in enhanced_hospitals.yaml
# Change from " - " to ", "

# Test again
quick_test(665)
# Output: Works! 6 executives found

# Update status in enhanced_hospitals.yaml to "ok"

# Mark in Excel as done='y'

# Repeat for next hospital...
```

---

## 🛠️ Essential Commands

### Session Management
```r
setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")      # Start
source("project_status.R")       # Check status
source("session_shutdown.R")     # End session
```

### Configuration Help
```r
# Analyze hospital structure
helper$analyze_hospital_structure(665, "Guelph General", "URL")
```

### Testing
```r
quick_test(665)                  # Test single hospital
test_all_configured_hospitals()  # Test all hospitals
```

### No More Need For:
~~source("test_next_batch.R")~~ - Not needed  
~~source("merge_tested_to_enhanced.R")~~ - Not needed  
~~merge_tested()~~ - Not needed  

---

## 📈 Tracking Progress

### Check What's Done:
```r
source("project_status.R")
```

Shows:
- Total hospitals configured
- Pattern distribution
- Status breakdown

### Check What's Left:
Open `next_batch_template.yaml` and look for hospitals without status='ok'

Or check Excel for rows where done != 'y'

---

## 💡 Pro Tips

### 1. Use helper$analyze_hospital_structure() First
Before configuring, analyze the HTML:
```r
helper$analyze_hospital_structure(665, "Name", "URL")
```

### 2. Copy Similar Hospital Configs
If a new hospital looks like an existing one, copy that config and modify:
```yaml
# FAC-941 works great with combined_h2
# Copy it and change FAC, name, URL, expected_executives
```

### 3. Test Immediately After Configuring
Don't configure 10 hospitals before testing. Configure one, test it, fix it, then move on.

### 4. Keep Backups
The system creates automatic backups in `E:/ExecutiveSearchYaml/backups/`

Make manual backups before big changes:
```r
file.copy("enhanced_hospitals.yaml", 
          "enhanced_hospitals_backup_20251013.yaml")
```

### 5. Use Pattern Registry
When stuck, check `PATTERN_REGISTRY.md` for examples of all 13 patterns.

---

## 🐛 Troubleshooting

### "Names being rejected with matches_pattern=FALSE"
**Cause:** The name_patterns in enhanced_hospitals.yaml don't cover this name style  
**Fix:** Add appropriate pattern to the global name_patterns section

### "No executives found"
**Cause:** Wrong pattern, wrong elements, or wrong separator  
**Fix:** 
1. Run helper$analyze_hospital_structure()
2. Check actual HTML structure
3. Update pattern and html_structure
4. Test again

### "Found more/fewer than expected"
**Cause:** expected_executives count is wrong  
**Fix:** Update expected_executives to match reality

### "Cannot open connection"
**Cause:** Website temporarily down or blocking  
**Fix:** Wait and try again, or check if URL changed

---

## 📁 File Structure

```
E:/ExecutiveSearchYaml/
├── code/
│   ├── enhanced_hospitals.yaml          ← WORK HERE (main config)
│   ├── next_batch_template.yaml         ← Reference only (TODO list)
│   ├── pattern_based_scraper.R
│   ├── quick_test_single.R
│   ├── test_all_configured_hospitals.R
│   ├── hospital_configuration_helper.R
│   └── session_startup.R
├── backups/
│   └── enhanced_hospitals_*.yaml        ← Automatic backups
└── output/
    └── hospital_executives_*.csv        ← Results
```

---

## 🎯 Daily Goals

**Realistic:** 5-10 hospitals per day
- ~10-15 minutes per hospital
- Configure, test, fix, verify
- Mark as done in Excel

**This Batch (30 hospitals):** 3-6 days to complete

**Total Project (100+ hospitals):** Complete in 2-3 weeks of focused work

---

## ✅ Checklist for Each Hospital

- [ ] Look up hospital in next_batch_template.yaml
- [ ] Run helper$analyze_hospital_structure()
- [ ] Add configuration to enhanced_hospitals.yaml
- [ ] Test with quick_test(FAC)
- [ ] Fix any issues
- [ ] Test again until working
- [ ] Update status to "ok" in enhanced_hospitals.yaml
- [ ] Mark done='y' in Excel
- [ ] Move to next hospital

---

## 🔄 What About the Merge Scripts?

The merge scripts (`test_next_batch.R` and `merge_tested_to_enhanced.R`) are still available if you want to use that workflow, but they're **not recommended** because:

1. Extra complexity
2. Configs in two places
3. Missing name_patterns issue
4. Need to sync changes

**Better approach:** Work directly in enhanced_hospitals.yaml

---

## 📚 Related Documentation

- **PATTERN_REGISTRY.md** - All scraping patterns with examples
- **Hospital Configuration Workflow Guide.md** - Detailed configuration guide
- **SESSION_LOG.md** - Project history and notes
- **QUICK_REFERENCE.md** - Quick command reference

---

## 🎊 Summary

### The Simplified Workflow:

1. **Reference** next_batch_template.yaml to see what needs work
2. **Configure** directly in enhanced_hospitals.yaml
3. **Test** with quick_test(FAC)
4. **Iterate** until working
5. **Mark** done in Excel
6. **Repeat** for next hospital

### No More:
- ❌ Syncing between files
- ❌ Merge scripts
- ❌ Duplicate name_patterns
- ❌ Status tracking in two places

### Benefits:
- ✅ Single source of truth
- ✅ Simpler workflow
- ✅ Faster iteration
- ✅ Less confusion
- ✅ Fewer errors

**Just work in enhanced_hospitals.yaml and test with quick_test(FAC). That's it!**

---

**Last Updated:** 2025-10-13  
**Version:** 2.0 - Simplified Workflow (Work Directly in Enhanced)