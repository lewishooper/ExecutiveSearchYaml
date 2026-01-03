# PHASE 3: LONGITUDINAL TRACKING SYSTEM
## Next Steps Following December 1 Baseline

**Version**: 1.0  
**Date**: December 3, 2025  
**Phase Start**: January 2, 2026 (after Jan 1 data collection)  
**Status**: Planning - Awaiting Jan 1 Comparison Data

---

## EXECUTIVE SUMMARY

With the successful December 1, 2025 baseline established, Phase 3 focuses on building the longitudinal tracking infrastructure. This phase transforms our single-snapshot system into a comprehensive personnel movement detection and tracking platform.

**Critical Dependency**: Phase 3 development begins AFTER January 1, 2026 automated run completes, providing the first comparison dataset needed to validate movement detection logic.

---

## PHASE 3 OVERVIEW

### Goals
1. Track personnel changes month-over-month
2. Detect movements across hospitals
3. Identify departures and create alumni tracking
4. Generate actionable notification lists for outreach
5. Build historical employment records for research

### Timeline
- **Jan 2-15, 2026**: Master Personnel Reference system development
- **Jan 15-20, 2026**: Movement detection algorithm implementation
- **Jan 20-25, 2026**: Alumni tracking system
- **Jan 25-31, 2026**: Testing and validation
- **Feb 1, 2026**: Production deployment for February data collection

### Prerequisites (COMPLETED ✓)
- ✓ December 1 baseline files generated
- ✓ Post-processing pipeline operational (`process_hospital_data.R`)
- ✓ Employee/volunteer classification working
- ✓ Priority flagging (CEO, Board Chair) functional
- ✓ Credential extraction operational

### Prerequisites (PENDING)
- ⏳ January 1, 2026 automated scrape completion
- ⏳ January comparison data validated
- ⏳ First real month-over-month changes observed

---

## DEVELOPMENT PLAN

### 3.1 Master Personnel Reference System

**Target File**: `PersonnelMaster.csv`  
**Development Period**: January 2-15, 2026  
**Priority**: HIGH

#### Purpose
Create a comprehensive longitudinal record of every person who appears in the system, tracking their complete employment history across all hospitals and time periods.

#### Data Structure

| Field | Type | Description | Implementation Notes |
|-------|------|-------------|---------------------|
| person_id | character | Unique identifier | Auto-generated: "P" + 8-digit sequential |
| person_name | character | Canonical name | Standardized format from first appearance |
| name_variants | character | Alternate spellings | Comma-separated, populated via fuzzy matching |
| credentials | character | Professional credentials | Extracted during normalization (MD, PhD, RN, etc.) |
| current_hospital | character | Most recent hospital | Updated each run |
| current_title | character | Most recent title | Updated each run |
| current_type | character | "Employee" or "Volunteer" | Updated each run |
| first_seen | Date | First appearance | Set on initial creation, never changes |
| last_seen | Date | Most recent appearance | Updated each run if person found |
| status | character | Current status | See status values below |
| total_appearances | integer | Count of months seen | Incremented each appearance |
| employment_history | text | JSON array of positions | Append-only historical record |

#### Status Values
- **"active"**: Appeared in most recent monthly run
- **"moved"**: Changed hospitals (detected via movement algorithm)
- **"departed"**: Not found in current month, moved to alumni
- **"alumni"**: Confirmed departed, no longer in active tracking

#### Employment History JSON Structure
```json
{
  "positions": [
    {
      "hospital": "Hospital Name",
      "hospital_fac": "FAC001",
      "title": "Chief Executive Officer",
      "person_type": "Employee",
      "priority_flag": true,
      "start_date": "2025-12-01",
      "end_date": "2025-12-01",  // Same as start until movement detected
      "months_in_position": 1,
      "data_quality": "scraped",
      "notes": ""
    }
  ]
}
```

#### Development Tasks

**Task 3.1.1**: Create Master Reference Initialization Function
```r
# Function: initialize_personnel_master()
# Input: December baseline files (employees + volunteers)
# Output: PersonnelMaster_2025-12-01.csv with initial records
# 
# Logic:
# 1. Combine employee and volunteer datasets
# 2. Generate unique person_id for each individual
# 3. Set first_seen = last_seen = "2025-12-01"
# 4. Set status = "active"
# 5. Initialize employment_history JSON with single position
# 6. Calculate total_appearances = 1
```

