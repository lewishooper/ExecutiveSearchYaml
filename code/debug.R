library(rvest)
url <- "https://www.bruyere.org/en/leadership-team?v=1"
page <- read_html(url)

# Get all H2 elements
h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)

cat("=== ALL H2 ELEMENTS ===\n")
for (i in seq_along(h2_elements)) {
  cat(i, ":", h2_elements[i], "\n")
  
  # Check if it matches name patterns
  text <- h2_elements[i]
  
  # Test the validation logic from scrape_h2_name_p_title
  cat("  Length:", nchar(text), "\n")
  cat("  Has space:", grepl("\\s", text), "\n")
  cat("  Matches [A-Z][a-z]+ pattern:", grepl("^[A-Z][a-z]+", text), "\n")
  cat("  Contains é or other accents:", grepl("[éèêëàâäôöûüçñ]", text, ignore.case = TRUE), "\n")
  
  # Check what the name validation function would do
  is_non_name <- grepl("^(About|Contact|Our|The|Welcome|Home|Menu|Navigation)", text, ignore.case = TRUE)
  cat("  Flagged as non-name:", is_non_name, "\n\n")
}

# Now let's see what the actual pattern matching logic does
cat("\n=== TESTING NAME PATTERN MATCHING ===\n")

test_names <- c(
  "Mélanie Dubé",
  "Melanie Dube", 
  "John Smith",
  "Dr. Sarah Jones",
  "About Bruyère Health"
)

for (name in test_names) {
  # Simulate the pattern check
  matches_pattern <- grepl("^(Dr\\.?\\s+)?[A-Z][a-zà-ÿ]+\\s+[A-Z][a-zà-ÿ]+", name)
  is_non_name <- grepl("^(About|Contact|Our|The|Welcome|Home|Menu|Navigation)", name, ignore.case = TRUE)
  
  cat(name, ":\n")
  cat("  Matches pattern:", matches_pattern, "\n")
  cat("  Is non-name:", is_non_name, "\n")
  cat("  Would be accepted:", matches_pattern && !is_non_name, "\n\n")
}
