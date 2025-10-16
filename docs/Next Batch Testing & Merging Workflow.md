# Next Batch Testing & Merging Workflow

## Overview

This workflow ensures safe testing and merging of hospitals from `next_batch_template.yaml` to `enhanced_hospitals.yaml` **without losing any configured hospitals**.

---

## Key Safety Features

1. **Automatic Backups**: Every merge creates a timestamped backup in `E:/ExecutiveSearchYaml/backups/`
2. **Duplicate Protection**: Won't overwrite existing hospitals by default
3. **Status-Based Merging**: Only merges hospitals marked as 'ok', 'configured', or 'tested_ok'
4. **Confirmation Required**: Interactive confirmation before making changes (unless using auto mode)
5. **Restore Capability**: Can restore from any backup if needed

---

## Complete Workflow

### Step 1: Initial Setup (Once per session)

```r
setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")
```

### Step 2: Check Next Batch Status

```r
source("test_next_batch.R")
status_next()
```

This shows:
- Total hospitals in next_batch
- Status breakdown
- How many need URLs
- How many are ready to test
- How many are ready to merge

### Step 3: Configure Hospitals (As Needed)

For each hospital that needs configuration:

```r
# Analyze the structure
helper$analyze_hospital_structure(FAC, "Name", "URL")

# Edit next_batch_template.yaml to:
# - Set correct pattern
# - Update html_structure
# - Set expected_executives
# - Change status to "needs_testing"
```

### Step 4: Test Individual Hospitals

```r
# Test a single hospital
quick_test_next(FAC)

# If successful, mark as OK
mark_ok(FAC)

# Or mark as configured
mark_configured(FAC)
```

**Example:**
```r
quick_test_next(981)
# Review results...
mark_ok(981)
```

### Step 5: Test All Ready Hospitals

```r
# Test all hospitals with status="needs_testing"
results <- test_ready()
```

This will:
- Test each hospital automatically
- Display results for each
- Create a summary table
- Show which passed/failed

**After testing:**
- Update status to 'ok' for passing hospitals
- Fix configuration for failing hospitals

### Step 6: Merge Tested Hospitals to Enhanced

```r
source("merge_tested_to_enhanced.R")

# Interactive merge (with confirmation)
merge_tested()

# Or automatic merge (no confirmation)
merge_auto()
```

**The merge will:**
1. Create automatic backup of enhanced_hospitals.yaml
2. Find all hospitals with status: 'ok', 'configured', or 'tested_ok'
3. Check for duplicates
4. Show what will be merged
5. Ask for confirmation (unless using merge_auto)
6. Add new hospitals to enhanced_hospitals.yaml
7. Skip duplicates (existing hospitals are preserved)

### Step 7: Verify Merge

```r
source("project_status.R")
```

Check that:
- Hospital count increased correctly
- No duplicates created
- All patterns still represented

### Step 8: Update Excel Master List

Mark completed hospitals with `done='y'` in:
`E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx`

---

## Quick Reference Commands

### Testing Commands
```r
source("test_next_batch.R")

status_next()                    # Show next batch status
quick_test_next(FAC)             # Test single hospital
test_ready()                     # Test all ready hospitals
mark_ok(FAC)                     # Mark as OK after testing
mark_configured(FAC)             # Mark as configured
```

### Merging Commands
```r
source("merge_tested_to_enhanced.R")

merge_tested()                   # Interactive merge with confirmation
merge_auto()                     # Automatic merge (no confirmation)
restore_from_backup()            # Restore from backup if needed
```

### Status Commands
```r
source("project_status.R")       # Show full project status
```

---

## Typical Daily Workflow

### Morning: Configure & Test

```r
# 1. Start session
setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")

# 2. Check what needs work
source("test_next_batch.R")
status_next()

# 3. Work on 5-10 hospitals
# For each hospital:
quick_test_next(FAC)             # Test
mark_ok(FAC)                     # Mark if successful

# 4. Or test all at once
results <- test_ready()
# Then update statuses for passing hospitals
```

### Afternoon: Merge & Continue

```r
# 5. Merge completed hospitals
source("merge_tested_to_enhanced.R")
merge_tested()

# 6. Verify
source("project_status.R")

# 7. Continue with next hospitals
status_next()
```

---

## Status Values Explained

### In next_batch_template.yaml:
- **needs_url**: Hospital entry exists but URL is TODO
- **needs_testing**: Configured and ready to test
- **ok**: Tested successfully, ready to merge
- **configured**: Fully configured, ready to merge
- **tested_ok**: Tested and confirmed working
- **needs_work**: Failed testing, needs configuration fixes
- **closed**: Hospital closed/merged, skip

