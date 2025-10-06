# Check what clean_text_data does to these titles
source("pattern_based_scraper.R")

test_titles <- c(
  "Chief of Staff, Vice President Medical and Academic Affairs",
  "Vice President, Strategy, Quality, Risk & Communications"
)

scraper <- PatternBasedScraper()

cat("After cleaning:\n\n")
for (title in test_titles) {
  # We can't directly call clean_text_data, but let's manually do what it does
  cleaned <- title
  cleaned <- str_remove_all(cleaned, "\\s*ext\\.?\\s*\\d+.*$")
  cleaned <- str_remove_all(cleaned, "\\s*extension\\s*\\d+.*$")
  cleaned <- str_replace_all(cleaned, "\\s+", " ")
  cleaned <- trimws(cleaned)
  
  cat("Original:", title, "\n")
  cat("Cleaned:", cleaned, "\n\n")
}

library(rvest)
page <- read_html("https://www.bchsys.org/en/about-us/senior-leadership-team.aspx")

h5_elements <- page %>% html_nodes("h5.emphasis-Secondary") %>% html_text(trim = TRUE)

cat("All h5.emphasis-Secondary elements:\n\n")
for (i in 1:length(h5_elements)) {
  parts <- strsplit(h5_elements[i], " | ", fixed = TRUE)[[1]]
  if (length(parts) >= 2) {
    cat(i, ".\n")
    cat("  Name:", trimws(parts[1]), "\n")
    cat("  Title:", trimws(parts[2]), "\n\n")
  }
}
library(rvest)
library(stringr)
library(yaml)

page <- read_html("https://www.bchsys.org/en/about-us/senior-leadership-team.aspx")
config <- yaml::read_yaml("enhanced_hospitals.yaml")

h5_elements <- page %>% html_nodes("h5.emphasis-Secondary") %>% html_text(trim = TRUE)

cat("Testing all 6 executives:\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

all_titles <- c(
  config$executive_titles$primary,
  config$executive_titles$secondary,
  config$executive_titles$medical_specific
)

for (i in 1:length(h5_elements)) {
  parts <- strsplit(h5_elements[i], " | ", fixed = TRUE)[[1]]
  if (length(parts) >= 2) {
    name <- trimws(parts[1])
    title <- trimws(parts[2])
    
    cat(i, ". ", name, "\n", sep = "")
    cat("   Title: ", title, "\n", sep = "")
    
    # Check if title matches any executive title pattern
    matches <- sapply(all_titles, function(t) grepl(t, title, ignore.case = TRUE))
    
    if (any(matches)) {
      cat("   ✓ Title MATCHES: ", paste(all_titles[matches], collapse = ", "), "\n")
    } else {
      cat("   ✗ Title DOES NOT MATCH any executive title\n")
    }
    cat("\n")
  }
}


library(rvest)

page <- read_html("https://www.bchsys.org/en/about-us/senior-leadership-team.aspx")
h5_elements <- page %>% html_nodes("h5.emphasis-Secondary") %>% html_text(trim = TRUE)

cat("All 6 raw elements (before splitting):\n\n")
for (i in 1:length(h5_elements)) {
  cat(i, ": ", h5_elements[i], "\n", sep = "")
  
  # Check for the separator
  if (grepl(" | ", h5_elements[i], fixed = TRUE)) {
    cat("   ✓ Contains ' | ' separator\n")
  } else {
    cat("   ✗ DOES NOT contain ' | ' separator\n")
  }
  
  # Try splitting
  parts <- strsplit(h5_elements[i], " | ", fixed = TRUE)[[1]]
  cat("   Split into ", length(parts), " parts\n", sep = "")
  
  # Show the character codes to check for hidden characters
  cat("   Character codes: ", paste(utf8ToInt(h5_elements[i])[1:min(20, nchar(h5_elements[i]))], collapse = " "), "\n\n")
}