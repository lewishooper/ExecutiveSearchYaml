# debug_606.R - Analyze Barrie Royal Victoria Hospital
# Run from E:/ExecutiveSearchYaml/code/

setwd("E:/ExecutiveSearchYaml/code/")

library(rvest)
library(stringr)

url <- "https://www.rvh.on.ca/about-rvh/senior-leadership-team/"

cat("=== ANALYZING BARRIE ROYAL VICTORIA (FAC-606) ===\n")
cat("URL:", url, "\n\n")

page <- read_html(url)

# Check element counts
cat("ELEMENT COUNTS:\n")
cat("  H1:", length(page %>% html_nodes("h1")), "\n")
cat("  H2:", length(page %>% html_nodes("h2")), "\n")
cat("  H3:", length(page %>% html_nodes("h3")), "\n")
cat("  H4:", length(page %>% html_nodes("h4")), "\n")
cat("  P:", length(page %>% html_nodes("p")), "\n")
cat("  Divs:", length(page %>% html_nodes("div")), "\n\n")

# Check for the classes mentioned in YAML
cat("=== CHECKING YAML-SPECIFIED CLASSES ===\n")
card_table <- page %>% html_nodes(".card-table")
cat("Elements with class 'card-table':", length(card_table), "\n")

card_subtable <- page %>% html_nodes(".card-subtable")
cat("Elements with class 'card-subtable':", length(card_subtable), "\n")

card_info <- page %>% html_nodes(".card-info")
cat("Elements with class 'card-info':", length(card_info), "\n\n")

# Sample content from these classes
if (length(card_table) > 0) {
  cat("SAMPLE 'card-table' CONTENT (first 10):\n")
  for (i in 1:min(10, length(card_table))) {
    text <- html_text(card_table[[i]], trim = TRUE)
    if (nchar(text) > 0 && nchar(text) < 100) {
      cat(sprintf("%2d: %s\n", i, text))
    }
  }
  cat("\n")
}

if (length(card_subtable) > 0) {
  cat("SAMPLE 'card-subtable' CONTENT (first 10):\n")
  for (i in 1:min(10, length(card_subtable))) {
    text <- html_text(card_subtable[[i]], trim = TRUE)
    if (nchar(text) > 0 && nchar(text) < 100) {
      cat(sprintf("%2d: %s\n", i, text))
    }
  }
  cat("\n")
}

# Look for common leadership-related classes
cat("=== SEARCHING FOR LEADERSHIP-RELATED CLASSES ===\n")
all_classes <- page %>% html_nodes("*[class]") %>% html_attr("class")
leadership_classes <- grep("(name|title|executive|leader|staff|team|bio|card|member)", 
                           all_classes, ignore.case = TRUE, value = TRUE)
unique_classes <- unique(leadership_classes)[1:min(20, length(unique(leadership_classes)))]

cat("Found", length(unique_classes), "potentially relevant classes:\n")
for (cls in unique_classes) {
  cat("  -", cls, "\n")
}

# Check H2/H3 as backup
cat("\n=== BACKUP: H2/H3 ELEMENTS ===\n")
h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
h3_elements <- page %>% html_nodes("h3") %>% html_text(trim = TRUE)

if (length(h2_elements) > 0) {
  cat("H2 elements (first 10):\n")
  for (i in 1:min(10, length(h2_elements))) {
    cat(sprintf("%2d: %s\n", i, h2_elements[i]))
  }
}

if (length(h3_elements) > 0) {
  cat("\nH3 elements (first 10):\n")
  for (i in 1:min(10, length(h3_elements))) {
    cat(sprintf("%2d: %s\n", i, h3_elements[i]))
  }
}

# Search for known executive names
cat("\n=== SEARCHING FOR EXECUTIVE KEYWORDS ===\n")
page_text <- tolower(html_text(page))
exec_keywords <- c("ceo", "president", "chief nursing", "chief medical", "vice president", "cfo")

for (kw in exec_keywords) {
  if (grepl(kw, page_text)) {
    cat("✓ Found:", kw, "\n")
  }
}
source("debug_606.R")
