# ==============================================================================
# MASTER PERSONNEL REFERENCE - CORE FUNCTIONS
# Phase 3.1 - Simple Dec→Jan Comparison
# Author: Skip
# Date: January 2026
# ==============================================================================

library(dplyr)
library(stringr)
library(stringdist)
library(lubridate)

# ------------------------------------------------------------------------------
# FUNCTION 1: Initialize Personnel Master from December Baseline
# ------------------------------------------------------------------------------

initialize_personnel_master <- function(dec_employees, dec_volunteers, baseline_date) {
  #
  # Creates the initial PersonnelMaster.csv from December baseline
  # Each person gets a unique person_id
  #
  # Inputs:
  #   dec_employees: HospitalExecutives_Employees_2025-12-01.csv
  #   dec_volunteers: HospitalExecutives_Volunteers_2025-12-01.csv
  #   baseline_date: "2025-12-01"
  #
  
  # Combine employees and volunteers
  all_people <- bind_rows(
    dec_employees %>% mutate(person_type = "Employee"),
    dec_volunteers %>% mutate(person_type = "Volunteer")
  )
  
  # Generate sequential person_ids
  all_people <- all_people %>%
    mutate(
      person_id = sprintf("P%08d", row_number()),
      current_hospital = hospital_name,
      current_hospital_fac = fac_number,
      current_title = title,
      current_type = person_type,
      first_seen = as.Date(baseline_date),
      last_seen = as.Date(baseline_date),
      status = "active",
      months_missing = 0,
      total_appearances = 1
    ) %>%
    select(
      person_id,
      person_name,
      credentials,
      current_hospital,
      current_hospital_fac,
      current_title,
      current_type,
      first_seen,
      last_seen,
      status,
      months_missing,
      total_appearances
    )
  
  cat(sprintf("Initialized PersonnelMaster with %d people\n", nrow(all_people)))
  
  return(all_people)
}

# ------------------------------------------------------------------------------
# FUNCTION 2: Compare Single Hospital Dec vs Jan
# ------------------------------------------------------------------------------

compare_hospital_months <- function(hospital_fac, dec_data, jan_data, 
                                    personnel_master) {
  #
  # For one hospital, identify what changed between Dec and Jan
  #
  
  # Filter to this hospital
  dec_hospital <- dec_data %>% filter(fac_number == hospital_fac)
  jan_hospital <- jan_data %>% filter(fac_number == hospital_fac)
  
  # Get person_ids for this hospital from master
  master_hospital <- personnel_master %>% 
    filter(current_hospital_fac == hospital_fac)
  
  # Simple exact name matching within same hospital
  dec_names <- dec_hospital$person_name
  jan_names <- jan_hospital$person_name
  
  retained_names <- intersect(dec_names, jan_names)
  new_names <- setdiff(jan_names, dec_names)
  departed_names <- setdiff(dec_names, jan_names)
  
  # Build result sets
  retained <- jan_hospital %>% 
    filter(person_name %in% retained_names) %>%
    left_join(master_hospital %>% select(person_name, person_id), 
              by = "person_name")
  
  # Check for title changes in retained people
  if (nrow(retained) > 0) {
    retained <- retained %>%
      left_join(dec_hospital %>% select(person_name, title), 
                by = "person_name", suffix = c("_jan", "_dec")) %>%
      mutate(title_changed = (title_jan != title_dec))
  }
  
  new_arrivals <- jan_hospital %>% 
    filter(person_name %in% new_names)
  
  departures <- dec_hospital %>% 
    filter(person_name %in% departed_names) %>%
    left_join(master_hospital %>% select(person_name, person_id), 
              by = "person_name")
  
  return(list(
    hospital_fac = hospital_fac,
    hospital_name = ifelse(nrow(jan_hospital) > 0, 
                           jan_hospital$hospital_name[1], 
                           dec_hospital$hospital_name[1]),
    retained = retained,
    new_arrivals = new_arrivals,
    departures = departures
  ))
}

