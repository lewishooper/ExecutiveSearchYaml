library(rvest)
library(yaml)

page <- read_html("https://www.sickkids.ca/en/about/leadership/")
config <- read_yaml("enhanced_hospitals.yaml")
source("pattern_based_scraper.R")

# Get hospital info
hospital_info <- NULL
for (h in config$hospitals) {
  if (h$FAC == "837") {
    hospital_info <- h
    break
  }
}

# Test with Ronald Cohn
test_name <- "Ronald Cohn"

# Manually call the validation (if function exists in global scope)
# If not, we'll need to test differently
cat("Testing name validation for:", test_name, "\n")

# Check patterns
name_patterns <- c(
  config$name_patterns$standard,
  config$name_patterns$with_titles,
  config$name_patterns$with_credentials,
  config$name_patterns$hyphenated_names,
  config$name_patterns$complex_credentials,
  config$name_patterns$internal_capitals,
  config$name_patterns$accented_names,
  config$name_patterns$parenthetical_names,
  config$name_patterns$flexible
)

matches_pattern <- any(sapply(name_patterns, function(p) {
  if (!is.null(p) && !is.na(p)) {
    grepl(p, test_name)
  } else {
    FALSE
  }
}))

cat("Matches name pattern:", matches_pattern, "\n")

# Check exclusions
non_names <- config$recognition_config$name_exclusions
fac_key <- paste0("FAC_", hospital_info$FAC)
if (!is.null(config$hospital_overrides[[fac_key]]$additional_name_exclusions)) {
  non_names <- c(non_names, config$hospital_overrides[[fac_key]]$additional_name_exclusions)
}

is_non_name <- any(sapply(non_names, function(p) {
  result <- grepl(p, test_name, ignore.case = TRUE)
  if (result) cat("  Matched exclusion:", p, "\n")
  result
}))

cat("Is excluded:", is_non_name, "\n")
cat("Should pass:", matches_pattern && !is_non_name, "\n")