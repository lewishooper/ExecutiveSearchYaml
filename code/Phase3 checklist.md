Pre-Flight Checks ✈️

 Verify January data completeness

 Confirm HospitalExecutives_Employees_2026-01-01.csv exists
 Confirm HospitalExecutives_Volunteers_2026-01-01.csv exists
 Check file sizes (compare to December baseline as sanity check)
 Verify date formats are YYYYMMDD throughout


 Validate December baseline integrity

 Confirm PersonnelMaster_2025-12-01.csv exists and is uncorrupted
 Check record count matches expectations (~1000+ individuals)
 Verify person_id uniqueness (no duplicates)


 Review January collection failures

 Document which hospitals failed (quantity and facility names)
 Categorize failure types (blocked, structure change, timeout, etc.)
 Assess impact on Phase 3 testing (critical vs. acceptable)



Phase 3.1: Master Personnel Reference - Initial Run

 Task 3.1.1: Initialize from December (COMPLETED ✓)

 Function initialize_personnel_master() exists
 Run initialization script to generate baseline if not already done
 Validate output: PersonnelMaster_2025-12-01.csv


 Task 3.1.2: First Update (Dec→Jan)

 Load December and January data files
 Load existing PersonnelMaster_2025-12-01.csv
 Run compare_all_hospitals() function
 Run detect_simple_movements() with threshold = 0.85
 Run update_personnel_master() with run_date = "2026-01-01"
 Generate PersonnelMaster_2026-01-01.csv


 Task 3.1.3: Validation and Review

 Run generate_summary_report()
 Manually review summary statistics for sanity
 Check: Total people count increased appropriately
 Check: No duplicate person_ids in updated master
 Check: Retained count + new count ≈ January total
 Check: Movements detected have confidence ≥ 0.85


 Task 3.1.4: Detailed Movement Analysis

 Export movements to CSV for manual review
 Flag high-confidence movements (≥0.95) as likely accurate
 Flag borderline movements (0.85-0.90) for human validation
 Document any obvious false positives
 Calculate actual accuracy metrics if validation done



Phase 3.2: Output Generation

 Generate monthly comparison files

 Create Retained_2026-01.csv (people at same hospital)
 Create NewArrivals_2026-01.csv (new to system)
 Create Departures_2026-01.csv (missing from January)
 Create Movements_2026-01.csv (detected cross-hospital changes)
 Create TitleChanges_2026-01.csv (promotions/lateral moves)


 Generate notification lists (Per Phase3_Next_Steps.md Section 3.4)

 Filter to priority positions (CEO, Board Chair)
 Create NewChanges_Notifications_2026-01.csv
 Include: person_name, movement type, from/to hospitals, confidence
 Flag for manual verification before outreach



Phase 3.3: Quality Assurance

 Data Quality Checks

 Verify no data loss: All December people accounted for (retained, moved, or departed)
 Check for orphaned records (person_id exists but no history)
 Validate all dates are valid Date objects
 Check for NA values in critical fields (person_id, person_name)


 Algorithm Performance

 Calculate movement detection metrics if manual validation done:

True positive rate (confirmed movements detected)
False positive rate (incorrect movement suggestions)
False negative rate (missed movements - if known)


 Assess credential matching effectiveness
 Document any edge cases or problem patterns



Documentation and Wrap-Up

 Update session logs

 Document Phase 3 first run results
 Record any issues encountered
 Note any algorithm tuning needed (threshold adjustments, etc.)


 Create February readiness checklist

 Confirm process can run end-to-end without errors
 Document manual steps still required (if any)
 Update automation scripts if needed
 Schedule February 1 execution


 Backup and version control

 Backup all generated files to server
 Commit code changes to Git
 Tag release: "Phase3-Initial-Run"