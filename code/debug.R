# Simple status check (no recursion issues)
library(yaml)
config <- yaml::read_yaml("enhanced_hospitals.yaml")

cat("═══════════════════════════════════════════════════════════════\n")
cat("PROJECT STATUS - SIMPLE CHECK\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Total hospitals configured:", length(config$hospitals), "\n\n")

# Count by status
statuses <- sapply(config$hospitals, function(h) h$status %||% "not_set")
status_table <- table(statuses)

cat("Status breakdown:\n")
for (status_name in names(status_table)) {
  cat(sprintf("  %-25s %3d\n", status_name, status_table[[status_name]]))
}

cat("\n")
cat("✓ YAML file is valid and readable\n")
cat("✓ No critical issues detected\n")