### Only 'ok', 'configured', and 'tested_ok' will be merged!

---

## Safety Checks

### Before Testing:
✅ URL is not "TODO"  
✅ Pattern is set correctly  
✅ html_structure matches the website  
✅ expected_executives is reasonable  

### Before Merging:
✅ Hospitals passed testing  
✅ Status updated to 'ok' or 'configured'  
✅ Backup will be created automatically  
✅ Duplicates will be skipped (not overwritten)  

### After Merging:
✅ Run `source("project_status.R")` to verify  
✅ Check hospital counts make sense  
✅ Backup exists in backups/ folder  

---

## Troubleshooting

### "No hospitals ready to merge"
- Check that hospitals have status='ok', 'configured', or 'tested_ok'
- Run `status_next()` to see status breakdown

### "Hospital failed test"
- Review the pattern and html_structure
- Use `helper$analyze_hospital_structure(FAC, "Name", "URL")`
- Compare with similar working hospitals in enhanced_hospitals.yaml
- Check PATTERN_REGISTRY.md for examples

### "Duplicate FAC found"
- The merge script will skip duplicates by default (safe!)
- If you want to UPDATE an existing hospital, use skip_duplicates=FALSE
- Or manually update in enhanced_hospitals.yaml

### "Need to restore from backup"
```r
source("merge_tested_to_enhanced.R")
restore_from_backup()  # Shows list of backups to choose from
```

---

## File Organization

```
E:/ExecutiveSearchYaml/
├── code/
│   ├── enhanced_hospitals.yaml          # MAIN CONFIG (34 hospitals)
│   ├── next_batch_template.yaml         # WORK IN PROGRESS (30 hospitals)
│   ├── test_next_batch.R                # Testing tools
│   ├── merge_tested_to_enhanced.R       # Merging tools
│   └── ...
├── backups/
│   ├── enhanced_hospitals_20251013_105201.yaml
│   ├── enhanced_hospitals_20251013_141532.yaml
│   └── ...
└── output/
    └── hospital_executives_YYYYMMDD.csv
```

---

## Best Practices

1. **Test incrementally**: Test 5-10 hospitals at a time, not all 30 at once
2. **Merge frequently**: Merge successful hospitals daily to avoid losing work
3. **Keep backups**: Backups are created automatically, but keep at least 3-5 recent ones
4. **Update Excel**: Mark hospitals as done='y' after merging to track progress
5. **Run project_status.R**: After each merge to verify everything looks correct
6. **Use status_next()**: Before and after testing to track batch progress

---

## Example Session

```r
# === MORNING SESSION ===

setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R")

# Check what's ready
source("test_next_batch.R")
status_next()
# Output: "5 hospitals ready to test"

# Test them all
results <- test_ready()
# Review results, 4 passed, 1 failed

# Mark the passing ones
mark_ok(981)
mark_ok(983)
mark_ok(985)
mark_ok(988)

# Fix the failing one (990) - not shown here

# === AFTERNOON SESSION ===

# Merge the successful ones
source("merge_tested_to_enhanced.R")
merge_tested()
# Confirms: Adding 4 hospitals, backup created

# Verify
source("project_status.R")
# Shows: 38 configured hospitals (was 34)

# Check next batch progress
status_next()
# Shows: 4 completed, 1 needs_work, 25 remaining

# Update Excel with done='y' for completed hospitals

# Continue with next batch...
```

---

## Quick Troubleshooting Checklist

**Hospital test fails:**
- [ ] Is URL correct and accessible?
- [ ] Is pattern correct for this hospital?
- [ ] Does html_structure match the website HTML?
- [ ] Is expected_executives count realistic?
- [ ] Are there special characters in names (check normalize_name)?

**Merge doesn't include hospital:**
- [ ] Is status set to 'ok', 'configured', or 'tested_ok'?
- [ ] Is hospital in next_batch_template.yaml?
- [ ] Run status_next() to confirm ready to merge

**Lost configured hospitals:**
- [ ] This shouldn't happen! Merge script protects existing hospitals
- [ ] Check backups folder
- [ ] Run restore_from_backup()
- [ ] Report issue so we can investigate

---

## Summary

This workflow provides a **safe, systematic process** for:
1. Testing hospitals in next_batch_template.yaml
2. Merging successful hospitals to enhanced_hospitals.yaml
3. Never losing already configured hospitals
4. Always having backups available

**Key principle**: Only merge hospitals that have been tested and marked with appropriate status. The system protects your existing work!