**Task 3.1.2**: Create Master Reference Update Function
```r
# Function: update_personnel_master(current_data, master_data, run_date)
# Input: 
#   - current_data: Combined employees + volunteers from new run
#   - master_data: Existing PersonnelMaster.csv
#   - run_date: Date of current data collection
# Output: Updated PersonnelMaster_YYYY-MM-DD.csv
#
# Logic:
# 1. Match current_data to master_data using fuzzy matching
# 2. For matched records:
#    a. Update last_seen date
#    b. Update current_hospital, current_title, current_type
#    c. Increment total_appearances
#    d. If hospital changed: flag for movement detection
#    e. If title changed at same hospital: update employment_history
# 3. For unmatched in current_data (new people):
#    a. Create new person_id
#    b. Add to master with first_seen = run_date
# 4. For unmatched in master_data (missing people):
#    a. Keep last_seen unchanged
#    b. Flag for alumni review
```

**Task 3.1.3**: Build Name Matching Algorithm
```r
# Function: fuzzy_match_names(name1, name2, credentials1, credentials2)
# Purpose: Match people across datasets handling name variations
#
# Matching Strategy:
# 1. Normalize both names (remove credentials, standardize spacing)
# 2. Generate name variants:
#    - Full name exact match
#    - First + Last (drop middle names)
#    - Nickname substitutions (Robert→Bob, Elizabeth→Beth, etc.)
#    - Initial variations (J. Smith vs John Smith)
# 3. Calculate Jaro-Winkler similarity for all variants
# 4. Apply credential matching bonus:
#    - Exact credential match: +10 points to similarity
#    - Partial credential match: +5 points
#    - Credential mismatch: -5 points (may be different person)
# 5. Return matches above 85% threshold
# 6. Rank by similarity score
#
# Special Handling for Common Names:
# - If multiple matches >85%, require additional evidence:
#   * Matching credentials (high value)
#   * Similar title/role
#   * Same hospital type
# - Flag ambiguous matches for human review
```

**Task 3.1.4**: Create Nickname Dictionary
```r
# File: name_variants_reference.csv
# Columns: canonical_name, variant_name
# Purpose: Support fuzzy matching with common nicknames
#
# Examples:
# Robert, Bob
# Robert, Rob
# Elizabeth, Beth
# Elizabeth, Liz
# Michael, Mike
# Christopher, Chris
# ... (expand as needed based on actual data)
```

**Testing Requirements**:
- Test with Dec 1 → Jan 1 data comparison
- Validate person_id uniqueness
- Verify employment_history JSON structure
- Test fuzzy matching with known name variations
- Validate credential matching bonus system
- Test with common names (John Smith, etc.)

---

### 3.2 Movement Detection System

**Target File**: `PersonnelMovement_YYYY-MM.csv`  
**Development Period**: January 15-20, 2026  
**Priority**: HIGH

#### Purpose
Automatically detect when personnel move between hospitals or change positions within the same hospital, generating candidates for verification and notification.

#### Movement Types

1. **EXTERNAL MOVE**: Different hospital than previous position
   - Subcategories: lateral, promotion, demotion
   - Detection: hospital_fac changed in master record
   - Confidence: Based on fuzzy match + credential match + title similarity

2. **INTERNAL MOVE**: Same hospital, different title
   - Subcategories: promotion, lateral, title_change
   - Detection: Same hospital_fac, title changed
   - Analysis: Compare title levels using title hierarchy

3. **RETURN TO SYSTEM**: Person in alumni list now back in active data
   - Detection: Status = "alumni" in master, now appears in current data
   - Flag: Calculate tenure gap duration

#### Detection Algorithm

