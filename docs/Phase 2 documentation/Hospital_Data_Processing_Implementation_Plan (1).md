# ONTARIO HOSPITAL EXECUTIVE DATA
## Post-Processing and Tracking System - Implementation Plan

**Version**: 1.0  
**Date**: November 20, 2025  
**Baseline Date**: December 1, 2025  
**Author**: Skip

---

## EXECUTIVE SUMMARY

This document outlines the implementation plan for transforming raw hospital executive scraping data into a comprehensive longitudinal tracking system. The system will support two primary objectives:

1. Research on hospital executive turnover over 24+ months
2. Generation of notification lists for outreach and relationship management

The implementation follows a phased approach with December 1, 2025 as the baseline date for ongoing tracking.

---

## SYSTEM OVERVIEW

### Current State

- Functional web scraper collecting executive/board data from 100+ Ontario hospitals
- Raw output from `test_all_configured_hospitals.R`
- Data includes executives, board members, and key contacts
- Variable data quality due to website blocking, JavaScript, and HTML complexity

### Target State

- Automated post-processing pipeline
- Separated employee and volunteer datasets
- Monthly tracking of personnel changes
- Movement detection across organizations
- Automated quality and status reporting
- Alumni tracking system

---

## PHASE 1: DATA CLEANING AND STANDARDIZATION

**Timeline**: November 21-29, 2025  
**Goal**: Create robust post-processing pipeline

### 1.1 Core Processing Script Development

**File**: `process_hospital_data.R`

**Input Requirements**:
- Raw scraping output (list format from scraper)
- Configuration: baseline date, comparison dates
- Reference files: hospital master list, pattern registry
- Enhanced hospitals YAML (with private/closed hospitals already removed)

**Pre-Processing Manual Step**:
- **CRITICAL**: Before running any processing, manually review `enhanced_hospitals.yaml` and remove or mark as inactive any hospitals designated as "private" or "closed"
- This is a one-time cleanup step to ensure we only process active, public hospitals

**Processing Steps**:

#### Step 1: Data Normalization and Cleaning

**FUNCTION**: `normalize_raw_data()`

- Accept raw scraper output
- Flatten nested list structures
- Standardize field names
- Handle missing values
- Normalize text encoding (UTF-8)
- Clean HTML entities and special characters
- Standardize Unicode for French names (accents, apostrophes)
- Extract and separate credentials from names (MD, PhD, RN, etc.)
- Validate name length (flag if >50 characters - possible biography bleed)
- Validate title length (flag if >100 characters - possible biography bleed)

**Note**: Data cleaning should be minimal as scraper output is already clean. Focus on standardization and validation.

#### Step 2: Employee vs Volunteer Classification

**FUNCTION**: `classify_person_type()`

**VOLUNTEER CLASSIFICATION RULES**:
1. Title contains: "Board", "Trustee", "Governor"
2. Title = "Director" ONLY (no additional text after "Director")
3. Title contains: "Chair", "Vice Chair", "First Vice Chair", "Second Vice Chair" (without executive designation)
4. Title contains: "Treasurer" (in board context)
5. Explicitly labeled as "Board Member" or "Volunteer"

**EMPLOYEE CLASSIFICATION RULES**:
1. Title contains executive designations: CEO, CFO, COO, CNO, CIO, CMO, COS (Chief of Staff)
   - Note: Full list of executive titles available in enhanced_hospitals.yaml title checking function
   - Some unusual titles exist but should be preserved as-is
2. Title pattern: "Director of [something]", "Director, [something]"
3. Title contains: Manager, Coordinator, Administrator, Supervisor, Vice President, VP
4. Title contains: "Chief" followed by role designation
5. Anyone listed as "Key Contact" or "Leadership Team" (unless board-specific)
6. **General Rule**: If not classified as Volunteer, classify as Employee and preserve original title

**CLASSIFICATION RULE**:
```
Each person is classified as EITHER Employee OR Volunteer (never both)

Priority of classification:
1. Check VOLUNTEER rules first
2. If matches ANY volunteer rule → VOLUNTEER
3. If does NOT match volunteer rules → EMPLOYEE

No dual classification or special flags needed.
```

**PRIORITY FLAGGING**:
- Priority flag set to TRUE ONLY for:
  - Chief Executive Officer (CEO)
  - Board Chair
- All other positions: priority flag = FALSE

