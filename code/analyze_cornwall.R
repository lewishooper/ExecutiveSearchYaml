# Analyze Cornwall Community Hospital Structure

library(rvest)
library(xml2)
library(stringr)

cat("=== ANALYZING CORNWALL COMMUNITY HOSPITAL ===\n\n")

url <- "https://www.cornwallhospital.ca/en/SeniorAdmin"
page <- read_html(url)

cat("URL:", url, "\n\n")

# Search for executive keywords
cat("=== SEARCHING FOR EXECUTIVE KEYWORDS ===\n")
all_text <- html_text(page)

keywords <- c("President", "CEO", "Chief", "Director", "Officer", "Vice President", "Administrator")

for (keyword in keywords) {
  if (grepl(keyword, all_text, ignore.case = TRUE)) {
    pattern <- paste0(".{0,60}", keyword, ".{0,60}")
    matches <- str_extract_all(all_text, regex(pattern, ignore_case = TRUE))[[1]]
    if (length(matches) > 0) {
      cat("✓ Found:", keyword, "\n")
      cat("  Context:", substr(matches[1], 1, 120), "\n")
    }
  }
}

# Check H2 elements
cat("\n=== H2 ELEMENTS ===\n")
h2s <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
for (i in 1:length(h2s)) {
  cat(sprintf("H2[%d]: %s\n", i, h2s[i]))
}

# Check H3 elements
cat("\n=== H3 ELEMENTS ===\n")
h3s <- page %>% html_nodes("h3") %>% html_text(trim = TRUE)
for (i in 1:min(20, length(h3s))) {
  cat(sprintf("H3[%d]: %s\n", i, h3s[i]))
}

# Check P elements
cat("\n=== FIRST 30 P ELEMENTS ===\n")
ps <- page %>% html_nodes("p") %>% html_text(trim = TRUE)
for (i in 1:min(30, length(ps))) {
  if (nchar(ps[i]) > 0) {
    cat(sprintf("P[%d]: %s\n", i, substr(ps[i], 1, 120)))
  }
}

# Check for STRONG elements
cat("\n=== STRONG ELEMENTS ===\n")
strongs <- page %>% html_nodes("strong") %>% html_text(trim = TRUE)
cat("Found", length(strongs), "strong elements\n")
for (i in 1:min(20, length(strongs))) {
  if (nchar(strongs[i]) > 0) {
    cat(sprintf("STRONG[%d]: %s\n", i, substr(strongs[i], 1, 100)))
  }
}

# Check P > STRONG structure
cat("\n=== P > STRONG STRUCTURE ===\n")
p_strongs <- page %>% html_nodes("p strong")
cat("Found", length(p_strongs), "p > strong elements\n\n")

for (i in 1:min(10, length(p_strongs))) {
  strong_text <- html_text(p_strongs[[i]], trim = TRUE)
  
  # Get the parent P element
  parent_p <- xml_parent(p_strongs[[i]])
  full_p_text <- html_text(parent_p, trim = TRUE)
  
  # Get the next sibling
  next_elem <- xml_sibling(parent_p)
  next_name <- if (!is.na(next_elem)) html_name(next_elem) else "N/A"
  next_text <- if (!is.na(next_elem)) html_text(next_elem, trim = TRUE) else "N/A"
  
  cat(sprintf("=== P>STRONG #%d ===\n", i))
  cat("STRONG:", strong_text, "\n")
  cat("Full P:", full_p_text, "\n")
  cat("Next elem type:", next_name, "\n")
  cat("Next elem text:", substr(next_text, 1, 100), "\n\n")
}

# Look for DIV structure
cat("\n=== CHECKING DIV CLASSES ===\n")
divs_with_class <- page %>% html_nodes("div[class]")
classes <- unique(html_attr(divs_with_class, "class"))
cat("Found", length(classes), "unique div classes\n")

# Look for any div containing executive names
cat("\n=== DIVS CONTAINING 'CHIEF' OR 'PRESIDENT' ===\n")
exec_divs <- page %>% html_nodes("div") %>% 
  keep(~grepl("Chief|President|Officer", html_text(.x, trim=TRUE), ignore.case=TRUE))

for (i in 1:min(10, length(exec_divs))) {
  div_class <- html_attr(exec_divs[[i]], "class")
  div_text <- html_text(exec_divs[[i]], trim = TRUE)
  
  cat(sprintf("\nDIV #%d (class: %s):\n", i, 
              if(is.na(div_class)) "none" else div_class))
  cat("Text:", substr(div_text, 1, 150), "\n")
  
  # Show children
  children <- xml_children(exec_divs[[i]])
  if (length(children) > 0 && length(children) < 10) {
    cat("Children:", paste(html_name(children), collapse=", "), "\n")
  }
}

# Sequential structure analysis
cat("\n=== SEQUENTIAL STRUCTURE (First 40 elements) ===\n")
all_elems <- page %>% html_nodes("body *")
count <- 0

for (elem in all_elems) {
  elem_text <- html_text(elem, trim = TRUE)
  
  # Look for executive-related content
  if (grepl("Chief|President|Officer|Director|Vacant", elem_text, ignore.case = TRUE) &&
      nchar(elem_text) < 200) {
    count <- count + 1
    if (count <= 20) {
      elem_name <- html_name(elem)
      has_strong <- length(xml_children(elem) %>% keep(~html_name(.x) == "strong")) > 0
      
      cat(sprintf("\n[%d] <%s>%s\n", count, elem_name, 
                  if(has_strong) " [HAS STRONG]" else ""))
      cat("Text:", substr(elem_text, 1, 120), "\n")
    }
  }
}

cat("\n=== ANALYSIS COMPLETE ===\n")
source("analyze_cornwall.R")