```r
# Function: detect_movements(current_data, previous_month_data, master_data)
#
# Step 1: Identify Changed Records
# - Match current month to previous month using person_id
# - Flag any records where hospital_fac OR title changed
#
# Step 2: Classify Movement Type
# - IF hospital_fac changed → EXTERNAL MOVE
# - IF hospital_fac same AND title changed → INTERNAL MOVE
# - IF person was in alumni → RETURN TO SYSTEM
#
# Step 3: Calculate Confidence Score
# - Base confidence from fuzzy match (0.85-1.0)
# - Bonus for credential match (+0.1)
# - Bonus for title similarity (+0.05)
# - Penalty for common names (-0.1)
# - Penalty for large geographic distance (-0.05)
#
# Step 4: Generate Movement Record
# - person_name, match_confidence
# - movement_type, movement_subtype
# - origin_hospital, origin_title, origin_last_seen
# - destination_hospital, destination_title, destination_first_seen
# - title_level_change (promotion/lateral/demotion)
# - verification_status = "pending"
# - priority_flag (TRUE if CEO or Board Chair position)
```

#### Title Hierarchy for Level Detection

```r
# Create title scoring system for promotion/demotion detection
title_hierarchy <- data.frame(
  title_pattern = c(
    "Chief Executive Officer", "CEO", "President and CEO",
    "Chief Operating Officer", "COO", "Chief Financial Officer", "CFO",
    "Chief Medical Officer", "CMO", "Chief Nursing Officer", "CNO",
    "Vice President", "VP", "Senior Vice President", "SVP",
    "Director", "Senior Director", "Executive Director",
    "Manager", "Senior Manager",
    "Coordinator", "Supervisor",
    "Board Chair", "Chair of the Board",
    "Board Member", "Board Director", "Trustee"
  ),
  level_score = c(
    100, 100, 100,
    90, 90, 90, 90,
    85, 85, 85, 85,
    70, 70, 75, 75,
    60, 65, 65,
    50, 55,
    40, 45,
    95, 95,
    80, 80, 80
  )
)

# Function: classify_title_change(old_title, new_title)
# Returns: "promotion", "lateral", "demotion", or "unclear"
```

#### Development Tasks

**Task 3.2.1**: Build Movement Detection Function
- Implement comparison logic between months
- Create confidence scoring system
- Handle edge cases (same name at multiple hospitals)

**Task 3.2.2**: Create Title Hierarchy Reference
- Build comprehensive title scoring system
- Test with real title variations from Dec/Jan data
- Validate promotion/lateral/demotion classification

**Task 3.2.3**: Build Movement Report Generator
- Create CSV output with all required fields
- Implement priority flagging (CEO/Board Chair only)
- Generate human-readable verification spreadsheet

**Testing Requirements**:
- Test with known movements (if any in Jan 1 data)
- Validate confidence scoring with manual review
- Test false positive rate with common names
- Verify title level detection accuracy

---

### 3.3 Alumni Tracking System

**Target File**: `PersonnelAlumni_YYYY-MM-DD.csv`  
**Development Period**: January 20-25, 2026  
**Priority**: MEDIUM

#### Purpose
Track individuals who have left the system, maintaining their historical records for research and potential re-entry detection.

#### Alumni Criteria
1. Person appeared in previous month's data
2. Person NOT in current month's data (checked across ALL hospitals)
3. Person not flagged as "on leave" or "temporary absence"

#### Alumni Record Structure

| Field | Type | Description |
|-------|------|-------------|
| person_id | character | From master reference |
| person_name | character | Canonical name |
| credentials | character | Professional credentials |
| last_hospital | character | Final hospital |
| last_hospital_fac | character | Final FAC number |
| last_title | character | Final position |
| last_seen_date | Date | Last appearance date |
| first_seen_date | Date | Original entry to system |
| total_tenure_months | integer | Months from first to last seen |
| number_of_positions_held | integer | Count from employment_history |
| highest_title_held | character | Best position ever held |
| highest_title_score | integer | From title hierarchy |
| exit_type | character | "departed", "unknown", "retirement" |
| alumni_status | character | "confirmed", "pending_verification", "returned" |
| notes | text | Additional information |

#### Development Tasks

**Task 3.3.1**: Create Alumni Detection Function
```r
# Function: identify_alumni(current_data, previous_data, master_data)
#
# Logic:
# 1. Get all person_ids from previous month
# 2. Check which person_ids NOT in current month (any hospital)
# 3. For each missing person:
#    a. Extract last position from master
#    b. Calculate tenure (first_seen to last_seen)
#    c. Count positions held from employment_history
#    d. Determine highest title held
#    e. Set exit_type based on patterns (if detectable)
#    f. Set alumni_status = "pending_verification"
# 4. Generate PersonnelAlumni_YYYY-MM-DD.csv
```

