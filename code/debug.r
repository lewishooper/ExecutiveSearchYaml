library(rvest)
url <- "https://web.lacgh.napanee.on.ca/about/governance/"
page <- read_html(url)

# Look for executive-related text
page_text <- page %>% html_text2()

# Search for keywords
cat("Looking for executive keywords in page text:\n\n")
if (grepl("President|CEO|Chief", page_text, ignore.case = TRUE)) {
  # Extract surrounding context
  lines <- strsplit(page_text, "\n")[[1]]
  exec_lines <- lines[grepl("President|CEO|Chief|Executive", lines, ignore.case = TRUE)]
  
  cat("Lines containing executive keywords:\n")
  for (line in head(exec_lines, 10)) {
    cat("-", trimws(line), "\n")
  }
}

# Also check for any p elements that might contain executive info
cat("\n\nChecking P elements:\n")
all_p <- page %>% html_nodes("p") %>% html_text2()
exec_p <- all_p[grepl("President|CEO|Chief", all_p, ignore.case = TRUE)]

for (i in seq_along(exec_p)) {
  cat("\nP element", i, ":\n")
  cat(exec_p[i], "\n")
}