# ------------------------------------------------------------------------------
# FUNCTION 3: Process All Hospitals Dec vs Jan
# ------------------------------------------------------------------------------

compare_all_hospitals <- function(dec_employees, dec_volunteers,
                                  jan_employees, jan_volunteers,
                                  personnel_master) {
  #
  # Run comparison for every hospital
  #
  
  # Combine employees and volunteers for each month
  dec_all <- bind_rows(
    dec_employees %>% mutate(person_type = "Employee"),
    dec_volunteers %>% mutate(person_type = "Volunteer")
  )
  
  jan_all <- bind_rows(
    jan_employees %>% mutate(person_type = "Employee"),
    jan_volunteers %>% mutate(person_type = "Volunteer")
  )
  
  # Get unique hospital list
  hospitals <- unique(c(dec_all$fac_number, jan_all$fac_number))
  
  all_retained <- data.frame()
  all_new <- data.frame()
  all_departed <- data.frame()
  
  hospital_summary <- data.frame()
  
  for (fac in hospitals) {
    result <- compare_hospital_months(fac, dec_all, jan_all, personnel_master)
    
    all_retained <- bind_rows(all_retained, result$retained)
    all_new <- bind_rows(all_new, result$new_arrivals)
    all_departed <- bind_rows(all_departed, result$departures)
    
    # Summary stats
    hospital_summary <- bind_rows(hospital_summary, data.frame(
      hospital_fac = result$hospital_fac,
      hospital_name = result$hospital_name,
      retained_count = nrow(result$retained),
      new_count = nrow(result$new_arrivals),
      departed_count = nrow(result$departures),
      title_changes = sum(result$retained$title_changed, na.rm = TRUE),
      stringsAsFactors = FALSE
    ))
  }
  
  cat("\n=== HOSPITAL-BY-HOSPITAL COMPARISON SUMMARY ===\n")
  cat(sprintf("Total hospitals processed: %d\n", nrow(hospital_summary)))
  cat(sprintf("Total retained: %d\n", nrow(all_retained)))
  cat(sprintf("Total new arrivals: %d\n", nrow(all_new)))
  cat(sprintf("Total departures: %d\n", nrow(all_departed)))
  cat(sprintf("Total title changes: %d\n", sum(hospital_summary$title_changes)))
  cat("\n")
  
  return(list(
    retained = all_retained,
    new_arrivals = all_new,
    departures = all_departed,
    hospital_summary = hospital_summary
  ))
}

# ------------------------------------------------------------------------------
# FUNCTION 4: Detect Cross-Hospital Movements (Simple Fuzzy Match)
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# FUNCTION 4: Detect Cross-Hospital Movements (Fixed for NA handling)
# ------------------------------------------------------------------------------

