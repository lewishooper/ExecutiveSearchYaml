# =============================================================================
# VALIDATION FUNCTION
# Claude API Screenshot Extraction - Phase 0 Prototype
# =============================================================================
# 
# Purpose: Validate extracted executive data for quality, completeness, and
#          accuracy before integration into main hospital database
#
# Author: Skip (with Claude assistance)
# Date: January 9, 2026
# Version: 1.0
#
# Dependencies: stringr, dplyr
# =============================================================================

library(stringr)
library(dplyr)

# =============================================================================
# VALIDATION RULES
# =============================================================================

# Executive title keywords (must contain at least one)
EXECUTIVE_KEYWORDS <- c(
  "chief", "ceo", "president", "vice president", "vp", "executive",
  "director", "officer", "lead", "head", "senior"
)

# Exclude patterns (should NOT contain these)
EXCLUDE_PATTERNS <- c(
  "board", "trustee", "governor", "volunteer", 
  "assistant to", "secretary to", "admin",
  "contact", "email", "phone", "www", "http"
)

# =============================================================================
# MAIN FUNCTION: validate_extracted_executives
# =============================================================================

#' Validate Extracted Executive Data
#' 
#' Performs multi-layer validation on extracted executive data to check for
#' quality issues, suspicious entries, and missing information.
#'
#' @param executives_df Data frame with columns: name, title
#' @param expected_count Numeric. Expected number of executives (NULL = no check)
#' @param min_count Numeric. Minimum acceptable executives. Default: 3
#' @param max_count Numeric. Maximum acceptable executives. Default: 25
#' @param hospital_name Character. Hospital name for reporting. Default: NULL
#' @param verbose Logical. Print detailed validation messages. Default: TRUE
#'
#' @return List with:
#'   - valid: Logical - overall validation passed
#'   - executives_validated: Data frame with validation flags added
#'   - issues: Character vector of validation issues found
#'   - warnings: Character vector of non-critical warnings
#'   - quality_score: Numeric 0-100 indicating data quality
#'   - summary: List with validation statistics
#'
#' @examples
#' validation_result <- validate_extracted_executives(
#'   executives_df = extracted_data,
#'   expected_count = 12,
#'   hospital_name = "Toronto Mount Sinai"
#' )

