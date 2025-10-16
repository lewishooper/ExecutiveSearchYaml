# Future Work: Missing People & Manual Entry Resolution

**Last Updated:** 2025-10-16
**Current Status:** 38+ hospitals configured

---

## Philosophy

Use `missing_people` and `manual_entry_required` as temporary solutions during initial configuration. Revisit when patterns emerge from larger dataset (50+ hospitals).

---

## Category 1: Name Pattern Issues ✅

**Status:** Solvable with regex patterns
**Impact:** ~5-7 hospitals currently
**Priority:** HIGH
**Timeline:** Address during next batch

### Description
Names don't match existing regex patterns in `name_patterns` section of enhanced_hospitals.yaml.

### Examples Already Fixed
- Lowercase "van" (Charmaine van Schaik, MD) → Added pattern: `^[A-Z][a-z]+ van [A-Z][a-z]+, [A-Z]{2,}$`
- Accented names (André, Mélanie) → Added Unicode patterns
- Internal capitals (McDonald, O'Brien, VanSlyke) → Added patterns

### Hospitals Using `missing_people` for Name Issues
- **FAC-726** (Georgian Bay): 2 people
  - Dr. Vikram Ralhan
  - Linda Gravel
- **FAC-953** (Sunnybrook): 3 people
  - Dr. Calvin Law, MD, FRCSC, MPH
  - Kullervo Hynynen, Ph.D.
  - Dr. Dan Cass B.Sc., MD, MSc, FRCPC
- **FAC-976** (Sinai Health): 2 people
  - Louis de Melo
  - Dr. Anne-Claude Gingras

### Action Items
- [ ] Review all `missing_people` entries in enhanced_hospitals.yaml
- [ ] For each entry, determine if it's a name pattern issue
- [ ] Extract the name format and create regex pattern
- [ ] Add pattern to appropriate section in `name_patterns`
- [ ] Re-test with `quick_test(FAC)` to confirm automatic detection
- [ ] Remove from `missing_people` once working

### Testing Script
```r