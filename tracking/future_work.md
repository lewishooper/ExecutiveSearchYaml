# Future Work: Missing People & Manual Entry Resolution

**Last Updated:** 2025-10-16
**Current Status:** 38+ hospitals configured

---

## Philosophy

Use `missing_people` and `manual_entry_required` as temporary solutions during initial configuration. Revisit when patterns emerge from larger dataset (50+ hospitals).

---

## Category 1: Name Pattern Issues âœ…

**Status:** Solvable with regex patterns
**Impact:** ~5-7 hospitals currently
**Priority:** HIGH
**Timeline:** Address during next batch

### Description
Names don't match existing regex patterns in `name_patterns` section of enhanced_hospitals.yaml.

### Examples Already Fixed
- Lowercase "van" (Charmaine van Schaik, MD) â†’ Added pattern: `^[A-Z][a-z]+ van [A-Z][a-z]+, [A-Z]{2,}$`
- Accented names (AndrÃ©, MÃ©lanie) â†’ Added Unicode patterns
- Internal capitals (McDonald, O'Brien, VanSlyke) â†’ Added patterns

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
```r# Test a hospital after adding name pattern
FAC <- 726  # Example
quick_test(FAC)
```

---

## Category 2: Single Source of Truth for Configuration ⚠️

**Status:** Code duplication issue
**Impact:** All hospitals (maintenance burden)
**Priority:** MEDIUM
**Timeline:** Before production/maintenance mode

### Description
Executive title keywords and name validation patterns are currently maintained in TWO separate locations, creating sync issues and maintenance overhead:

1. **enhanced_hospitals.yaml** (lines 1473-1568)
   - `executive_titles` section (primary, secondary, medical_specific)
   - `name_patterns` section (standard, with_titles, with_credentials, etc.)
   - **Purpose:** Reference documentation for human configuration
   - **Usage:** Passive reference only
   - **More comprehensive** but not actively used by scraper

2. **pattern_based_scraper.R** 
   - `executive_keywords` hardcoded in `is_executive_title()` function
   - `name_patterns` pulled from YAML config (already centralized)
   - **Purpose:** Active filtering during scraping
   - **Usage:** Real-time validation to determine if title is executive-level
   - **Must stay current** or executives get filtered out

### Recent Example of the Problem
- **FAC-862** (Toronto Women's College) was missing 2 executives
- Both had "Strategic Lead" titles
- "Strategic Lead" was in YAML reference but NOT in R code keywords
- Fix required manual addition to `pattern_based_scraper.R`
- This type of sync issue will continue without centralization

### Recommended Solution
Modify `pattern_based_scraper.R` to read executive keywords directly from enhanced_hospitals.yaml instead of hardcoding them:

**Current approach:**
```r
# Hardcoded in pattern_based_scraper.R
executive_keywords <- c(
  "CEO", "Chief", "President", "Vice President", "VP", 
  "Director", "Officer", "Administrator", "Manager", 
  "Chair", "Vice-Chair", "Vice Chair",
  "Medical Staff", "Nursing Executive", "CNE",
  "Supervisor", "Health System Executive",
  "Strategic Lead"  # Had to manually add this
)
```

**Proposed approach:**
```r
# Read from YAML config (single source of truth)
executive_keywords <- c(
  config$executive_titles$primary,
  config$executive_titles$secondary,
  config$executive_titles$medical_specific
)
```

### Benefits
1. **Single maintenance point** - Update only YAML file
2. **No sync issues** - Keywords automatically available to all patterns
3. **Easier updates** - Add new title types without touching R code
4. **Better documentation** - YAML structure shows title categories clearly
5. **Reduced errors** - Can't forget to sync between files

### Implementation Complexity
- **Low** - Name patterns already read from YAML successfully
- **Pattern already established** - Just extend existing config reading
- **Minimal code changes** - One modification in scraper initialization
- **No hospital reconfigs needed** - Transparent to existing configs

### Action Items
- [ ] Modify `PatternBasedScraper()` initialization to read executive_titles from config
- [ ] Update `is_executive_title()` to use config-based keywords instead of hardcoded
- [ ] Test with representative hospitals from each pattern type
- [ ] Document the change in code comments
- [ ] Remove hardcoded executive_keywords list
- [ ] Update any documentation that references keyword maintenance

### Testing Plan
```r
# Test hospitals that use title filtering heavily
test_hospitals <- c(
  862,  # Women's College (Strategic Lead issue)
  684,  # Alexandra (board member filtering)
  656,  # WHCA (combined board/executive page)
  # Add 3-5 more from different patterns
)

for (fac in test_hospitals) {
  cat("\nTesting FAC", fac, "\n")
  result <- quick_test(fac)
  # Verify same results as before change
}
```

### Related Improvements
- Consider also centralizing invalid_title_patterns (currently hardcoded)
- Consider centralizing non_names patterns (currently hardcoded)
- All filtering logic could reference YAML config for easier maintenance

---

