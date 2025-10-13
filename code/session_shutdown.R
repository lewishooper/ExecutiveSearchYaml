# session_shutdown.R - End of session checklist and cleanup
# Run this at the end of each work session
# Save in E:/ExecutiveSearchYaml/code/

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║          HOSPITAL SCRAPER PROJECT - SESSION SHUTDOWN           ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Calculate session duration
if (exists(".session_start")) {
  duration <- difftime(Sys.time(), .session_start, units = "hours")
  cat("Session duration:", round(duration, 2), "hours\n\n")
}

cat("═══════════════════════════════════════════════════════════════\n")
cat("                    SESSION SUMMARY                             \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Count what was accomplished
if (file.exists("enhanced_hospitals.yaml")) {
  config <- yaml::read_yaml("enhanced_hospitals.yaml")
  cat("Total configured hospitals:", length(config$hospitals), "\n")
  
  # Count by status
  configured_count <- sum(sapply(config$hospitals, function(h) 
    (h$status %||% "") %in% c("configured", "ok")))
  testing_count <- sum(sapply(config$hospitals, function(h) 
    (h$status %||% "") == "needs_testing"))
  
  cat("  Complete:", configured_count, "\n")
  cat("  Needs testing:", testing_count, "\n")
}

# Check batch progress
if (file.exists("next_batch_template.yaml")) {
  batch_config <- yaml::read_yaml("next_batch_template.yaml")
  if (!is.null(batch_config$hospitals)) {
    batch_total <- length(batch_config$hospitals)
    batch_done <- sum(sapply(batch_config$hospitals, function(h) 
      (h$status %||% "") %in% c("configured", "ok")))
    
    cat("\nBatch progress:\n")
    cat("  Completed:", batch_done, "of", batch_total, "\n")
    cat("  Remaining:", batch_total - batch_done, "\n")
    
    if (batch_done > 0) {
      cat("  Progress:", round(batch_done/batch_total*100, 1), "%\n")
    }
  }
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    END OF SESSION CHECKLIST                    \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Checklist
checklist <- data.frame(
  Task = c(
    "Save all modified files",
    "Commit to Git (if using)",
    "Update SESSION_LOG.md with today's progress",
    "Mark completed hospitals in Excel (done='y')",
    "Upload updated files to Claude project",
    "Note any issues/blockers for next session",
    "Identify next 3-5 hospitals to tackle"
  ),
  Done = rep("[ ]", 7),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(checklist)) {
  cat(checklist$Done[i], checklist$Task[i], "\n")
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    FILES TO UPLOAD TO CLAUDE                   \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Before next session, upload these files to Claude:\n\n")

# List modified files
important_files <- c(
  "enhanced_hospitals.yaml",
  "next_batch_template.yaml",
  "SESSION_LOG.md",
  "pattern_based_scraper.R",
  "hospital_configuration_helper.R",
  "quick_test_single.R"
)

cat("CRITICAL FILES (always upload):\n")
for (file in important_files) {
  if (file.exists(file)) {
    mod_time <- file.info(file)$mtime
    cat("  ✓", file, "\n")
    cat("    Last modified:", format(mod_time, "%Y-%m-%d %H:%M:%S"), "\n")
  } else {
    cat("  ⚠", file, "(missing)\n")
  }
}

# Check for new output files
output_files <- list.files("../output", 
                           pattern = "test_summary.*\\.csv$|all_hospitals.*\\.csv$",
                           full.names = FALSE)
if (length(output_files) > 0) {
  cat("\nRECENT OUTPUT FILES:\n")
  latest_outputs <- tail(output_files[order(file.info(paste0("../output/", output_files))$mtime)], 3)
  for (file in latest_outputs) {
    cat("  •", file, "\n")
  }
  cat("  (Upload if you want Claude to analyze test results)\n")
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    NEXT SESSION PREPARATION                    \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("TO START NEXT SESSION:\n")
cat("  1. Upload updated files to Claude (see list above)\n")
cat("  2. Tell Claude: 'Let's resume the hospital scraper project'\n")
cat("  3. Run: source('session_startup.R')\n")
cat("  4. Review SESSION_LOG.md for context\n")
cat("  5. Continue with next hospital in batch\n\n")

# Suggest what to work on next
if (file.exists("next_batch_template.yaml")) {
  batch_config <- yaml::read_yaml("next_batch_template.yaml")
  if (!is.null(batch_config$hospitals)) {
    # Find next hospital to configure
    next_hospitals <- batch_config$hospitals[sapply(batch_config$hospitals, function(h) 
      !(h$status %||% "") %in% c("configured", "ok"))]
    
    if (length(next_hospitals) > 0) {
      cat("SUGGESTED NEXT HOSPITALS TO WORK ON:\n")
      for (i in 1:min(5, length(next_hospitals))) {
        h <- next_hospitals[[i]]
        cat(sprintf("  %d. FAC-%s: %s\n", i, h$FAC, h$name))
        if (!is.null(h$url) && !grepl("TODO", h$url)) {
          cat("     URL: Available ✓\n")
        } else {
          cat("     URL: Needs adding ⚠\n")
        }
      }
    }
  }
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    SESSION ENDED                               \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Session ended:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Don't forget to update SESSION_LOG.md!\n\n")

# Prompt for session notes
cat("Quick session notes (optional, press Enter to skip):\n")
cat("What did you accomplish today? ")
notes <- readline()

if (nchar(notes) > 0) {
  cat("\n📝 Session notes saved to clipboard (paste into SESSION_LOG.md):\n\n")
  cat("### Session:", format(Sys.Date(), "%Y-%m-%d"), "\n")
  cat("**What We Accomplished:**\n")
  cat("-", notes, "\n\n")
  cat("**Time Spent:** ~", round(duration, 1), "hours\n")
}

cat("\n✓ Shutdown complete. See you next session!\n\n")