detect_simple_movements <- function(departures, new_arrivals, threshold = 0.85) {
  #
  # Simple fuzzy matching between departures and new arrivals
  # Only matches across different hospitals
  #
  
  if (nrow(departures) == 0 || nrow(new_arrivals) == 0) {
    cat("No departures or no new arrivals - no movements to detect\n")
    return(data.frame())
  }
  
  movements <- data.frame()
  
  cat(sprintf("\nSearching for movements: %d departures x %d arrivals = %d comparisons\n",
              nrow(departures), nrow(new_arrivals), 
              nrow(departures) * nrow(new_arrivals)))
  
  for (i in 1:nrow(departures)) {
    dep_name <- departures$person_name[i]
    dep_cred <- departures$credentials[i]
    dep_hospital <- departures$fac_number[i]
    
    # Skip if name is NA or empty
    if (is.na(dep_name) || dep_name == "") next
    
    for (j in 1:nrow(new_arrivals)) {
      arr_name <- new_arrivals$person_name[j]
      arr_cred <- new_arrivals$credentials[j]
      arr_hospital <- new_arrivals$fac_number[j]
      
      # Skip if name is NA or empty
      if (is.na(arr_name) || arr_name == "") next
      
      # Skip same hospital (shouldn't happen, but safety check)
      if (dep_hospital == arr_hospital) next
      
      # Normalize names
      dep_norm <- toupper(str_trim(dep_name))
      arr_norm <- toupper(str_trim(arr_name))
      
      # Calculate Jaro-Winkler similarity
      name_sim <- stringsim(dep_norm, arr_norm, method = "jw")
      
      # Handle NA from stringsim
      if (is.na(name_sim)) next
      
      # Simple credential check
      cred_bonus <- 0
      if (!is.na(dep_cred) && !is.na(arr_cred) && 
          dep_cred != "" && arr_cred != "" &&
          nchar(dep_cred) > 0 && nchar(arr_cred) > 0) {
        if (dep_cred == arr_cred) {
          cred_bonus <- 0.10  # Exact match
        }
      }
      
      final_confidence <- name_sim + cred_bonus
      
      # Final check for NA
      if (is.na(final_confidence)) next
      
      if (final_confidence >= threshold) {
        movements <- bind_rows(movements, data.frame(
          person_id = departures$person_id[i],
          person_name = dep_name,
          from_hospital_fac = dep_hospital,
          from_hospital = departures$hospital_name[i],
          from_title = departures$title[i],
          to_hospital_fac = arr_hospital,
          to_hospital = new_arrivals$hospital_name[j],
          to_title = new_arrivals$title[j],
          match_confidence = final_confidence,
          name_similarity = name_sim,
          credential_bonus = cred_bonus,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  if (nrow(movements) > 0) {
    movements <- movements %>% arrange(desc(match_confidence))
    cat(sprintf("Found %d potential movements\n", nrow(movements)))
  } else {
    cat("No movements detected above threshold\n")
  }
  
  return(movements)
}

# ------------------------------------------------------------------------------
# FUNCTION 5: Update Personnel Master with January Data
# ------------------------------------------------------------------------------

update_personnel_master <- function(personnel_master, comparison_results, 
                                    movements, run_date) {
  #
  # Update the master file based on Jan comparison
  #
  
  updated_master <- personnel_master
  
  # 1. Update RETAINED people (still at same hospital)
  if (nrow(comparison_results$retained) > 0) {
    for (i in 1:nrow(comparison_results$retained)) {
      person_id <- comparison_results$retained$person_id[i]
      
      idx <- which(updated_master$person_id == person_id)
      if (length(idx) > 0) {
        updated_master$last_seen[idx] <- as.Date(run_date)
        updated_master$total_appearances[idx] <- updated_master$total_appearances[idx] + 1
        updated_master$status[idx] <- "active"
        updated_master$months_missing[idx] <- 0
        
        # Update title if changed
        if (comparison_results$retained$title_changed[i]) {
          updated_master$current_title[idx] <- comparison_results$retained$title_jan[i]
        }
      }
    }
  }
  
  # 2. Update MOVED people (detected movements)
  if (nrow(movements) > 0) {
    for (i in 1:nrow(movements)) {
      person_id <- movements$person_id[i]
      
      idx <- which(updated_master$person_id == person_id)
      if (length(idx) > 0) {
        updated_master$current_hospital[idx] <- movements$to_hospital[i]
        updated_master$current_hospital_fac[idx] <- movements$to_hospital_fac[i]
        updated_master$current_title[idx] <- movements$to_title[i]
        updated_master$last_seen[idx] <- as.Date(run_date)
        updated_master$total_appearances[idx] <- updated_master$total_appearances[idx] + 1
        updated_master$status[idx] <- "active"
        updated_master$months_missing[idx] <- 0
      }
    }
  }
  
  # 3. Mark DEPARTED people (not retained, not moved)
  departed_person_ids <- comparison_results$departures$person_id
  moved_person_ids <- movements$person_id
  truly_departed_ids <- setdiff(departed_person_ids, moved_person_ids)
  
  for (person_id in truly_departed_ids) {
    idx <- which(updated_master$person_id == person_id)
    if (length(idx) > 0) {
      updated_master$months_missing[idx] <- updated_master$months_missing[idx] + 1
      updated_master$status[idx] <- "missing_1_month"
    }
  }
  
  # 4. Add NEW people (assign new person_ids)
  new_people_to_add <- comparison_results$new_arrivals %>%
    anti_join(movements, by = c("person_name", "fac_number" = "to_hospital_fac"))
  
  if (nrow(new_people_to_add) > 0) {
    # Generate new person_ids
    max_id <- max(as.numeric(sub("P", "", updated_master$person_id)))
    
    new_people <- new_people_to_add %>%
      mutate(
        person_id = sprintf("P%08d", max_id + row_number()),
        current_hospital = hospital_name,
        current_hospital_fac = fac_number,
        current_title = title,
        current_type = person_type,
        first_seen = as.Date(run_date),
        last_seen = as.Date(run_date),
        status = "active",
        months_missing = 0,
        total_appearances = 1
      ) %>%
      select(
        person_id,
        person_name,
        credentials,
        current_hospital,
        current_hospital_fac,
        current_title,
        current_type,
        first_seen,
        last_seen,
        status,
        months_missing,
        total_appearances
      )
    
    updated_master <- bind_rows(updated_master, new_people)
    
    cat(sprintf("Added %d new people to master\n", nrow(new_people)))
  }
  
  return(updated_master)
}

# ------------------------------------------------------------------------------
# FUNCTION 6: Generate Summary Reports
# ------------------------------------------------------------------------------

generate_summary_report <- function(comparison_results, movements, 
                                    personnel_master_before, 
                                    personnel_master_after) {
  #
  # Print summary statistics
  #
  
  cat("\n")
  cat("========================================\n")
  cat("   DEC → JAN COMPARISON SUMMARY\n")
  cat("========================================\n\n")
  
  cat("PEOPLE COUNTS:\n")
  cat(sprintf("  Master (before): %d\n", nrow(personnel_master_before)))
  cat(sprintf("  Master (after):  %d\n", nrow(personnel_master_after)))
  cat(sprintf("  New people added: %d\n", 
              nrow(personnel_master_after) - nrow(personnel_master_before)))
  cat("\n")
  
  cat("JANUARY STATUS:\n")
  cat(sprintf("  Retained at same hospital: %d\n", nrow(comparison_results$retained)))
  cat(sprintf("  Moved to different hospital: %d\n", nrow(movements)))
  cat(sprintf("  New to system: %d\n", nrow(comparison_results$new_arrivals) - nrow(movements)))
  cat(sprintf("  Missing (departed Dec, not found Jan): %d\n", 
              nrow(comparison_results$departures) - nrow(movements)))
  cat("\n")
  
  cat("TITLE CHANGES:\n")
  title_changes <- comparison_results$retained %>% 
    filter(title_changed == TRUE)
  cat(sprintf("  People with title changes (same hospital): %d\n", nrow(title_changes)))
  cat("\n")
  
  cat("MOVEMENTS DETECTED:\n")
  if (nrow(movements) > 0) {
    cat(sprintf("  Total movements: %d\n", nrow(movements)))
    cat(sprintf("  Average confidence: %.3f\n", mean(movements$match_confidence)))
    cat(sprintf("  Min confidence: %.3f\n", min(movements$match_confidence)))
    cat(sprintf("  Max confidence: %.3f\n", max(movements$match_confidence)))
  } else {
    cat("  No movements detected\n")
  }
  cat("\n")
  
  cat("MASTER STATUS BREAKDOWN:\n")
  status_summary <- personnel_master_after %>%
    group_by(status) %>%
    summarize(count = n(), .groups = "drop")
  print(status_summary)
  cat("\n")
}