**Task 3.3.2**: Create Return-to-System Monitor
```r
# Function: check_alumni_returns(current_data, alumni_data)
#
# Logic:
# 1. Match current month data against alumni list
# 2. If alumni person found in current data:
#    a. Flag as "return_to_system" in movement report
#    b. Update alumni_status = "returned"
#    c. Calculate gap period
#    d. Update master record with gap notation in employment_history
```

**Task 3.3.3**: Build Alumni Analytics
```r
# Function: generate_alumni_statistics(alumni_data, master_data)
#
# Calculate:
# - Departure rate by hospital type
# - Average tenure by position level
# - Most common career endpoints
# - Return rate (alumni who came back)
# - Seasonal patterns in departures
```

**Testing Requirements**:
- Test alumni detection with simulated departures
- Validate tenure calculations
- Test return-to-system detection
- Verify no false positives (temporary data gaps)

---

### 3.4 Notification Lists Generation

**Target File**: `NewChanges_Notifications_YYYY-MM.csv`  
**Development Period**: January 25-28, 2026  
**Priority**: MEDIUM

#### Purpose
Generate actionable lists for outreach based on detected changes, prioritizing CEO and Board Chair positions.

#### Notification Categories

1. **New Hires** (never seen before in system)
   - Priority: High for CEO/Board Chair, medium for others
   - Message type: "Welcome/Introduction"

2. **Promotions** (same hospital, improved title)
   - Priority: High for CEO/Board Chair, medium for others
   - Message type: "Congratulations on promotion"

3. **External Moves** (different hospital)
   - Priority: High for CEO/Board Chair, medium for others
   - Message type: "Congratulations on new position"

4. **Departures** (moved to alumni status)
   - Priority: High for CEO/Board Chair only
   - Message type: "Stay connected"

#### Notification Record Structure

| Field | Type | Description |
|-------|------|-------------|
| notification_id | character | Unique ID |
| person_name | character | Person to contact |
| person_type | character | Employee or Volunteer |
| notification_type | character | new_hire, promotion, move, departure |
| priority_level | character | high, medium, low |
| hospital | character | Current/last hospital |
| title | character | Current/last title |
| previous_hospital | character | If applicable |
| previous_title | character | If applicable |
| detected_date | Date | When change detected |
| suggested_message | text | Template message type |
| verification_status | character | pending, confirmed, skip |
| notes | text | Additional context |

#### Development Tasks

**Task 3.4.1**: Build Notification Generator
```r
# Function: generate_notifications(movement_data, alumni_data, master_data, run_date)
#
# Logic:
# 1. Process movement records:
#    a. New person_ids → "new_hire"
#    b. Internal promotions → "promotion"
#    c. External moves → "move"
# 2. Process alumni records:
#    a. Recent departures → "departure"
# 3. Set priority levels:
#    a. CEO/Board Chair → "high"
#    b. All others → "medium" or "low"
# 4. Generate suggested message templates
# 5. Export to CSV for manual review/sending
```

**Task 3.4.2**: Create Message Templates
```r
# Store in separate reference file: notification_templates.csv
#
# Templates for each notification_type:
# - new_hire_ceo: "Congratulations on your appointment as CEO..."
# - new_hire_board_chair: "Welcome to your role as Board Chair..."
# - promotion_ceo: "Congratulations on your promotion to CEO..."
# - move_ceo: "Congratulations on your new position at..."
# - departure_ceo: "Best wishes in your next endeavor..."
# etc.
```

**Testing Requirements**:
- Test notification generation with Jan data
- Validate priority assignment
- Review message templates for appropriateness
- Test verification workflow

---

## INTEGRATION AND TESTING

### Phase 3 Complete Integration Test

**Test Date**: January 28-31, 2026  
**Test Data**: December 1 baseline + January 1 comparison

#### Test Scenarios

