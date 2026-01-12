# Start fresh
#rm(list=ls())
project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}
config <- yaml::read_yaml("code/enhanced_hospitals.yaml")
source("code/pattern_based_scraper.R")
source("code/get_hosptial_info.R")
source("code/quick_test_single.R")
source("code/session_startup.R")

source("code/test_all_configured_hospitals.R")
source("code/hospital_configuration_helper.R")
FAC<-976





# Test single hospital
quick_test(FAC)

#
# Pre-monthly check
source("code/PreMonthlyRun.R")

# Read file as text, truncate at marker, then parse
yaml_text <- readLines("code/enhanced_hospitals.yaml")
read_yaml_hospitals_only <- function(file, verbose = TRUE) {
  
  yaml_text <- readLines(file, warn = FALSE)
  
  # Find first line starting with ### (comments/documentation section)
  marker_line <- grep("^###", yaml_text)
  
  if (length(marker_line) > 0) {
    stop_line <- marker_line[1] - 1
    yaml_text <- yaml_text[1:stop_line]
    
    if (verbose) {
      cat(sprintf("✓ Stopping at line %d (first ### marker)\n", marker_line[1]))
      cat(sprintf("  Marker text: '%s'\n", trimws(yaml_text[marker_line[1]])))
    }
  } else {
    if (verbose) {
      cat("No ### marker found - reading entire file\n")
    }
  }
  
  # Parse YAML
  config <- yaml::yaml.load(paste(yaml_text, collapse = "\n"))
  
  if (verbose && !is.null(config$hospitals)) {
    cat(sprintf("✓ Loaded %d hospitals\n", length(config$hospitals)))
  }
  
  return(config)
}
config <- read_yaml_hospitals_only("code/enhanced_hospitals.yaml")
table(sapply(config$hospitals, function(h) h$data_status))



## test completeness
# Safe extraction with NA for missing values
get_status <- function(h) {
  status <- h$status
  if (is.null(status)) return(NA_character_) else return(status)
}

status_values <- sapply(config$hospitals, get_status)

cat("\nDATA_STATUS SUMMARY:\n")
print(table(status_values, useNA = "always"))

# Show which FACs are missing
missing_facs <- sapply(config$hospitals, function(h) h$FAC)[is.na(status_values)]
if (length(missing_facs) > 0) {
  cat(sprintf("\n%d hospitals missing data_status:\n", length(missing_facs)))
  cat("FACs:", paste(missing_facs, collapse = ", "), "\n")
}

