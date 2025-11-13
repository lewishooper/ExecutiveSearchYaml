# Test the title validation
source("pattern_based_scraper.R")

# Get hospital info
hospital <- NULL
for(h in config$hospitals) {
  if(h$FAC == "950") {
    hospital <- h
    break
  }
}

# Test the title
test_title <- "Redevelopment, Facilities & Retail Operations"
cat("Testing title:", test_title, "\n")

# This function should exist in your scraper
result <- is_executive_title(test_title, config, hospital)
cat("Is executive title?", result, "\n")