**Scenario 1: New Hires**
- Expected: People in Jan data but not Dec data
- Validate: Proper person_id creation, employment_history initialization
- Check: Notification generation for new CEOs/Board Chairs

**Scenario 2: Departures**
- Expected: People in Dec data but not Jan data
- Validate: Alumni record creation, tenure calculations
- Check: Notification generation for departed CEOs/Board Chairs

**Scenario 3: Internal Moves** (if any)
- Expected: Same person_id, same hospital_fac, different title
- Validate: Employment_history update, title level detection
- Check: Promotion notification if appropriate

**Scenario 4: External Moves** (if any)
- Expected: Same person_id, different hospital_fac
- Validate: Movement detection, confidence scoring
- Check: Move notification with priority flagging

**Scenario 5: Data Continuity** (most people)
- Expected: Same person_id, no changes
- Validate: last_seen updated, total_appearances incremented
- Check: No false positive notifications

#### Success Criteria
- ✓ All test scenarios pass
- ✓ Zero data loss (all Dec people accounted for)
- ✓ Movement detection accuracy >80% (manual validation)
- ✓ False positive rate <10%
- ✓ All files generate successfully
- ✓ No critical errors in logs

---

## PRODUCTION DEPLOYMENT

### Deployment Checklist (January 31, 2026)

**Pre-Deployment**:
- [ ] All Phase 3 code reviewed and tested
- [ ] Integration tests passed
- [ ] Documentation updated
- [ ] Backup of December baseline created
- [ ] Master reference file validated

**Deployment Steps**:
1. [ ] Update `process_hospital_data.R` with Phase 3 functions
2. [ ] Deploy `PersonnelMaster.csv` initialization
3. [ ] Deploy movement detection module
4. [ ] Deploy alumni tracking module
5. [ ] Deploy notification generation module
6. [ ] Update Task Scheduler jobs (if needed)
7. [ ] Create Phase 3 execution log

**Post-Deployment Validation**:
- [ ] Run full pipeline on Dec→Jan data
- [ ] Review all generated files
- [ ] Validate master reference update
- [ ] Check notification list accuracy
- [ ] Monitor for errors

**Documentation**:
- [ ] Update system documentation
- [ ] Create Phase 3 user guide
- [ ] Document known issues/limitations
- [ ] Update monthly operations checklist

---

## ONGOING OPERATIONS (February 2026+)

### Monthly Workflow with Phase 3

**Day 1 (1st of month, 2:00 AM)**: Automated scraping
- Task Scheduler runs `test_all_configured_hospitals.R`
- Generates raw data for new month

**Day 1 (4:00 AM)**: Automated processing
- Task Scheduler runs `process_hospital_data.R`
- Includes Phase 3 functions:
  * Update PersonnelMaster.csv
  * Detect movements
  * Identify alumni
  * Generate notification lists

**Day 2 (Manual review)**: Human validation
- Review movement detection results
- Verify high-priority notifications (CEO/Board Chair)
- Flag any anomalies
- Update verification status

**Day 2-5**: Outreach activities
- Use notification lists for relationship building
- Track responses/outcomes
- Update notes fields

**Monthly**: Quality review
- Review system metrics
- Validate data quality
- Monitor blocking trends
- Address manual entry queue

---

## SUCCESS METRICS

### Phase 3 Performance Targets

**Data Quality**:
- Master reference accuracy: >99%
- Movement detection true positive rate: >80%
- False positive rate: <10%
- Alumni detection accuracy: >95%

**Coverage**:
- Track >1000 individuals in master reference
- Capture >95% of actual personnel changes
- Document movements for >100 individuals (over time)

**Operational**:
- Automated pipeline success: >99%
- Manual review time: <3 hours per month
- Notification list generation: 100% automated
- Error rate: <2% of processed records

---

## RISK MANAGEMENT

### Identified Risks and Mitigations

**Risk 1**: Poor fuzzy matching accuracy with common names
- **Mitigation**: Credential matching bonus, title similarity checks, human review flagging
- **Contingency**: Lower confidence threshold with stricter review process

**Risk 2**: Too many false positive movements
- **Mitigation**: Conservative confidence thresholds (85%), credential validation
- **Contingency**: Increase threshold to 90%, add geographic proximity check

