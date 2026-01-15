# logging_functions.R
# Centralized logging utilities for Hospital Executive Data Collection
# Version: 1.0
# Created: January 2026
# Location: E:/ExecutiveSearchYaml/code/
#
# Usage:
#   source("E:/ExecutiveSearchYaml/code/logging_functions.R")
#   log_file <- create_log_file(Sys.Date(), "scraper")
#   log_message("Starting process", log_file)
#
# ==============================================================================

# ==============================================================================
# LOG FILE CREATION
# ==============================================================================

#' Create a timestamped log file
#' 
#' @param date Date object or character string
#' @param process_name Name of process (e.g., "scraper", "processor", "monthly")
#' @param log_dir Directory for log files (default: E:/ExecutiveSearchYaml/tracking)
#' @return Full path to created log file
create_log_file <- function(date = Sys.Date(), 
                            process_name = "process",
                            log_dir = "E:/ExecutiveSearchYaml/tracking") {
  
  # Ensure log directory exists
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE)
  }
  
  # Format date as YYYY-MM-DD
  date_string <- format(as.Date(date), "%Y-%m-%d")
  
  # Create filename
  log_filename <- paste0(process_name, "_", date_string, ".log")
  log_file <- file.path(log_dir, log_filename)
  
  # Initialize empty log file
  cat("", file = log_file)
  
  return(log_file)
}

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

#' Log a message with timestamp to console and optionally to file
#' 
#' @param message Character string to log
#' @param log_file Path to log file (optional)
log_message <- function(message, log_file = NULL) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0("[", timestamp, "] ", message)
  
  # Console output
  cat(log_entry, "\n")
  
  # File output if specified
  if (!is.null(log_file)) {
    cat(log_entry, "\n", file = log_file, append = TRUE)
  }
  
  invisible(log_entry)
}

#' Log an error message with timestamp
#' 
#' @param message Error message to log
#' @param log_file Path to log file (optional)
#' @param stop_execution If TRUE, stops execution with error (default: TRUE)
log_error <- function(message, log_file = NULL, stop_execution = TRUE) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0("[", timestamp, "] ERROR: ", message)
  
  # Console output in red if possible
  cat(log_entry, "\n")
  
  # File output if specified
  if (!is.null(log_file)) {
    cat(log_entry, "\n", file = log_file, append = TRUE)
  }
  
  if (stop_execution) {
    stop(message, call. = FALSE)
  }
  
  invisible(log_entry)
}

#' Log a warning message with timestamp
#' 
#' @param message Warning message to log
#' @param log_file Path to log file (optional)
log_warning <- function(message, log_file = NULL) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0("[", timestamp, "] WARNING: ", message)
  
  # Console output
  cat(log_entry, "\n")
  
  # File output if specified
  if (!is.null(log_file)) {
    cat(log_entry, "\n", file = log_file, append = TRUE)
  }
  
  invisible(log_entry)
}

#' Log a section header
#' 
#' @param title Section title
#' @param log_file Path to log file (optional)
#' @param char Character to use for border (default: "=")
#' @param width Width of border (default: 80)
log_section <- function(title, log_file = NULL, char = "=", width = 80) {
  border <- paste(rep(char, width), collapse = "")
  log_message("", log_file)
  log_message(border, log_file)
  log_message(paste0("  ", title), log_file)
  log_message(border, log_file)
  log_message("", log_file)
}

#' Log record count information
#' 
#' @param counts Named list or vector of counts
#' @param log_file Path to log file (optional)
log_record_counts <- function(counts, log_file = NULL) {
  log_message("Record counts:", log_file)
  for (name in names(counts)) {
    log_message(sprintf("  %s: %d", name, counts[[name]]), log_file)
  }
}

#' Log duration information
#' 
#' @param start_time POSIXct start time
#' @param end_time POSIXct end time (default: Sys.time())
#' @param log_file Path to log file (optional)
#' @return Duration in seconds
log_duration <- function(start_time, end_time = Sys.time(), log_file = NULL) {
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # Format duration nicely
  if (duration < 60) {
    duration_str <- sprintf("%.1f seconds", duration)
  } else if (duration < 3600) {
    duration_str <- sprintf("%.1f minutes", duration / 60)
  } else {
    duration_str <- sprintf("%.1f hours", duration / 3600)
  }
  
  log_message(sprintf("Duration: %s", duration_str), log_file)
  
  invisible(duration)
}