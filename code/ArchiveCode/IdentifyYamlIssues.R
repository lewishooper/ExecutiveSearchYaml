# Diagnostic script to find problematic hospital configs
library(yaml)
library(dplyr)

hospitals_data <- read_yaml("enhanced_hospitals.yaml")

cat("Checking all hospitals for missing fields...\n\n")

problems <- list()

for (i in seq_along(hospitals_data$hospitals)) {
  hospital <- hospitals_data$hospitals[[i]]
  
  issues <- c()
  
  # Check required fields
  if (is.null(hospital$FAC) || length(hospital$FAC) == 0) {
    issues <- c(issues, "Missing FAC")
  }
  if (is.null(hospital$name) || length(hospital$name) == 0) {
    issues <- c(issues, "Missing name")
  }
  if (is.null(hospital$pattern) || length(hospital$pattern) == 0) {
    issues <- c(issues, "Missing pattern")
  }
  if (is.null(hospital$status) || length(hospital$status) == 0) {
    issues <- c(issues, "Missing status")
  }
  if (is.null(hospital$url) || length(hospital$url) == 0) {
    issues <- c(issues, "Missing url")
  }
  
  if (length(issues) > 0) {
    problems[[length(problems) + 1]] <- list(
      index = i,
      FAC = hospital$FAC %||% "UNKNOWN",
      name = hospital$name %||% "UNKNOWN",
      issues = paste(issues, collapse = ", ")
    )
  }
}

if (length(problems) > 0) {
  cat("Found", length(problems), "hospitals with issues:\n")
  cat("================================================\n\n")
  for (prob in problems) {
    cat(sprintf("Index %d: FAC-%s (%s)\n", prob$index, prob$FAC, prob$name))
    cat(sprintf("  Issues: %s\n\n", prob$issues))
  }
} else {
  cat("✓ All hospitals have required fields!\n")
}