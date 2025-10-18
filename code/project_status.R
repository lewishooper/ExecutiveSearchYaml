# project_status.R - Detailed project status dashboard
# Run this anytime to see comprehensive project status
# Save in E:/ExecutiveSearchYaml/code/

# project_status.R - Detailed project status dashboard
# Save in E:/ExecutiveSearchYaml/code/

library(dplyr)
library(yaml)

# ENSURE WE'RE IN THE RIGHT DIRECTORY
setwd("E:/ExecutiveSearchYaml/code/")

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║        HOSPITAL SCRAPER PROJECT - STATUS DASHBOARD             ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║        HOSPITAL SCRAPER PROJECT - STATUS DASHBOARD             ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# ═══════════════════════════════════════════════════════════════════
# CONFIGURED HOSPITALS ANALYSIS
# ═══════════════════════════════════════════════════════════════════

if (!file.exists("enhanced_hospitals.yaml")) {
  cat("⚠ enhanced_hospitals.yaml not found\n")
  stop("Cannot generate status report")
}

config <- yaml::read_yaml("enhanced_hospitals.yaml")

cat("═══════════════════════════════════════════════════════════════\n")
cat("                 CONFIGURED HOSPITALS SUMMARY                   \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

total_hospitals <- length(config$hospitals)
cat("Total configured:", total_hospitals, "\n\n")

# Status breakdown
status_counts <- table(sapply(config$hospitals, function(h) h$status %||% "unknown"))
cat("Status breakdown:\n")
for (status in names(sort(status_counts, decreasing = TRUE))) {
  cat(sprintf("  %-20s: %3d (%5.1f%%)\n", 
              status, 
              status_counts[status],
              status_counts[status]/total_hospitals*100))
}

# Pattern usage
cat("\n───────────────────────────────────────────────────────────────\n")
cat("Pattern usage:\n")
pattern_counts <- table(sapply(config$hospitals, function(h) h$pattern))
pattern_counts <- sort(pattern_counts, decreasing = TRUE)

for (pattern in names(pattern_counts)) {
  cat(sprintf("  %-30s: %3d (%5.1f%%)\n", 
              pattern, 
              pattern_counts[pattern],
              pattern_counts[pattern]/total_hospitals*100))
}

# Hospitals with missing_people
missing_people_count <- sum(sapply(config$hospitals, function(h) 
  !is.null(h$html_structure$missing_people)))

cat("\n───────────────────────────────────────────────────────────────\n")
cat("Special features:\n")
cat("  Hospitals with missing_people:", missing_people_count, "\n")

# Expected executives stats
expected_execs <- sapply(config$hospitals, function(h) h$expected_executives %||% NA)
expected_execs <- expected_execs[!is.na(expected_execs)]

if (length(expected_execs) > 0) {
  cat("  Total expected executives:", sum(expected_execs), "\n")
  cat("  Average per hospital:", round(mean(expected_execs), 1), "\n")
  cat("  Range:", min(expected_execs), "-", max(expected_execs), "\n")
}

# ═══════════════════════════════════════════════════════════════════
# BATCH PROGRESS
# ═══════════════════════════════════════════════════════════════════

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    CURRENT BATCH STATUS                        \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

if (file.exists("next_batch_template.yaml")) {
  batch_config <- yaml::read_yaml("next_batch_template.yaml")
  
  if (!is.null(batch_config$hospitals)) {
    batch_total <- length(batch_config$hospitals)
    
    # Categorize hospitals
    needs_url <- sum(sapply(batch_config$hospitals, function(h) 
      grepl("TODO", h$url %||% "", fixed = TRUE)))
    
    needs_testing <- sum(sapply(batch_config$hospitals, function(h) 
      (h$status %||% "") == "needs_testing"))
    
    configured <- sum(sapply(batch_config$hospitals, function(h) 
      (h$status %||% "") %in% c("configured", "ok")))
    
    needs_url_but_ready <- sum(sapply(batch_config$hospitals, function(h) 
      (h$status %||% "") == "needs_url" && !grepl("TODO", h$url %||% "", fixed = TRUE)))
    
    closed <- sum(sapply(batch_config$hospitals, function(h) 
      (h$status %||% "") == "closed"))
    
    cat("Batch size:", batch_total, "\n\n")
    
    cat("Progress:\n")
    cat(sprintf("  Configured (done):     %3d (%5.1f%%)\n", 
                configured, configured/batch_total*100))
    cat(sprintf("  Ready to test:         %3d (%5.1f%%)\n", 
                needs_testing, needs_testing/batch_total*100))
    cat(sprintf("  Has URL, needs config: %3d (%5.1f%%)\n", 
                needs_url_but_ready, needs_url_but_ready/batch_total*100))
    cat(sprintf("  Needs URL:             %3d (%5.1f%%)\n", 
                needs_url, needs_url/batch_total*100))
    cat(sprintf("  Closed/Merged:         %3d (%5.1f%%)\n", 
                closed, closed/batch_total*100))
    
    # Progress bar
    pct_done <- configured/batch_total*100
    bar_length <- 40
    filled <- round(bar_length * pct_done / 100)
    empty <- bar_length - filled
    
    cat("\nOverall batch progress:\n")
    cat("  [", rep("█", filled), rep("░", empty), "] ", 
        sprintf("%.1f%%", pct_done), "\n", sep = "")
    
    # Time estimate
    if (configured > 0) {
      remaining <- batch_total - configured - closed
      avg_time_per_hospital <- 7.5  # minutes
      estimated_minutes <- remaining * avg_time_per_hospital
      
      cat("\nEstimated time remaining:", 
          sprintf("%.1f hours", estimated_minutes/60), 
          sprintf("(%d hospitals × %.1f min each)\n", remaining, avg_time_per_hospital))
    }
  }
} else {
  cat("No batch template found.\n")
  cat("Run source('generate_yaml_template.R') to create next batch.\n")
}

# ═══════════════════════════════════════════════════════════════════
# DETAILED HOSPITAL LIST
# ═══════════════════════════════════════════════════════════════════

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    CONFIGURED HOSPITALS LIST                   \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Create summary dataframe
hospital_summary <- data.frame(
  FAC = sapply(config$hospitals, function(h) h$FAC),
  Name = sapply(config$hospitals, function(h) {
    name <- h$name
    if (nchar(name) > 35) {
      paste0(substr(name, 1, 32), "...")
    } else {
      name
    }
  }),
  Pattern = sapply(config$hospitals, function(h) {
    pattern <- h$pattern
    # Shorten pattern names for display
    pattern <- gsub("h2_name_h3_title", "h2→h3", pattern)
    pattern <- gsub("combined_h2", "combined", pattern)
    pattern <- gsub("div_classes", "div-class", pattern)
    pattern <- gsub("list_items", "list", pattern)
    pattern <- gsub("table_rows", "table", pattern)
    pattern <- gsub("h2_name_p_title", "h2→p", pattern)
    pattern <- gsub("boardcard_gallery", "gallery", pattern)
    pattern <- gsub("field_content_sequential", "seq-field", pattern)
    pattern <- gsub("nested_list_with_ids", "nested-id", pattern)
    pattern <- gsub("qch_mixed_tables", "qch-mixed", pattern)
    pattern <- gsub("custom_table_nested", "tbl-nested", pattern)
    pattern <- gsub("manual_entry_required", "manual", pattern)
    pattern
  }),
  Status = sapply(config$hospitals, function(h) h$status %||% "unknown"),
  Expected = sapply(config$hospitals, function(h) h$expected_executives %||% NA),
  stringsAsFactors = FALSE
)

# Sort by FAC
hospital_summary <- hospital_summary %>% arrange(FAC)

# Display in groups of 10
cat("Showing first 15 hospitals:\n")
cat(sprintf("%-6s %-36s %-12s %-12s %s\n", 
            "FAC", "Name", "Pattern", "Status", "Exp"))
cat(rep("─", 80), "\n", sep = "")

for (i in 1:min(15, nrow(hospital_summary))) {
  cat(sprintf("%-6s %-36s %-12s %-12s %3s\n",
              hospital_summary$FAC[i],
              hospital_summary$Name[i],
              hospital_summary$Pattern[i],
              hospital_summary$Status[i],
              ifelse(is.na(hospital_summary$Expected[i]), "-", 
                     as.character(hospital_summary$Expected[i]))))
}

if (nrow(hospital_summary) > 15) {
  cat("... and", nrow(hospital_summary) - 15, "more hospitals\n")
}

# ═══════════════════════════════════════════════════════════════════
# NEXT HOSPITALS TO WORK ON
# ═══════════════════════════════════════════════════════════════════

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    NEXT HOSPITALS TO CONFIGURE                 \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

if (file.exists("next_batch_template.yaml")) {
  batch_config <- yaml::read_yaml("next_batch_template.yaml")
  
  if (!is.null(batch_config$hospitals)) {
    # Find hospitals that need work
    next_hospitals <- batch_config$hospitals[sapply(batch_config$hospitals, function(h) 
      !(h$status %||% "") %in% c("configured", "ok", "closed"))]
    
    if (length(next_hospitals) > 0) {
      cat("Recommended order (next 5 hospitals):\n\n")
      
      for (i in 1:min(5, length(next_hospitals))) {
        h <- next_hospitals[[i]]
        has_url <- !is.null(h$url) && !grepl("TODO", h$url)
        
        cat(sprintf("%d. FAC-%s: %s\n", i, h$FAC, h$name))
        cat(sprintf("   URL: %s\n", 
                    if(has_url) "✓ Available" else "⚠ Needs to be added"))
        cat(sprintf("   Status: %s\n", h$status %||% "unknown"))
        
        if (has_url) {
          cat("   Next step: Run helper$analyze_hospital_structure()\n")
        } else {
          cat("   Next step: Find leadership page URL\n")
        }
        cat("\n")
      }
      
      if (length(next_hospitals) > 5) {
        cat("... and", length(next_hospitals) - 5, "more hospitals to configure\n")
      }
    } else {
      cat("🎉 All hospitals in current batch are configured!\n")
      cat("Run source('generate_yaml_template.R') to create next batch.\n")
    }
  }
}

# ═══════════════════════════════════════════════════════════════════
# RECENT ACTIVITY
# ═══════════════════════════════════════════════════════════════════

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    RECENT ACTIVITY                             \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Check for recent output files
output_dir <- "../output"
if (dir.exists(output_dir)) {
  all_outputs <- list.files(output_dir, 
                            pattern = "\\.csv$",
                            full.names = TRUE)
  
  if (length(all_outputs) > 0) {
    # Get most recent files
    file_info <- file.info(all_outputs)
    file_info$name <- basename(rownames(file_info))
    file_info <- file_info[order(file_info$mtime, decreasing = TRUE), ]
    
    recent_files <- head(file_info, 5)
    
    cat("Recent output files:\n")
    for (i in 1:nrow(recent_files)) {
      cat(sprintf("  %d. %s\n", i, recent_files$name[i]))
      cat(sprintf("     Modified: %s\n", 
                  format(recent_files$mtime[i], "%Y-%m-%d %H:%M")))
      cat(sprintf("     Size: %.1f KB\n", recent_files$size[i]/1024))
      cat("\n")
    }
  } else {
    cat("No output files found yet.\n")
  }
} else {
  cat("Output directory not found.\n")
}

# ═══════════════════════════════════════════════════════════════════
# QUICK STATS SUMMARY
# ═══════════════════════════════════════════════════════════════════

cat("═══════════════════════════════════════════════════════════════\n")
cat("                    QUICK STATS SUMMARY                         \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("PROJECT SNAPSHOT:\n")
cat(sprintf("  • Total configured hospitals: %d\n", total_hospitals))
if (exists("batch_total") && exists("configured")) {
  cat(sprintf("  • Current batch progress: %d/%d (%.1f%%)\n", 
              configured, batch_total, configured/batch_total*100))
}
cat(sprintf("  • Most common pattern: %s (%d hospitals)\n", 
            names(pattern_counts)[1], pattern_counts[1]))
cat(sprintf("  • Hospitals with missing_people: %d\n", missing_people_count))

if (exists("expected_execs") && length(expected_execs) > 0) {
  cat(sprintf("  • Total expected executives: %d\n", sum(expected_execs)))
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

cat("✓ Status report complete!\n\n")

cat("AVAILABLE COMMANDS:\n")
cat("  source('session_startup.R')     # Start session\n")
cat("  source('session_shutdown.R')    # End session\n")
cat("  source('project_status.R')      # This report\n")
cat("  quick_test(FAC)                 # Test hospital\n")
cat("  helper$analyze_hospital_structure()  # Analyze HTML\n\n")

source('project_status.R')   