**Risk 3**: January data contains unexpected anomalies
- **Mitigation**: Comprehensive testing, manual validation of first run
- **Contingency**: Pause automation, debug with Claude, adjust algorithms

**Risk 4**: Alumni tracking misses temporary absences
- **Mitigation**: Require 2 consecutive months of absence before alumni status
- **Contingency**: Create "on leave" status for confirmed temporary absences

**Risk 5**: Notification lists overwhelming with new system
- **Mitigation**: Start with CEO/Board Chair only, expand gradually
- **Contingency**: Filter to verified movements only initially

---

## DEPENDENCIES AND BLOCKERS

### Critical Dependencies
1. ✓ December 1 baseline complete
2. ⏳ January 1 automated run successful
3. ⏳ January data quality validated
4. ⏳ Sufficient personnel changes in Jan vs Dec to test algorithms

### Potential Blockers
- **January automated run failure**: Would delay Phase 3 start
  * Mitigation: Manual run on Jan 2 if automation fails
- **Insufficient data changes**: Can't validate movement detection
  * Mitigation: Simulate test scenarios, proceed with caution
- **Technical issues with fuzzy matching**: Performance problems
  * Mitigation: Optimize with parallelization, reduce dataset size for testing

---

## NEXT IMMEDIATE STEPS (Post-December 1)

### Week of December 2-8, 2025
1. **Monitor December baseline stability**
   - Review any error reports
   - Validate CEO/Board Chair flagging
   - Check credential extraction accuracy

2. **Prepare for January 1 run**
   - Confirm Task Scheduler job configured
   - Verify email notification setup
   - Prepare comparison validation checklist

3. **Phase 3 planning refinement**
   - Review fuzzy matching libraries in R (stringdist, fuzzyjoin)
   - Research JSON handling best practices in R (jsonlite)
   - Prototype nickname dictionary structure

### Week of December 9-15, 2025
1. **Code skeleton preparation**
   - Create placeholder functions for Phase 3
   - Set up development branch (if using Git)
   - Prepare test data structure

### Week of December 16-31, 2025
1. **Holiday monitoring**
   - Ensure December baseline remains stable
   - Address any blocking issues
   - Prepare for January 1 automated execution

### Week of January 1-5, 2026
1. **January 1 data collection**
   - Monitor automated run completion
   - Validate January data quality
   - Compare to December baseline manually
   - Document observed changes

2. **Phase 3 kickoff**
   - Begin Master Personnel Reference development
   - Start with Task 3.1.1: Initialize function

---

## APPENDIX: FILE STRUCTURE

### Phase 3 Generated Files

**Master Reference** (Monthly):
```
E:/ExecutiveSearchYaml/
  processed/2025-12/PersonnelMaster_2025-12-01.csv
  processed/2026-01/PersonnelMaster_2026-01-01.csv
  processed/2026-02/PersonnelMaster_2026-02-01.csv
```

**Movement Reports** (Monthly):
```
E:/ExecutiveSearchYaml/
  processed/2026-01/PersonnelMovement_2026-01.csv
  processed/2026-02/PersonnelMovement_2026-02.csv
```

**Alumni Files** (Monthly):
```
E:/ExecutiveSearchYaml/
  processed/2026-01/PersonnelAlumni_2026-01-01.csv
  processed/2026-02/PersonnelAlumni_2026-02-01.csv
```

**Notification Lists** (Monthly):
```
E:/ExecutiveSearchYaml/
  processed/2026-01/NewChanges_Notifications_2026-01.csv
  processed/2026-02/NewChanges_Notifications_2026-02.csv
```

---

## DOCUMENT CONTROL

**Version History**:
- v1.0 (Dec 3, 2025): Initial Phase 3 plan created, December baseline established

**Related Documents**:
- Hospital_Data_Processing_Implementation_Plan (1).md (Original comprehensive plan)
- Implementation_Checklist.md (Phase 1 tasks - COMPLETED)
- Phase3_Implementation_Checklist.md (To be created after Jan 1 data)

**Approval**:
- Project Lead: Skip
- Status: Awaiting January 1, 2026 data for Phase 3 start

**Next Review Date**: January 5, 2026 (post-Jan 1 data validation)

---

*END OF DOCUMENT*
