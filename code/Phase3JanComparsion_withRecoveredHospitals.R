# =============================================================================
# PHASE 3.1 - JANUARY COMPARISON (WITH RECOVERED HOSPITALS)
# =============================================================================

library(dplyr)
library(stringr)
library(stringdist)

# Load Phase 3 functions
source("E:/ExecutiveSearchYaml/code/master_reference_functions.R")

cat("\n╔═══════════════════════════════════════════════╗\n")
cat("║   PHASE 3: DEC → JAN COMPARISON (UPDATED)    ║\n")
cat("╚═══════════════════════════════════════════════╝\n\n")

# =============================================================================
# SECTION 2.2: LOAD ALL REQUIRED DATA
# =============================================================================

cat("Loading data files...\n")
cat("─────────────────────────────────────────────────\n\n")

# Load December baseline (unchanged)
dec_employees <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Employees_2025-12-01.csv",
                          stringsAsFactors = FALSE)
dec_volunteers <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Volunteers_2025-12-01.csv",
                           stringsAsFactors = FALSE)

cat(sprintf("✓ December employees: %d\n", nrow(dec_employees)))
cat(sprintf("✓ December volunteers: %d\n", nrow(dec_volunteers)))

# Load UPDATED January data (with recovered hospitals)
jan_employees <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Employees_2026-01-01.csv",
                          stringsAsFactors = FALSE)
jan_volunteers <- read.csv("E:/ExecutiveSearchYaml/processed/HospitalExecutives_Volunteers_2026-01-01.csv",
                           stringsAsFactors = FALSE)

cat(sprintf("✓ January employees: %d\n", nrow(jan_employees)))
cat(sprintf("✓ January volunteers: %d\n", nrow(jan_volunteers)))

# Load December PersonnelMaster baseline
personnel_master <- read.csv("E:/ExecutiveSearchYaml/processed/PersonnelMaster_2025-12-01.csv",
                             stringsAsFactors = FALSE)

# Convert dates (important!)
personnel_master$first_seen <- as.Date(personnel_master$first_seen)
personnel_master$last_seen <- as.Date(personnel_master$last_seen)

cat(sprintf("✓ Personnel Master: %d people\n\n", nrow(personnel_master)))

# Verify recovered hospitals are present in January data
cat("Verifying recovered hospitals...\n")
cat("─────────────────────────────────────────────────\n")
recovered_facs <- c("699", "930", "763")
for (fac in recovered_facs) {
  count <- sum(c(jan_employees$fac_number, jan_volunteers$fac_number) == fac)
  cat(sprintf("FAC %s: %d people %s\n", fac, count, ifelse(count > 0, "✓", "✗ MISSING")))
}
cat("\n")

# =============================================================================
# SECTION 2.3: RUN HOSPITAL COMPARISON
# =============================================================================

cat("Running hospital comparison...\n")
cat("─────────────────────────────────────────────────\n\n")

comparison_results <- compare_all_hospitals(
  dec_employees = dec_employees,
  dec_volunteers = dec_volunteers,
  jan_employees = jan_employees,
  jan_volunteers = jan_volunteers,
  personnel_master = personnel_master
)

# Console output will show summary automatically

# =============================================================================
# SECTION 2.4: DETECT CROSS-HOSPITAL MOVEMENTS
# =============================================================================

cat("\nDetecting movements...\n")
cat("─────────────────────────────────────────────────\n\n")

movements <- detect_simple_movements(
  departures = comparison_results$departures,
  new_arrivals = comparison_results$new_arrivals,
  threshold = 0.85
)

# =============================================================================
# SECTION 2.5: UPDATE PERSONNEL MASTER
# =============================================================================

cat("\nUpdating Personnel Master...\n")
cat("─────────────────────────────────────────────────\n\n")

updated_master <- update_personnel_master(
  personnel_master = personnel_master,
  comparison_results = comparison_results,
  movements = movements,
  run_date = "2026-01-01"
)

cat(sprintf("✓ Master updated: %d → %d people\n", 
            nrow(personnel_master), nrow(updated_master)))
cat(sprintf("✓ New people added: %d\n\n", 
            nrow(updated_master) - nrow(personnel_master)))

# =============================================================================
# SECTION 2.6: GENERATE SUMMARY REPORT
# =============================================================================

generate_summary_report(
  comparison_results = comparison_results,
  movements = movements,
  personnel_master_before = personnel_master,
  personnel_master_after = updated_master
)

# =============================================================================
# SPECIAL CHECK: DOUG EARLE AND LESLIE SANDERS
# =============================================================================

cat("\n╔═══════════════════════════════════════════════╗\n")
cat("║   CHECKING KNOWN ISSUE CASES                  ║\n")
cat("╚═══════════════════════════════════════════════╝\n\n")

# Check Doug Earle movements
doug_movements <- movements %>%
  filter(grepl("Earle", person_name, ignore.case = TRUE))

if (nrow(doug_movements) > 0) {
  cat("DOUG EARLE MOVEMENTS:\n")
  cat("─────────────────────────────────────────────────\n")
  for (i in 1:nrow(doug_movements)) {
    cat(sprintf("%d. %s\n", i, doug_movements$person_name[i]))
    cat(sprintf("   From: %s (FAC-%s)\n", 
                doug_movements$from_hospital[i], doug_movements$from_hospital_fac[i]))
    cat(sprintf("   To:   %s (FAC-%s)\n", 
                doug_movements$to_hospital[i], doug_movements$to_hospital_fac[i]))
    cat(sprintf("   Confidence: %.3f\n\n", doug_movements$match_confidence[i]))
  }
} else {
  cat("✓ No Doug Earle movements detected\n")
  cat("  (WRHN data now present, may have resolved the false movement)\n\n")
}