#### Step 3: Data Quality Status Assignment

**FUNCTION**: `assign_data_status()`

**STATUS CODES**:
- "scraped" = Successfully extracted via pattern matching
- "manual_entry" = Human-entered data (from manual process)
- "partial_scrape" = Some executives found, but known to be incomplete
- "robotstxt_blocked" = Blocked by robots.txt
- "javascript_blocked" = Content requires JavaScript rendering
- "blocked" = General blocking (403, 429, etc.)
- "failed" = Scraping attempted but failed

**ASSIGNMENT LOGIC**:
Based on scraper return codes and error flags in raw data

---

### 1.2 Output Dataframe Specifications

**EMPLOYEES Dataset**  
File: `HospitalExecutives_Employees_YYYY-MM-DD.csv`

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| hospital_name | character | Full hospital name | "Ottawa Hospital - General Campus" |
| fac_number | character | FAC identifier | "123" |
| hospital_type | character | Hospital classification | "Large Community" |
| person_name | character | Standardized name (without credentials) | "Jane Smith" |
| credentials | character | Professional credentials | "MD, PhD" |
| title | character | Job title | "Chief Financial Officer" |
| collection_date | Date | Scrape date | "2025-12-01" |
| data_status | character | Quality indicator | "scraped" |
| source_url | character | URL scraped from | "https://..." |
| pattern_used | character | Pattern ID | "simple_name_title" |
| notes | character | Any relevant flags | "long_title_flagged" |

**VOLUNTEERS Dataset**  
File: `HospitalExecutives_Volunteers_YYYY-MM-DD.csv`

Same structure as Employees dataset.

**Field Notes**:
- **person_name**: Name without credentials (credentials stored separately)
- **credentials**: Comma-separated list of credentials (MD, PhD, RN, MBA, etc.)
- **notes**: Used for validation flags (e.g., "name_length_warning", "title_length_warning", "biography_bleed_suspected")

---

### 1.3 Validation Requirements

**Pre-Release Validation Checklist**:
- [ ] Manually remove private and closed hospitals from enhanced_hospitals.yaml
- [ ] Test with 100 random records weighted toward Large and Teaching hospitals
- [ ] Verify employee/volunteer split (CEO = Employee, Board members = Volunteer)
- [ ] Confirm "Director" alone → Volunteer
- [ ] Confirm "Director of X" → Employee
- [ ] Confirm Board Treasurer → Volunteer
- [ ] Confirm First/Second Vice Chair → Volunteer
- [ ] Check name length validation (flag if >50 characters)
- [ ] Check title length validation (flag if >100 characters)
- [ ] Review flagged records for biography text bleed
- [ ] Verify no duplicate person-hospital combinations within dataset
- [ ] Test with manual entry data
- [ ] Test with partial scrape scenarios
- [ ] Confirm UTF-8 encoding for French names
- [ ] Verify Unicode standardization for accents and apostrophes
- [ ] Validate credentials extraction (MD, PhD, RN, etc.)
- [ ] Validate date formatting consistency
- [ ] Confirm priority flags only on CEO and Board Chair

---

## PHASE 2: LONGITUDINAL TRACKING SYSTEM

**Timeline**: December 1, 2025 - Ongoing  
**Goal**: Track changes over time, identify movements

### 2.1 Baseline Establishment (December 1, 2025)

**Process**:
1. Execute full scrape: `test_all_configured_hospitals.R`
2. Run post-processing: `process_hospital_data.R`
3. Generate baseline files:
   - `HospitalExecutives_Employees_2025-12-01.csv` (BASELINE)
   - `HospitalExecutives_Volunteers_2025-12-01.csv` (BASELINE)
4. Create master reference: `PersonnelMaster_2025-12-01.csv`
5. Generate initial quality report
6. Archive raw scraping output
7. Document any manual interventions needed

---

### 2.2 Master Personnel Reference System

**File**: `PersonnelMaster.csv`

**Purpose**: Maintain complete employment history for all individuals across time

**Structure**:

| Field | Type | Description |
|-------|------|-------------|
| person_id | character | Unique identifier (auto-generated) |
| person_name | character | Canonical name |
| name_variants | character | Comma-separated alternate spellings |
| current_hospital | character | Most recent hospital |
| current_title | character | Most recent title |
| current_type | character | "Employee" or "Volunteer" |
| first_seen | Date | First appearance in system |
| last_seen | Date | Most recent appearance |
| status | character | "active", "moved", "departed", "alumni" |
| employment_history | text | JSON array of positions |

