# compare_yaml_status.R
# Compare enhanced_hospitals.yaml and next_batch_template.yaml
# Shows what's in each file and what overlaps
# Save in E:/ExecutiveSearchYaml/code/

library(yaml)
library(dplyr)

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║          COMPARE ENHANCED vs NEXT BATCH STATUS                 ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

compare_yaml_files <- function() {
  
  # Load files
  enhanced_file <- "enhanced_hospitals.yaml"
  next_batch_file <- "next_batch_template.yaml"
  
  if (!file.exists(enhanced_file)) {
    cat("⚠️  enhanced_hospitals.yaml not found\n")
    enhanced_config <- list(hospitals = list())
  } else {
    enhanced_config <- yaml::read_yaml(enhanced_file)
  }
  
  if (!file.exists(next_batch_file)) {
    cat("⚠️  next_batch_template.yaml not found\n")
    next_batch_config <- list(hospitals = list())
  } else {
    next_batch_config <- yaml::read_yaml(next_batch_file)
  }
  
  # Get FAC lists
  enhanced_facs <- sapply(enhanced_config$hospitals, function(h) h$FAC)
  next_batch_facs <- sapply(next_batch_config$hospitals, function(h) h$FAC)
  
  # Find overlaps
  in_both <- intersect(enhanced_facs, next_batch_facs)
  only_enhanced <- setdiff(enhanced_facs, next_batch_facs)
  only_next_batch <- setdiff(next_batch_facs, enhanced_facs)
  
  # Display results
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("FILE SUMMARY\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  cat("Enhanced hospitals:     ", length(enhanced_facs), "hospitals\n")
  cat("Next batch:             ", length(next_batch_facs), "hospitals\n")
  cat("In both files:          ", length(in_both), "hospitals\n")
  cat("Only in enhanced:       ", length(only_enhanced), "hospitals\n")
  cat("Only in next_batch:     ", length(only_next_batch), "hospitals\n\n")
  
  # Show duplicates if any
  if (length(in_both) > 0) {
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("⚠️  HOSPITALS IN BOTH FILES (", length(in_both), ")\n", sep = "")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    cat("These hospitals exist in both files. During merge, next_batch\n")
    cat("versions will be SKIPPED to preserve enhanced versions.\n\n")
    
    for (fac in sort(in_both)) {
      # Get names from both
      enh_hosp <- Find(function(h) h$FAC == fac, enhanced_config$hospitals)
      next_hosp <- Find(function(h) h$FAC == fac, next_batch_config$hospitals)
      
      cat("FAC-", fac, ":\n", sep = "")
      cat("  Enhanced:    ", substr(enh_hosp$name, 1, 50), "\n", sep = "")
      cat("  Next batch:  ", substr(next_hosp$name, 1, 50), "\n", sep = "")
      
      # Compare status
      enh_status <- enh_hosp$status %||% "not_set"
      next_status <- next_hosp$status %||% "not_set"
      
      if (enh_status != next_status) {
        cat("  Status diff: Enhanced='", enh_status, 
            "', Next='", next_status, "'\n", sep = "")
      }
      cat("\n")
    }
    
    cat("RECOMMENDATION: Remove duplicates from next_batch_template.yaml\n")
    cat("                or leave them (they'll be skipped during merge)\n\n")
  }
  
  # Show next_batch breakdown
  if (length(next_batch_facs) > 0) {
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("NEXT BATCH STATUS BREAKDOWN\n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    # Count by status
    status_list <- sapply(next_batch_config$hospitals, function(h) h$status %||% "not_set")
    status_table <- table(status_list)
    
    for (status in names(status_table)) {
      count <- status_table[[status]]
      pct <- round(count/length(next_batch_facs)*100, 1)
      
      # Add emoji indicators
      emoji <- switch(status,
                      "ok" = "✅",
                      "configured" = "✅",
                      "tested_ok" = "✅",
                      "needs_testing" = "🔄",
                      "needs_url" = "⚠️",
                      "needs_work" = "⚠️",
                      "closed" = "🚫",
                      "ℹ️")
      
      cat(sprintf("%s %-20s %3d (%5.1f%%)\n", emoji, status, count, pct))
    }
    
    # Ready to merge count
    ready_to_merge <- sum(sapply(next_batch_config$hospitals, function(h) {
      status <- h$status %||% ""
      status %in% c("ok", "configured", "tested_ok")
    }))
    
    # But exclude duplicates
    ready_unique <- sum(sapply(next_batch_config$hospitals, function(h) {
      status <- h$status %||% ""
      fac <- h$FAC
      status %in% c("ok", "configured", "tested_ok") && !(fac %in% in_both)
    }))
    
    cat("\n")
    cat("Ready to merge:         ", ready_to_merge, " total\n", sep = "")
    if (ready_to_merge != ready_unique) {
      cat("  (", ready_unique, " unique, ", 
          ready_to_merge - ready_unique, " are duplicates)\n", sep = "")
    }
    
    # Ready to test
    ready_to_test <- sum(sapply(next_batch_config$hospitals, function(h) {
      status <- h$status %||% ""
      url <- h$url %||% ""
      status == "needs_testing" && !grepl("TODO", url, fixed = TRUE)
    }))
    
    if (ready_to_test > 0) {
      cat("\n")
      cat("✅ ", ready_to_test, " hospitals ready to test\n", sep = "")
      cat("   Run: source('test_next_batch.R'); test_ready()\n")
    }
    
    if (ready_unique > 0) {
      cat("\n")
      cat("✅ ", ready_unique, " unique hospitals ready to merge\n", sep = "")
      cat("   Run: source('merge_tested_to_enhanced.R'); merge_tested()\n")
    }
  }
  
  # Show enhanced breakdown
  if (length(enhanced_facs) > 0) {
    cat("\n═══════════════════════════════════════════════════════════════\n")
    cat("ENHANCED HOSPITALS STATUS BREAKDOWN\n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    status_list <- sapply(enhanced_config$hospitals, function(h) h$status %||% "not_set")
    status_table <- table(status_list)
    
    for (status in names(status_table)) {
      count <- status_table[[status]]
      pct <- round(count/length(enhanced_facs)*100, 1)
      cat(sprintf("  %-20s %3d (%5.1f%%)\n", status, count, pct))
    }
  }
  
  # Master list comparison
  master_file <- "E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx"
  if (file.exists(master_file)) {
    cat("\n═══════════════════════════════════════════════════════════════\n")
    cat("MASTER EXCEL FILE COMPARISON\n")
    cat("═══════════════════════════════════════════════════════════════\n\n")
    
    tryCatch({
      library(readxl)
      master <- read_excel(master_file)
      
      # Format FACs
      master$FAC_formatted <- sprintf("%03d", as.numeric(master$FAC))
      
      # Count done
      done_count <- sum(master$done == "y", na.rm = TRUE)
      total_count <- nrow(master)
      
      cat("Total in master file:   ", total_count, "\n")
      cat("Marked as done='y':     ", done_count, "\n")
      cat("Remaining:              ", total_count - done_count, "\n\n")
      
      # Check if enhanced matches done
      enhanced_in_master <- sum(enhanced_facs %in% master$FAC_formatted)
      done_in_master <- master$FAC_formatted[master$done == "y"]
      enhanced_marked_done <- sum(enhanced_facs %in% done_in_master)
      
      cat("Enhanced hospitals in master:     ", enhanced_in_master, "\n")
      cat("Enhanced hospitals marked done:   ", enhanced_marked_done, "\n")
      
      if (enhanced_marked_done < length(enhanced_facs)) {
        not_marked <- enhanced_facs[!(enhanced_facs %in% done_in_master)]
        cat("\n⚠️  ", length(not_marked), " enhanced hospitals not marked done='y':\n", sep = "")
        cat("   ", paste(not_marked[1:min(10, length(not_marked))], collapse = ", "))
        if (length(not_marked) > 10) cat(", ...")
        cat("\n")
      }
      
    }, error = function(e) {
      cat("Could not read master Excel file\n")
    })
  }
  
  cat("\n═══════════════════════════════════════════════════════════════\n\n")
  
  # Return summary
  return(invisible(list(
    enhanced_count = length(enhanced_facs),
    next_batch_count = length(next_batch_facs),
    duplicates = in_both,
    only_enhanced = only_enhanced,
    only_next_batch = only_next_batch
  )))
}

# Run comparison
result <- compare_yaml_files()

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("QUICK ACTIONS\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
cat("# Test next batch hospitals:\n")
cat("source('test_next_batch.R')\n")
cat("status_next()         # Show status\n")
cat("test_ready()          # Test all ready hospitals\n\n")
cat("# Merge to enhanced:\n")
cat("source('merge_tested_to_enhanced.R')\n")
cat("merge_tested()        # Interactive merge\n\n")
cat("# Check project status:\n")
cat("source('project_status.R')\n\n")
cat("═══════════════════════════════════════════════════════════════\n")