validate_extracted_executives <- function(
  executives_df,
  expected_count = NULL,
  min_count = 3,
  max_count = 25,
  hospital_name = NULL,
  verbose = TRUE
) {
  
  # Initialize result
  result <- list(
    valid = TRUE,
    executives_validated = NULL,
    issues = character(),
    warnings = character(),
    quality_score = 100,
    summary = list()
  )
  
  if (verbose) {
    cat("\n========================================\n")
    cat("VALIDATING EXTRACTED EXECUTIVES\n")
    if (!is.null(hospital_name)) {
      cat("Hospital:", hospital_name, "\n")
    }
    cat("========================================\n\n")
  }
  
  # ===== VALIDATION LAYER 1: STRUCTURAL CHECKS =====
  if (verbose) cat("LAYER 1: Structural Validation\n")
  cat("----------------------------------------\n")
  
  # Check 1.1: Data frame exists and has data
  if (is.null(executives_df) || !is.data.frame(executives_df) || nrow(executives_df) == 0) {
    result$issues <- c(result$issues, "No executive data provided or empty data frame")
    result$valid <- FALSE
    result$quality_score <- 0
    if (verbose) cat("✗ CRITICAL: No data to validate\n\n")
    return(result)
  }
  
  if (verbose) cat(sprintf("✓ Data frame with %d rows\n", nrow(executives_df)))
  
  # Check 1.2: Required columns present
  if (!all(c("name", "title") %in% names(executives_df))) {
    result$issues <- c(result$issues, "Missing required columns (name, title)")
    result$valid <- FALSE
    result$quality_score <- result$quality_score - 50
    if (verbose) cat("✗ Missing required columns\n\n")
    return(result)
  }
  
  if (verbose) cat("✓ Required columns present (name, title)\n")
  
  # Check 1.3: Executive count in acceptable range
  exec_count <- nrow(executives_df)
  
  if (exec_count < min_count) {
    result$issues <- c(result$issues, 
                      sprintf("Too few executives (%d < minimum %d)", exec_count, min_count))
    result$valid <- FALSE
    result$quality_score <- result$quality_score - 30
    if (verbose) cat(sprintf("✗ Too few executives: %d (min: %d)\n", exec_count, min_count))
  } else if (exec_count > max_count) {
    result$warnings <- c(result$warnings,
                        sprintf("Unusually high executive count (%d > typical %d)", exec_count, max_count))
    result$quality_score <- result$quality_score - 10
    if (verbose) cat(sprintf("⚠ High executive count: %d (max: %d)\n", exec_count, max_count))
  } else {
    if (verbose) cat(sprintf("✓ Executive count acceptable: %d\n", exec_count))
  }
  
  # Check 1.4: Compare to expected count if provided
  if (!is.null(expected_count)) {
    count_diff <- abs(exec_count - expected_count)
    count_pct <- count_diff / expected_count * 100
    
    if (count_pct > 50) {
      result$warnings <- c(result$warnings,
                          sprintf("Count differs significantly from expected (%d vs %d expected)", 
                                 exec_count, expected_count))
      result$quality_score <- result$quality_score - 15
      if (verbose) cat(sprintf("⚠ Count differs from expected: %d vs %d expected (%.0f%% diff)\n", 
                              exec_count, expected_count, count_pct))
    } else if (count_pct > 20) {
      result$quality_score <- result$quality_score - 5
      if (verbose) cat(sprintf("✓ Count close to expected: %d vs %d expected\n", 
                              exec_count, expected_count))
    } else {
      if (verbose) cat(sprintf("✓ Count matches expected: %d vs %d expected\n", 
                              exec_count, expected_count))
    }
  }
  
  if (verbose) cat("\n")
  
  # ===== VALIDATION LAYER 2: NAME VALIDATION =====
  if (verbose) {
    cat("LAYER 2: Name Validation\n")
    cat("----------------------------------------\n")
  }
  
  # Add validation flags to data frame
  executives_df$name_valid <- TRUE
  executives_df$name_issues <- ""
  
  for (i in 1:nrow(executives_df)) {
    name <- executives_df$name[i]
    name_issues <- character()
    
    # Check 2.1: Name is not NA or empty
    if (is.na(name) || trimws(name) == "") {
      name_issues <- c(name_issues, "empty_name")
      executives_df$name_valid[i] <- FALSE
      result$issues <- c(result$issues, sprintf("Row %d: Empty or NA name", i))
      result$quality_score <- result$quality_score - 5
    }
    
    # Check 2.2: Name length reasonable
    if (!is.na(name)) {
      name_len <- nchar(name)
      if (name_len < 3) {
        name_issues <- c(name_issues, "too_short")
        result$warnings <- c(result$warnings, sprintf("Row %d: Name too short (%s)", i, name))
        result$quality_score <- result$quality_score - 2
      } else if (name_len > 100) {
        name_issues <- c(name_issues, "too_long")
        result$warnings <- c(result$warnings, sprintf("Row %d: Name unusually long (%s)", i, name))
        result$quality_score <- result$quality_score - 2
      }
    }
    
    # Check 2.3: Name contains only valid characters (letters, spaces, hyphens, apostrophes, periods, commas)
    if (!is.na(name)) {
      if (grepl("[0-9]", name)) {
        name_issues <- c(name_issues, "contains_numbers")
        result$warnings <- c(result$warnings, sprintf("Row %d: Name contains numbers (%s)", i, name))
        result$quality_score <- result$quality_score - 3
      }
      
      # Check for suspicious patterns (emails, URLs)
      if (grepl("@|www\\.|http", name, ignore.case = TRUE)) {
        name_issues <- c(name_issues, "contains_contact_info")
        executives_df$name_valid[i] <- FALSE
        result$issues <- c(result$issues, sprintf("Row %d: Name contains contact info (%s)", i, name))
        result$quality_score <- result$quality_score - 10
      }
    }
    
    executives_df$name_issues[i] <- paste(name_issues, collapse = ",")
  }
  
  valid_names <- sum(executives_df$name_valid)
  if (verbose) {
    cat(sprintf("✓ Valid names: %d / %d (%.0f%%)\n", 
               valid_names, nrow(executives_df), 
               valid_names / nrow(executives_df) * 100))
  }
  
  if (verbose) cat("\n")
  
  # ===== VALIDATION LAYER 3: TITLE VALIDATION =====
  if (verbose) {
    cat("LAYER 3: Title Validation\n")
    cat("----------------------------------------\n")
  }
  
  executives_df$title_valid <- TRUE
  executives_df$title_issues <- ""
  executives_df$has_executive_keyword <- FALSE
  executives_df$has_exclude_pattern <- FALSE
  
  for (i in 1:nrow(executives_df)) {
    title <- executives_df$title[i]
    title_issues <- character()
    
    # Check 3.1: Title is not NA or empty
    if (is.na(title) || trimws(title) == "") {
      title_issues <- c(title_issues, "empty_title")
      executives_df$title_valid[i] <- FALSE
      result$issues <- c(result$issues, sprintf("Row %d: Empty or NA title", i))
      result$quality_score <- result$quality_score - 5
    }
    
    # Check 3.2: Title contains executive keyword
    if (!is.na(title)) {
      title_lower <- tolower(title)
      has_keyword <- any(sapply(EXECUTIVE_KEYWORDS, function(kw) grepl(kw, title_lower)))
      executives_df$has_executive_keyword[i] <- has_keyword
      
      if (!has_keyword) {
        title_issues <- c(title_issues, "no_executive_keyword")
        result$warnings <- c(result$warnings, 
                           sprintf("Row %d: Title lacks executive keyword (%s)", i, title))
        result$quality_score <- result$quality_score - 3
      }
    }
    
    # Check 3.3: Title does NOT contain exclude patterns
    if (!is.na(title)) {
      title_lower <- tolower(title)
      has_exclude <- any(sapply(EXCLUDE_PATTERNS, function(pat) grepl(pat, title_lower)))
      executives_df$has_exclude_pattern[i] <- has_exclude
      
      if (has_exclude) {
        title_issues <- c(title_issues, "exclude_pattern")
        executives_df$title_valid[i] <- FALSE
        result$issues <- c(result$issues, 
                         sprintf("Row %d: Title contains exclude pattern (%s)", i, title))
        result$quality_score <- result$quality_score - 8
      }
    }
    
    # Check 3.4: Title length reasonable
    if (!is.na(title)) {
      title_len <- nchar(title)
      if (title_len < 5) {
        title_issues <- c(title_issues, "too_short")
        result$warnings <- c(result$warnings, sprintf("Row %d: Title too short (%s)", i, title))
        result$quality_score <- result$quality_score - 2
      } else if (title_len > 200) {
        title_issues <- c(title_issues, "too_long")
        result$warnings <- c(result$warnings, sprintf("Row %d: Title too long (truncated?)", i))
        result$quality_score <- result$quality_score - 2
      }
    }
    
    executives_df$title_issues[i] <- paste(title_issues, collapse = ",")
  }
  
  valid_titles <- sum(executives_df$title_valid)
  has_keywords <- sum(executives_df$has_executive_keyword)
  has_excludes <- sum(executives_df$has_exclude_pattern)
  
  if (verbose) {
    cat(sprintf("✓ Valid titles: %d / %d (%.0f%%)\n", 
               valid_titles, nrow(executives_df),
               valid_titles / nrow(executives_df) * 100))
    cat(sprintf("✓ Titles with executive keywords: %d / %d (%.0f%%)\n",
               has_keywords, nrow(executives_df),
               has_keywords / nrow(executives_df) * 100))
    if (has_excludes > 0) {
      cat(sprintf("⚠ Titles with exclude patterns: %d\n", has_excludes))
    }
  }
  
  if (verbose) cat("\n")
  
  # ===== VALIDATION LAYER 4: DUPLICATE DETECTION =====
  if (verbose) {
    cat("LAYER 4: Duplicate Detection\n")
    cat("----------------------------------------\n")
  }
  
  # Check for duplicate names
  dup_names <- duplicated(executives_df$name) | duplicated(executives_df$name, fromLast = TRUE)
  if (any(dup_names)) {
    dup_count <- sum(dup_names)
    result$warnings <- c(result$warnings, sprintf("%d duplicate names detected", dup_count))
    result$quality_score <- result$quality_score - (dup_count * 5)
    if (verbose) {
      cat(sprintf("⚠ Duplicate names: %d\n", dup_count))
      cat("  Duplicates:\n")
      for (name in unique(executives_df$name[dup_names])) {
        cat(sprintf("    - %s\n", name))
      }
    }
  } else {
    if (verbose) cat("✓ No duplicate names\n")
  }
  
  if (verbose) cat("\n")
  
  # ===== FINAL VALIDATION STATUS =====
  
  # Overall validity check
  overall_valid <- sum(executives_df$name_valid & executives_df$title_valid)
  overall_pct <- overall_valid / nrow(executives_df) * 100
  
  if (overall_pct < 50) {
    result$valid <- FALSE
    result$issues <- c(result$issues, 
                      sprintf("Too many invalid records (%.0f%% valid)", overall_pct))
  } else if (overall_pct < 80) {
    result$warnings <- c(result$warnings,
                        sprintf("Moderate validation issues (%.0f%% valid)", overall_pct))
  }
  
  # Ensure quality score doesn't go negative
  result$quality_score <- max(0, result$quality_score)
  
  # Add summary statistics
  result$summary <- list(
    total_records = nrow(executives_df),
    valid_records = overall_valid,
    valid_percentage = overall_pct,
    invalid_names = sum(!executives_df$name_valid),
    invalid_titles = sum(!executives_df$title_valid),
    missing_keywords = sum(!executives_df$has_executive_keyword),
    has_excludes = sum(executives_df$has_exclude_pattern),
    duplicate_names = sum(dup_names),
    total_issues = length(result$issues),
    total_warnings = length(result$warnings),
    quality_score = result$quality_score
  )
  
  # Add detailed validation reasons for each record
  result$validation_details <- executives_df[, c(
    "name", "title", 
    "name_valid", "name_issues",
    "title_valid", "title_issues",
    "has_executive_keyword", "has_exclude_pattern"
  )]
  
  # Add validated data frame to result
  result$executives_validated <- executives_df
  
  # Print summary
  if (verbose) {
    cat("========================================\n")
    cat("VALIDATION SUMMARY\n")
    cat("========================================\n")
    cat(sprintf("Overall Status: %s\n", ifelse(result$valid, "✓ VALID", "✗ INVALID")))
    cat(sprintf("Quality Score: %.0f / 100\n", result$quality_score))
    cat(sprintf("Valid Records: %d / %d (%.0f%%)\n", 
               overall_valid, nrow(executives_df), overall_pct))
    cat(sprintf("Critical Issues: %d\n", length(result$issues)))
    cat(sprintf("Warnings: %d\n", length(result$warnings)))
    
    if (length(result$issues) > 0) {
      cat("\nCritical Issues:\n")
      for (issue in result$issues) {
        cat(sprintf("  ✗ %s\n", issue))
      }
    }
    
    if (length(result$warnings) > 0 && length(result$warnings) <= 5) {
      cat("\nWarnings:\n")
      for (warning in result$warnings) {
        cat(sprintf("  ⚠ %s\n", warning))
      }
    } else if (length(result$warnings) > 5) {
      cat(sprintf("\nWarnings: %d (showing first 5)\n", length(result$warnings)))
      for (i in 1:5) {
        cat(sprintf("  ⚠ %s\n", result$warnings[i]))
      }
    }
    
    cat("\n")
  }
  
  return(result)
}