**Update Process**:
1. Each monthly run compares new data to master
2. Matching records update last_seen date
3. New names create new person_id
4. Missing names flagged for alumni check
5. Title changes append to employment_history

---

### 2.3 Monthly Differential Reports

**Script**: `generate_monthly_reports.R`

#### Report 1: Month-to-Month Changes

**File**: `TurnoverReport_Monthly_YYYY-MM.csv`

**Generation Logic**:
```
FUNCTION: compare_months(current_month, previous_month)

FOR EACH hospital:
  current_people = get_people(current_month, hospital)
  previous_people = get_people(previous_month, hospital)
  
  # New hires
  new_hires = current_people NOT IN previous_people
  
  # Departures
  departures = previous_people NOT IN current_people
  
  # Title changes
  FOR EACH person IN BOTH months:
    IF current_title != previous_title:
      RECORD title_change
      CLASSIFY as "promotion", "lateral_move", or "title_change"
```

**Output Fields**:
- hospital_name, fac_number
- person_name
- change_type: "new_hire", "departure", "title_change", "promotion", "internal_move"
- old_title (if applicable)
- new_title (if applicable)
- old_hospital (if applicable - for moves)
- new_hospital (if applicable)
- detection_date
- priority_flag: TRUE if CEO or Board Chair

#### Report 2: Baseline Comparison

**File**: `TurnoverReport_vs_Baseline_YYYY-MM.csv`

Same logic as Report 1, but comparing current month against December 1, 2025 baseline.

**Additional Metrics**:
- Total net change (additions minus departures)
- Cumulative turnover rate by hospital
- Position stability indicators

---

### 2.4 Movement Detection System

**Script**: `detect_personnel_movements.R`

**Purpose**: Identify individuals moving between organizations or positions

#### Fuzzy Name Matching Algorithm

**Algorithm**: Jaro-Winkler distance with 85% threshold

**Steps**:
1. Normalize names (remove titles, but KEEP credentials for comparison)
2. Generate name variants:
   - Full name as-is
   - First + Last (drop middle)
   - Nickname substitutions (Robert→Bob, Elizabeth→Beth, etc.)
   - Initial variations (J. Smith → John Smith)
3. Calculate similarity scores for all combinations
4. **Use credentials as additional evidence**: If credentials match (MD, PhD, RN), increase confidence in match
5. Return matches above 85% threshold
6. Rank by similarity score and credential match

**Handling Common Names**:
- If multiple matches found, require additional evidence:
  - **Matching credentials (high value evidence)**
  - Similar title/role
  - Geographic proximity
- Flag for human review if ambiguous

**Credential Matching Rules**:
- Exact credential match adds strong supporting evidence
- Partial credential match (e.g., "MD" present in both) adds moderate evidence
- Credential mismatch (different credentials) may indicate different person
- Missing credentials in one record treated neutrally (not penalized)

#### Movement Classification

**EXTERNAL MOVE**:
- Different hospital than previous position
- Subcategories: lateral, promotion, demotion (based on title analysis)

**INTERNAL MOVE**:
- Same hospital, different title
- Subcategories:
  - promotion: improved title level
  - lateral: similar title level, different department
  - title_change: administrative title update

**RETURN TO SYSTEM**:
- Person appeared in alumni list, now back in active system
- Flag tenure gap duration

#### Output File: Personnel Movement Report

**File**: `PersonnelMovement_YYYY-MM.csv`

**Fields**:
- person_name
- match_confidence: 0.0-1.0 (from fuzzy matching)
- movement_type: "external_move", "internal_promotion", "internal_lateral", "return_to_system"
- origin_hospital
- origin_title
- origin_last_seen
- destination_hospital
- destination_title
- destination_first_seen
- title_level_change: "promotion", "lateral", "demotion", "unclear"
- verification_status: "pending", "confirmed", "false_positive", "rejected"
- notes: text field for human annotations
- priority_flag: TRUE if high-priority position

**Human Verification Workflow**:
1. System generates movement candidates
2. Export to review spreadsheet
3. Human reviews and marks verification_status
4. Confirmed movements added to master record employment_history
5. False positives used to improve matching algorithm

---

### 2.5 Alumni Tracking System

**File**: `PersonnelAlumni_YYYY-MM-DD.csv`

