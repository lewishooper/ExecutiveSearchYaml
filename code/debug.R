# diagnose_guelph.R - Diagnose FAC-665 Guelph General Hospital
# This script will inspect the actual HTML structure and show what's happening

library(rvest)
library(stringr)

url <- "https://www.gghorg.ca/about-ggh/leadership-team/"

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║          DIAGNOSING FAC-665 GUELPH GENERAL                     ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("URL:", url, "\n\n")

tryCatch({
  page <- read_html(url)
  
  # Check all H2 elements
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("ALL H2 ELEMENTS:\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  h2_elements <- page %>% html_nodes("h2") %>% html_text(trim = TRUE)
  
  if (length(h2_elements) > 0) {
    for (i in seq_along(h2_elements)) {
      text <- h2_elements[i]
      cat(sprintf("[%d] '%s'\n", i, text))
      cat(sprintf("    Length: %d chars\n", nchar(text)))
      
      # Check for separators
      has_dash <- grepl("-", text)
      has_endash <- grepl("–", text)  # en-dash
      has_emdash <- grepl("—", text)  # em-dash
      has_pipe <- grepl("\\|", text)
      has_comma <- grepl(",", text)
      
      cat("    Separators: ")
      if (has_dash) cat("hyphen(-) ")
      if (has_endash) cat("en-dash(–) ")
      if (has_emdash) cat("em-dash(—) ")
      if (has_pipe) cat("pipe(|) ")
      if (has_comma) cat("comma(,) ")
      if (!has_dash && !has_endash && !has_emdash && !has_pipe && !has_comma) {
        cat("NONE")
      }
      cat("\n")
      
      # Try to detect name pattern
      looks_like_name <- grepl("^[A-Z][a-z]+ [A-Z]", text) || grepl("^Dr\\.", text)
      cat(sprintf("    Looks like name: %s\n", if(looks_like_name) "YES" else "NO"))
      
      cat("\n")
    }
  } else {
    cat("NO H2 elements found\n\n")
  }
  
  # Check SPAN elements
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("ALL SPAN ELEMENTS (first 20):\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  span_elements <- page %>% html_nodes("span") %>% html_text(trim = TRUE)
  
  if (length(span_elements) > 0) {
    for (i in 1:min(20, length(span_elements))) {
      text <- span_elements[i]
      if (nchar(text) > 0) {
        cat(sprintf("[%d] '%s'\n", i, text))
        
        # Check if looks like name
        looks_like_name <- grepl("^[A-Z][a-z]+ [A-Z]", text) || grepl("^Dr\\.", text)
        if (looks_like_name) {
          cat("    ⭐ POTENTIAL NAME\n")
        }
      }
    }
  } else {
    cat("NO SPAN elements found\n")
  }
  
  # Look for the actual executive names
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("SEARCHING FOR KNOWN EXECUTIVE NAMES:\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  known_names <- c("Mark Walton", "Alex Ferguson", "Gavin Webb", 
                   "Karen Suk-Patrick", "Andrea Lucas", "Julie Byczynski")
  
  page_text <- html_text(page)
  
  for (name in known_names) {
    found <- grepl(name, page_text, ignore.case = TRUE)
    cat(sprintf("%-20s %s\n", name, if(found) "✅ FOUND on page" else "❌ NOT FOUND"))
    
    if (found) {
      # Find which elements contain this name
      h2_match <- any(sapply(h2_elements, function(x) grepl(name, x, ignore.case = TRUE)))
      span_match <- any(sapply(span_elements, function(x) grepl(name, x, ignore.case = TRUE)))
      
      cat("   Found in: ")
      if (h2_match) cat("H2 ")
      if (span_match) cat("SPAN ")
      cat("\n")
    }
  }
  
  # Check for executive titles/keywords
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("EXECUTIVE KEYWORDS ON PAGE:\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  keywords <- c("CEO", "Chief", "President", "CFO", "CNE", "Executive", "Officer")
  
  for (kw in keywords) {
    matches <- str_count(page_text, regex(kw, ignore.case = TRUE))
    if (matches > 0) {
      cat(sprintf("%-15s %3d occurrences\n", kw, matches))
    }
  }
  
  # Try to identify the actual structure
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("STRUCTURE ANALYSIS:\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")
  
  # Check for common container divs
  leader_divs <- page %>% html_nodes("div[class*='leader'], div[class*='exec'], div[class*='team']")
  cat("Divs with leader/exec/team in class:", length(leader_divs), "\n")
  
  # Check for specific structure patterns
  cat("\nLooking for name-title pairs...\n\n")
  
  # Pattern: h2 for name, p for title
  all_h2 <- page %>% html_nodes("h2")
  for (i in seq_along(all_h2)) {
    h2_text <- html_text(all_h2[[i]], trim = TRUE)
    
    # Check if looks like a name
    if (grepl("^[A-Z][a-z]+ |^Dr\\.", h2_text)) {
      # Look for following p
      parent <- xml2::xml_parent(all_h2[[i]])
      siblings <- xml2::xml_siblings(parent)
      
      cat("H2:", h2_text, "\n")
      
      # Get next few siblings to see structure
      next_nodes <- xml2::xml_find_all(parent, "following-sibling::*[position()<=2]")
      for (j in seq_along(next_nodes)) {
        node_name <- xml2::xml_name(next_nodes[[j]])
        node_text <- xml2::xml_text(next_nodes[[j]], trim = TRUE)
        if (nchar(node_text) > 0 && nchar(node_text) < 200) {
          cat("  Following", node_name, ":", substr(node_text, 1, 100), "\n")
        }
      }
      cat("\n")
    }
  }
  
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
})

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("RECOMMENDATIONS:\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Based on the analysis above:\n")
cat("1. Check which element type actually contains the names (H2 or SPAN)\n")
cat("2. Identify the separator character (dash, en-dash, pipe, etc.)\n")
cat("3. Determine if it's combined_h2 or a sequential pattern\n")
cat("4. Update next_batch_template.yaml accordingly\n\n")

cat("Run this script and share the output to get specific recommendations!\n")