# =============================================================================
# HELPER FUNCTION: print_validation_report
# =============================================================================

#' Print Detailed Validation Report
#'
#' @param validation_result Result from validate_extracted_executives()

print_validation_report <- function(validation_result) {
  
  cat("\n╔════════════════════════════════════════╗\n")
  cat("║    EXECUTIVE DATA VALIDATION REPORT    ║\n")
  cat("╚════════════════════════════════════════╝\n\n")
  
  # Overall status
  cat("OVERALL STATUS\n")
  cat("─────────────────────────────────────────\n")
  status_symbol <- ifelse(validation_result$valid, "✓", "✗")
  status_text <- ifelse(validation_result$valid, "PASS", "FAIL")
  cat(sprintf("%s Validation: %s\n", status_symbol, status_text))
  cat(sprintf("Quality Score: %.0f / 100\n\n", validation_result$quality_score))
  
  # Statistics
  cat("STATISTICS\n")
  cat("─────────────────────────────────────────\n")
  s <- validation_result$summary
  cat(sprintf("Total Records:      %d\n", s$total_records))
  cat(sprintf("Valid Records:      %d (%.0f%%)\n", s$valid_records, s$valid_percentage))
  cat(sprintf("Invalid Names:      %d\n", s$invalid_names))
  cat(sprintf("Invalid Titles:     %d\n", s$invalid_titles))
  cat(sprintf("Missing Keywords:   %d\n", s$missing_keywords))
  cat(sprintf("Exclude Patterns:   %d\n", s$has_excludes))
  cat(sprintf("Duplicate Names:    %d\n", s$duplicate_names))
  cat(sprintf("Critical Issues:    %d\n", s$total_issues))
  cat(sprintf("Warnings:           %d\n\n", s$total_warnings))
  
  # Detailed issues
  if (s$total_issues > 0) {
    cat("CRITICAL ISSUES\n")
    cat("─────────────────────────────────────────\n")
    for (issue in validation_result$issues) {
      cat(sprintf("✗ %s\n", issue))
    }
    cat("\n")
  }
  
  # Invalid records
  invalid_records <- validation_result$executives_validated[
    !validation_result$executives_validated$name_valid | 
    !validation_result$executives_validated$title_valid, 
  ]
  
  if (nrow(invalid_records) > 0) {
    cat("INVALID RECORDS\n")
    cat("─────────────────────────────────────────\n")
    for (i in 1:nrow(invalid_records)) {
      cat(sprintf("\nRecord %d:\n", i))
      cat(sprintf("  Name: %s\n", invalid_records$name[i]))
      cat(sprintf("  Title: %s\n", invalid_records$title[i]))
      if (invalid_records$name_issues[i] != "") {
        cat(sprintf("  Name Issues: %s\n", invalid_records$name_issues[i]))
      }
      if (invalid_records$title_issues[i] != "") {
        cat(sprintf("  Title Issues: %s\n", invalid_records$title_issues[i]))
      }
    }
    cat("\n")
  }
  
  # Recommendation
  cat("RECOMMENDATION\n")
  cat("─────────────────────────────────────────\n")
  if (validation_result$quality_score >= 90) {
    cat("✓ Data quality is EXCELLENT. Ready for production use.\n")
  } else if (validation_result$quality_score >= 75) {
    cat("✓ Data quality is GOOD. Minor issues can be reviewed.\n")
  } else if (validation_result$quality_score >= 60) {
    cat("⚠ Data quality is FAIR. Review and clean recommended.\n")
  } else if (validation_result$quality_score >= 40) {
    cat("⚠ Data quality is POOR. Significant review required.\n")
  } else {
    cat("✗ Data quality is UNACCEPTABLE. Do not use without manual review.\n")
  }
  
  cat("\n")
}

# =============================================================================
# USAGE EXAMPLES
# =============================================================================

# Example 1: Validate extraction result
if (FALSE) {
  # After extraction
  extraction_result <- extract_executives_from_screenshot(screenshot_file)
  
  # Validate
  validation_result <- validate_extracted_executives(
    executives_df = extraction_result$executives,
    expected_count = 12,
    hospital_name = "Toronto Mount Sinai"
  )
  
  # Print detailed report
  print_validation_report(validation_result)
}

# =============================================================================
# END OF SCRIPT
# =============================================================================

cat("\n✓ Validation function loaded successfully!\n")
cat("\nQuick Start:\n")
cat("  validation_result <- validate_extracted_executives(executives_df)\n")
cat("  print_validation_report(validation_result)\n\n")