**Generation Logic**:
```
FUNCTION: identify_alumni(current_data, previous_data, master_data)

CRITERIA FOR ALUMNI STATUS:
1. Person appeared in previous month's data
2. Person NOT in current month's data (any hospital)
3. Person not flagged as "on leave" or "temporary absence"
```

**Alumni Record Fields**:
- person_name
- last_hospital
- last_title
- last_seen_date
- first_seen_date (original entry to system)
- total_tenure_months
- number_of_positions_held
- highest_title_held
- exit_type: "departed", "unknown", "retirement" (if detectable)
- notes

**Monitoring**:
- Check each month if alumni reappear in system
- If reappear: flag as "return_to_system" in movement report
- Update master record with gap period

---

## PHASE 3: REPORTING AND MONITORING

**Timeline**: Ongoing (auto-generated each run)  
**Goal**: Visibility into data quality and actionable intelligence

### 3.1 Notification/Congratulations Lists

**File**: `NewChanges_Notifications_YYYY-MM.csv`

**Purpose**: Generate lists for outreach based on detected changes

**Categories**:

1. **New Hires** (never seen before in system)
   - Priority: High for CEO/Board Chair, medium for all others
   - Message type: "Welcome/Introduction"

2. **Promotions** (same hospital, improved title)
   - Priority: High for CEO/Board Chair, medium for others
   - Message type: "Congratulations on promotion"

3. **External Moves** (different hospital)
   - Priority: High for CEO/Board Chair, medium for all others
   - Message type: "Congratulations on new position"

4. **New Board Appointments**
   - Priority: High for Board Chair, medium for members
   - Message type: "Congratulations on board appointment"

**High Priority Positions** (automatic flagging):
- Chief Executive Officer (CEO)
- Board Chair

**Output Format**:
```
person_name | hospital_name | new_title | change_type | priority | detection_date | notes
```

**Generation Rules**:
- Only include changes from most recent month
- Exclude false positives from movement detection
- Include confidence score if below 0.8 (for human review)
- Sort by priority then by hospital

---

### 3.2 Data Quality Reports

#### Report A: Scraping Status Summary

**File**: `ScrapingStatus_YYYY-MM-DD.csv`

**Auto-generated each scraping run**

**Summary Statistics Section**:
```
Total hospitals in system: XXX
Successfully scraped: XXX (XX%)
Manual entry required: XXX (XX%)
Blocked by robots.txt: XXX (XX%)
Blocked by JavaScript: XXX (XX%)
General blocking issues: XXX (XX%)
Partial scrapes: XXX (XX%)
Failed (other): XXX (XX%)
```

**Trend Analysis** (compared to previous run):
```
Change in success rate: +/- XX%
New blocking issues: XX hospitals
Resolved issues: XX hospitals
```

#### Report B: Detailed Blocking Report

**File**: `BlockedHospitals_Detail_YYYY-MM-DD.csv`

**Fields**:
- hospital_name, fac_number
- block_type: specific error category
- last_successful_scrape: date
- consecutive_failures: count
- first_failure_date: date
- error_message: text
- recommended_action: "retry", "manual_entry", "contact_hospital", "update_pattern"
- priority: "high", "medium", "low" (based on hospital size/importance)
- notes: manual annotations

**Auto-Population Logic**:
- Carry forward from previous runs
- Update consecutive_failures count
- Flag hospitals that were working but now blocked
- Priority = high if large hospital or CEO missing

#### Report C: Manual Entry Requirements

**File**: `ManualEntryNeeded_YYYY-MM-DD.csv`

**Purpose**: Track hospitals requiring human data entry

**Fields**:
- hospital_name, fac_number, hospital_type
- reason_code: why manual entry needed
- last_attempt_date
- number_of_attempts
- estimated_executives_count: (to track completion)
- current_executives_count: (already manually entered)
- completion_status: "not_started", "partial", "complete"
- priority: based on hospital size and data staleness
- assigned_to: (for workflow management)
- notes

**Workflow Integration**:
- Generate at end of each scraping run
- Integrate with manual entry tracking spreadsheet
- Flag when manual entry data becomes stale (>60 days)

---

### 3.3 Executive Dashboard Metrics (Future Phase)