# Check Leslie Sanders
leslie_movements <- movements %>%
  filter(grepl("Sanders.*Leslie|Leslie.*Sanders", person_name, ignore.case = TRUE))

if (nrow(leslie_movements) > 0) {
  cat("LESLIE SANDERS MOVEMENTS:\n")
  cat("─────────────────────────────────────────────────\n")
  for (i in 1:nrow(leslie_movements)) {
    cat(sprintf("%d. %s\n", i, leslie_movements$person_name[i]))
    cat(sprintf("   From: %s (FAC-%s)\n", 
                leslie_movements$from_hospital[i], leslie_movements$from_hospital_fac[i]))
    cat(sprintf("   To:   %s (FAC-%s)\n", 
                leslie_movements$to_hospital[i], leslie_movements$to_hospital_fac[i]))
    cat(sprintf("   Confidence: %.3f\n\n", leslie_movements$match_confidence[i]))
  }
} else {
  cat("✓ No Leslie Sanders movements detected\n")
  cat("  (Name format issue may still need normalization fix)\n\n")
}

# Check if they're in retained list (correct outcome)
doug_retained <- comparison_results$retained %>%
  filter(grepl("Earle", person_name, ignore.case = TRUE))

leslie_retained <- comparison_results$retained %>%
  filter(grepl("Sanders.*Leslie|Leslie.*Sanders", person_name, ignore.case = TRUE))

if (nrow(doug_retained) > 0) {
  cat("✓ Doug Earle found in RETAINED list (correct!)\n")
  cat(sprintf("  Hospital: %s\n", doug_retained$hospital_name[1]))
}

if (nrow(leslie_retained) > 0) {
  cat("✓ Leslie Sanders found in RETAINED list (correct!)\n")
  cat(sprintf("  Hospital: %s\n\n", leslie_retained$hospital_name[1]))
}

# =============================================================================
# SECTION 3: SAVE OUTPUT FILES
# =============================================================================

cat("\n╔═══════════════════════════════════════════════╗\n")
cat("║   SAVING OUTPUT FILES                         ║\n")
cat("╚═══════════════════════════════════════════════╝\n\n")

# Save updated master
write.csv(updated_master,
          "E:/ExecutiveSearchYaml/processed/PersonnelMaster_2026-01-01_FINAL.csv",
          row.names = FALSE)
cat("✓ Saved: PersonnelMaster_2026-01-01_FINAL.csv\n")

# Save comparison results
write.csv(comparison_results$retained,
          "E:/ExecutiveSearchYaml/output/temp/Retained_2026-01_FINAL.csv",
          row.names = FALSE)
cat("✓ Saved: Retained_2026-01_FINAL.csv\n")

write.csv(comparison_results$new_arrivals,
          "E:/ExecutiveSearchYaml/output/temp/NewArrivals_2026-01_FINAL.csv",
          row.names = FALSE)
cat("✓ Saved: NewArrivals_2026-01_FINAL.csv\n")

write.csv(comparison_results$departures,
          "E:/ExecutiveSearchYaml/output/temp/Departures_2026-01_FINAL.csv",
          row.names = FALSE)
cat("✓ Saved: Departures_2026-01_FINAL.csv\n")

write.csv(movements,
          "E:/ExecutiveSearchYaml/output/temp/Movements_2026-01_FINAL.csv",
          row.names = FALSE)
cat("✓ Saved: Movements_2026-01_FINAL.csv\n")

write.csv(comparison_results$hospital_summary,
          "E:/ExecutiveSearchYaml/output/temp/HospitalSummary_2026-01_FINAL.csv",
          row.names = FALSE)
cat("✓ Saved: HospitalSummary_2026-01_FINAL.csv\n")

# Save title changes
title_changes <- comparison_results$retained %>%
  filter(title_changed == TRUE) %>%
  select(person_id, person_name, hospital_name, title_dec, title_jan)

write.csv(title_changes,
          "E:/ExecutiveSearchYaml/output/temp/TitleChanges_2026-01_FINAL.csv",
          row.names = FALSE)
cat("✓ Saved: TitleChanges_2026-01_FINAL.csv\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n╔═══════════════════════════════════════════════╗\n")
cat("║   PHASE 3 COMPLETE - WITH RECOVERED DATA      ║\n")
cat("╚═══════════════════════════════════════════════╝\n\n")

cat("ACCOMPLISHMENTS:\n")
cat("─────────────────────────────────────────────────\n")
cat("✓ Recovered 3 failed hospitals (FAC 699, 930, 763)\n")
cat("✓ Reprocessed January data through pipeline\n")
cat("✓ Rebuilt PersonnelMaster with complete data\n")
cat("✓ Detected movements with updated dataset\n")
cat("✓ Generated all output files\n\n")

cat("FILES READY FOR FEBRUARY:\n")
cat("─────────────────────────────────────────────────\n")
cat("→ PersonnelMaster_2026-01-01_FINAL.csv (baseline for Feb)\n")
cat("→ All comparison files saved with _FINAL suffix\n\n")

cat("NEXT STEPS:\n")
cat("─────────────────────────────────────────────────\n")
cat("1. Review Doug Earle and Leslie Sanders cases above\n")
cat("2. Verify movement detection accuracy\n")
cat("3. Update YAML with working WRHN patterns\n")
cat("4. Monitor these 3 hospitals in February run\n\n")

cat("✓ Phase 3 restart complete!\n\n")

