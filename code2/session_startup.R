# session_startup.R - Start of session initialization
# Run this at the beginning of each work session
# Save in E:/ExecutiveSearchYaml/code/

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║           HOSPITAL SCRAPER PROJECT - SESSION STARTUP           ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Record session start time
session_start_time <- Sys.time()
cat("Session started:", format(session_start_time, "%Y-%m-%d %H:%M:%S"), "\n\n")

# Set working directory
setwd("E:/ExecutiveSearchYaml/code/")
cat("✓ Working directory set\n")

# Load required libraries
cat("\nLoading libraries...\n")
required_libs <- c("rvest", "dplyr", "yaml", "stringr", "readxl")
for (lib in required_libs) {
  if (!require(lib, character.only = TRUE, quietly = TRUE)) {
    cat("  ⚠ Installing", lib, "...\n")
    install.packages(lib)
    library(lib, character.only = TRUE)
  }
}
cat("✓ All libraries loaded\n")

# Source all required scripts
cat("\nLoading project scripts...\n")
scripts <- c(
  "pattern_based_scraper.R",
  "hospital_configuration_helper.R",
  "quick_test_single.R"
)

for (script in scripts) {
  if (file.exists(script)) {
    source(script)
    cat("  ✓", script, "\n")
  } else {
    cat("  ⚠ Missing:", script, "\n")
  }
}

# Check for key files
cat("\nChecking key files...\n")
key_files <- c(
  "enhanced_hospitals.yaml",
  "next_batch_template.yaml",
  "SESSION_LOG.md"
)

for (file in key_files) {
  if (file.exists(file)) {
    cat("  ✓", file, "\n")
  } else {
    cat("  ⚠ Missing:", file, "\n")
  }
}

# Display current project status
cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    CURRENT PROJECT STATUS                      \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

if (file.exists("enhanced_hospitals.yaml")) {
  config <- yaml::read_yaml("enhanced_hospitals.yaml")
  
  total_configured <- length(config$hospitals)
  
  # Count by status
  status_counts <- table(sapply(config$hospitals, function(h) h$status %||% "unknown"))
  
  cat("Configured hospitals:", total_configured, "\n")
  cat("\nStatus breakdown:\n")
  for (status in names(status_counts)) {
    cat("  ", status, ":", status_counts[status], "\n")
  }
  
  # Pattern usage
  pattern_counts <- table(sapply(config$hospitals, function(h) h$pattern))
  pattern_counts <- sort(pattern_counts, decreasing = TRUE)
  
  cat("\nTop patterns in use:\n")
  for (i in 1:min(5, length(pattern_counts))) {
    cat("  ", names(pattern_counts)[i], ":", pattern_counts[i], "\n")
  }
}

# Check next batch status
cat("\n───────────────────────────────────────────────────────────────\n")
if (file.exists("next_batch_template.yaml")) {
  batch_config <- yaml::read_yaml("next_batch_template.yaml")
  if (!is.null(batch_config$hospitals)) {
    batch_total <- length(batch_config$hospitals)
    
    # Count how many need URLs
    needs_url <- sum(sapply(batch_config$hospitals, function(h) 
      grepl("TODO", h$url %||% "")))
    
    needs_testing <- sum(sapply(batch_config$hospitals, function(h) 
      (h$status %||% "") == "needs_testing"))
    
    configured <- sum(sapply(batch_config$hospitals, function(h) 
      (h$status %||% "") %in% c("configured", "ok")))
    
    cat("Next batch status:\n")
    cat("  Total hospitals:", batch_total, "\n")
    cat("  Needs URL:", needs_url, "\n")
    cat("  Ready to test:", needs_testing, "\n")
    cat("  Configured:", configured, "\n")
    cat("  Remaining:", batch_total - configured, "\n")
  }
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                         QUICK START                            \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("COMMON COMMANDS:\n")
cat("  source('project_status.R')           # Detailed status report\n")
cat("  helper$analyze_hospital_structure()  # Analyze new hospital\n")
cat("  quick_test(FAC)                      # Test single hospital\n")
cat("  source('session_shutdown.R')         # End session checklist\n\n")

cat("NEXT STEPS:\n")
if (file.exists("next_batch_template.yaml")) {
  cat("  1. Open next_batch_template.yaml\n")
  cat("  2. Pick next hospital to configure\n")
  cat("  3. Run helper$analyze_hospital_structure(FAC, 'Name', 'URL')\n")
  cat("  4. Configure YAML entry\n")
  cat("  5. Test with quick_test(FAC)\n\n")
} else {
  cat("  1. Review SESSION_LOG.md for yesterday's progress\n")
  cat("  2. Generate next batch: source('generate_yaml_template.R')\n\n")
}

cat("═══════════════════════════════════════════════════════════════\n\n")

cat("✓ Startup complete! Ready to work.\n\n")

# Store start time in global environment for shutdown script
.session_start <<- session_start_time