**Metrics to Track**:
1. Overall system coverage (% hospitals with current data)
2. Average executive count by hospital type
3. Turnover rate by hospital type
4. Turnover rate by position type
5. Most common career paths (movement patterns)
6. Geographic movement patterns
7. Average tenure by position
8. Seasonal patterns in hiring/departures

---

## PHASE 4: AUTOMATION AND SCHEDULING

**Timeline**: Q1 2026 (after manual process validated)  
**Goal**: Automate monthly execution

### 4.1 Automation Strategy

**Tool**: Windows Task Scheduler

**Monthly Job Configuration**:

**Job 1: Data Collection**
- Schedule: 1st of each month, 2:00 AM
- Script: `E:/ExecutiveSearchYaml/scheduled_scrape.R`
- Actions:
  1. Execute `test_all_configured_hospitals.R`
  2. Save raw output with timestamp
  3. Log execution results
  4. Email notification on completion/failure

**Job 2: Data Processing**
- Schedule: 1st of each month, 4:00 AM (after Job 1)
- Script: `E:/ExecutiveSearchYaml/scheduled_processing.R`
- Actions:
  1. Run `process_hospital_data.R`
  2. Generate all reports
  3. Update master reference file
  4. Archive previous month's data
  5. Email summary report

**Job 3: Movement Detection**
- Schedule: 2nd of each month, 9:00 AM (manual review time)
- Script: `E:/ExecutiveSearchYaml/scheduled_movement_detection.R`
- Actions:
  1. Run movement detection
  2. Generate notification lists
  3. Create verification spreadsheet
  4. Email to Skip for review

---

### 4.2 Error Handling and Notifications

**Email Notification Rules**:
- Always notify on job completion
- Immediate alert on critical failures
- Summary report with key metrics
- Attach quality reports
- Include exception count and types

**Logging Requirements**:
- Timestamp each major operation
- Log all errors with full stack traces
- Track processing time for performance monitoring
- Maintain 12 months of logs

---

### 4.3 Backup and Archival

**Backup Strategy**:
- Daily backup of master reference file
- Monthly archive of all generated files
- Quarterly archive of raw scraping outputs
- Cloud backup (OneDrive/Google Drive) of critical files

**Directory Structure**:
```
E:/ExecutiveSearchYaml/
  /current/           # Current working files
  /archive/
    /2025-12/         # Monthly archives
    /2026-01/
    ...
  /backups/
    /daily/           # Rolling 7-day backups
    /monthly/         # Permanent monthly backups
  /logs/              # Execution logs
  /reports/           # Generated reports by date
```

---

## DATA DICTIONARY

### Field Definitions and Standards

**person_name**: 
- Format: "First [Middle] Last"
- Remove credentials (MD, PhD, RN, etc.) - store in separate credentials field
- Standardize capitalization
- Handle hyphenated names consistently
- Handle accented characters (UTF-8)
- Standardize Unicode for French names (accents, apostrophes - e.g., normalize different Unicode representations of é, à, ')
- Flag if length >50 characters (possible biography text bleed)

**credentials**:
- Comma-separated list of professional credentials
- Examples: "MD", "PhD", "RN", "MBA", "MD, PhD", "RN, BScN"
- Extracted from name field during normalization
- Used in movement detection matching to disambiguate common names
- May be empty/null if person has no credentials

**title**: 
- Preserve original title text as given by hospital
- Standardize common abbreviations (CEO, CFO, etc.) only if needed
- Keep credentials if part of title (e.g., "Director, MD" if that's how hospital lists it)
- Preserve department/specialty designations
- Flag if length >100 characters (possible biography text bleed)

**hospital_type**:
- Values: "Large Community", "Small Community", "Teaching", "Psychiatric", "Rehabilitation", "Specialty"
- From master hospital reference list

**data_status**:
- "scraped": Successfully extracted via automated pattern
- "manual_entry": Human-entered data
- "partial_scrape": Automated but known incomplete
- "robotstxt_blocked": Blocked by robots.txt file
- "javascript_blocked": Requires JS rendering
- "blocked": HTTP-level blocking (403, 429, etc.)
- "failed": Other failure modes

**movement_type**:
- "new_hire": First appearance in system
- "departure": Left previous position, not found elsewhere
- "external_move": Changed hospitals
- "internal_promotion": Same hospital, better title
- "internal_lateral": Same hospital, different role
- "return_to_system": Reappearance after alumni status
- "title_change": Administrative title update

**priority_flag**:
- TRUE for: CEO and Board Chair only
- FALSE for all others

---

## TESTING AND VALIDATION PLAN

### Pre-Launch Testing (Nov 21-29)

**Test 1: Classification Accuracy**
- Manual review of 100 random records
- Weight selection toward Large and Teaching hospitals
- Include representation from all hospital types
- Verify employee/volunteer split
- Check CEO → Employee, Board members → Volunteer
- Verify Treasurer and Vice Chair positions → Volunteer
- Target: >99% accuracy

**Test 2: Data Quality**
- Check for malformed names
- Verify name length validation (<50 characters)
- Verify title length validation (<100 characters)
- Review flagged records for biography text bleed
- Verify date formatting
- Confirm UTF-8 encoding
- Test Unicode standardization for French names
- Verify credential extraction
- Test with edge cases

**Test 3: Report Generation**
- Generate all report types
- Verify file naming conventions
- Check report completeness
- Validate calculations
- Confirm priority flags only on CEO and Board Chair

---

### Baseline Validation (Dec 1)

**Pre-Baseline Manual Tasks**:
- [ ] Review enhanced_hospitals.yaml
- [ ] Remove or mark as inactive any hospitals designated as "private"
- [ ] Remove or mark as inactive any hospitals designated as "closed"
- [ ] Document which hospitals were removed and why

**Validation Checklist**:
- [ ] All configured active hospitals processed
- [ ] Private and closed hospitals excluded
- [ ] Employee/volunteer counts reasonable
- [ ] CEO and Board Chair positions captured and flagged
- [ ] Quality reports generated
- [ ] Master reference file created
- [ ] No critical errors in logs
- [ ] Manual interventions documented
- [ ] Name/title length validations working
- [ ] Credentials properly extracted and stored

---

### Ongoing Monitoring

**Monthly Review Process**:
1. Review turnover reports for anomalies
2. Validate movement detection accuracy
3. Check blocking report trends
4. Review confidence score distributions
5. Update manual entry queue
6. Document any system improvements needed

---

## RISK MANAGEMENT

### Identified Risks and Mitigations

**Risk 1: Website Blocking Escalation**
- Impact: High (data availability)
- Probability: Medium
- Mitigation: 
  - Respect robots.txt strictly
  - Rotate scraping times
  - Maintain manual entry capability
  - Build relationships with hospital IT departments

**Risk 2: False Positive Movement Detection**
- Impact: Medium (reputation risk if incorrect congratulations sent)
- Probability: Medium-High
- Mitigation:
  - Human verification required before action
  - Conservative fuzzy matching threshold (85%)
  - Build verified matches database over time
  - Track false positive rate

**Risk 3: Data Privacy Concerns**
- Impact: High (legal/ethical)
- Probability: Low
- Mitigation:
  - Only collect publicly posted information
  - No scraping of password-protected areas
  - Respect robots.txt
  - Proper data security for stored information

**Risk 4: Name Matching Errors (Common Names)**
- Impact: Medium (data accuracy)
- Probability: Medium
- Mitigation:
  - Require additional evidence for common names
  - Track name frequency in system
  - Flag ambiguous matches for review
  - Build verification history

**Risk 5: System Failure During Automated Run**
- Impact: Medium (missed data collection)
- Probability: Low
- Mitigation:
  - Comprehensive error logging
  - Email notifications on failures
  - Ability to re-run manually
  - Maintain backup schedules

---

## SUCCESS METRICS

### Key Performance Indicators (KPIs)

**Data Quality Metrics**:
1. Classification Accuracy: >99% employee/volunteer split correct
2. Data Completeness: >90% of active hospitals with current executive data
3. Duplicate Rate: <1% duplicate person-hospital records
4. Name/Title Length: <2% of records flagged for length warnings
5. Credential Extraction: >95% of credentials properly extracted and stored

**System Performance Metrics**:
1. Scraping Success Rate: >85% successful scrapes
2. Processing Time: Complete monthly cycle in <4 hours
3. Movement Detection Accuracy: >80% true positive rate
4. False Positive Rate: <10% on movement detection

**Research Value Metrics**:
1. Longitudinal Coverage: 24+ months of continuous data
2. Turnover Detection: Capture >95% of actual executive changes
3. Career Path Tracking: Document movements for >100 individuals
4. Data Freshness: >90% of data <45 days old

**Operational Metrics**:
1. Manual Entry Queue: <10 hospitals pending
2. Report Generation: 100% automated, no manual intervention
3. System Uptime: >99% scheduled job success rate
4. Error Rate: <2% of records with processing errors

---

## RESOURCE REQUIREMENTS

### Technical Resources
- R Development Environment (RStudio)
- Required R Packages: tidyverse, stringdist, lubridate, yaml, jsonlite, readxl, writexl
- Storage: ~500MB per month (estimated)
- Processing Power: Standard desktop sufficient
- Backup Storage: Cloud storage for archives

### Time Requirements

**Development Phase (Nov 21-29)**:
- Script development: 16-20 hours
- Testing and validation: 8-12 hours
- Documentation: 4-6 hours

**Monthly Operations** (once automated):
- Data collection: Automated (2 hours runtime)
- Movement verification: 2-3 hours manual review
- Quality review: 1-2 hours
- Report distribution: 0.5 hours

**Baseline Setup (Dec 1)**:
- Execution and validation: 4-6 hours
- Documentation: 2 hours

---

## APPENDICES

### A. File Naming Conventions

**Data Files**:
- Employees: `HospitalExecutives_Employees_YYYY-MM-DD.csv`
- Volunteers: `HospitalExecutives_Volunteers_YYYY-MM-DD.csv`
- Master: `PersonnelMaster_YYYY-MM-DD.csv`
- Alumni: `PersonnelAlumni_YYYY-MM-DD.csv`

**Reports**:
- Monthly Turnover: `TurnoverReport_Monthly_YYYY-MM.csv`
- Baseline Comparison: `TurnoverReport_vs_Baseline_YYYY-MM.csv`
- Movements: `PersonnelMovement_YYYY-MM.csv`
- Notifications: `NewChanges_Notifications_YYYY-MM.csv`
- Scraping Status: `ScrapingStatus_YYYY-MM-DD.csv`
- Blocking Detail: `BlockedHospitals_Detail_YYYY-MM-DD.csv`
- Manual Entry: `ManualEntryNeeded_YYYY-MM-DD.csv`

---

### B. Known Title Patterns

**Executive Titles** (sample - expand as needed):
- Chief Executive Officer (CEO)
- Chief Financial Officer (CFO)
- Chief Operating Officer (COO)
- Chief Nursing Officer (CNO)
- Chief Medical Officer (CMO)
- Chief of Staff (COS)
- Chief Information Officer (CIO)
- President
- Vice President
- Director of [Department]
- Manager
- Administrator
- Coordinator

**Volunteer Titles**:
- Board Chair
- Board Vice Chair
- First Vice Chair
- Second Vice Chair
- Board Member
- Trustee
- Treasurer (in board context)
- Governor
- Director (standalone)

---

### C. Common Name Variants for Fuzzy Matching

**Nicknames to Track**:
- Robert ↔ Bob, Rob, Bobby
- William ↔ Bill, Will, Billy
- Elizabeth ↔ Beth, Liz, Betty
- Michael ↔ Mike, Mick
- Jennifer ↔ Jen, Jenny
- Christopher ↔ Chris
- Catherine ↔ Cathy, Kate, Katie
- (Expand as encountered)

---

### D. Decision Trees

**Employee vs Volunteer Classification**:
```
START
├─ Title contains "Board"? 
│  ├─ YES → Is also CEO/COS/CNO?
│  │  ├─ YES → EMPLOYEE
│  │  └─ NO → VOLUNTEER
│  └─ NO → Continue
├─ Title = "Director" only (nothing after)?
│  ├─ YES → VOLUNTEER
│  └─ NO → Continue
├─ Title contains "Chief", "Manager", "Director of", "VP"?
│  ├─ YES → EMPLOYEE
│  └─ NO → Continue
├─ Listed as "Leadership Team"?
│  ├─ YES → EMPLOYEE
│  └─ NO → Manual review needed
```

---

### E. Contact Information

**Project Lead**: Skip  
**Project Repository**: E:/ExecutiveSearchYaml/  
**Documentation**: E:/ExecutiveSearchYaml/documentation/  
**Support**: Claude AI (Project assistant)

---

## REVISION HISTORY

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-20 | Skip | Initial implementation plan |

---

## APPROVAL SIGNATURES

**Project Lead**: __________________________ Date: __________

**Technical Review**: __________________________ Date: __________

---

**END OF DOCUMENT**
