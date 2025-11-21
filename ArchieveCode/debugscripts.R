# Hotel Dieu Shaver (FAC 790) Debugging
library(rvest)

page <- read_html("https://www.hoteldieushaver.org/site/team")

cat("=== HOTEL DIEU SHAVER DEBUG ===\n\n")

# Get all LI elements
li_elements <- page %>% html_nodes("li") %>% html_text(trim = TRUE)

cat("1. Total LI elements found:", length(li_elements), "\n\n")

# Look for executive names
cat("2. LI elements containing executive keywords:\n")
exec_keywords <- c("CEO", "Chief", "President", "Vice President", "Director", "Manager")

exec_lis <- c()
for (i in 1:length(li_elements)) {
  for (kw in exec_keywords) {
    if (grepl(kw, li_elements[i], ignore.case = TRUE)) {
      exec_lis <- c(exec_lis, i)
      break
    }
  }
}

cat("   Found", length(exec_lis), "LI elements with executive titles\n\n")

if (length(exec_lis) > 0) {
  cat("3. First 10 executive LI elements:\n")
  for (i in 1:min(10, length(exec_lis))) {
    idx <- exec_lis[i]
    cat("   ", idx, ":", li_elements[idx], "\n")
  }
}

# Test splitting with pipe
cat("\n4. Testing pipe separator on first few:\n")
for (i in 1:min(5, length(exec_lis))) {
  idx <- exec_lis[i]
  text <- li_elements[idx]
  
  # Try splitting with flexible regex
  parts <- strsplit(text, "\\s*\\|\\s*")[[1]]
  
  cat("\n   LI", idx, ":", text, "\n")
  cat("   Split into", length(parts), "parts:\n")
  for (j in 1:length(parts)) {
    cat("     Part", j, ":", trimws(parts[j]), "\n")
  }
}

# Check for Dr. David Ceglie specifically
cat("\n5. Looking for Dr. David Ceglie:\n")
ceglie_found <- FALSE
for (i in 1:length(li_elements)) {
  if (grepl("Ceglie", li_elements[i], ignore.case = TRUE)) {
    cat("   Found at position", i, ":\n")
    cat("   Raw:", li_elements[i], "\n")
    parts <- strsplit(li_elements[i], "\\s*\\|\\s*")[[1]]
    cat("   Parts:", paste(parts, collapse=" || "), "\n")
    ceglie_found <- TRUE
  }
}
if (!ceglie_found) cat("   NOT FOUND\n")





library(rvest)

page <- read_html("https://quintehealth.ca/about-quinte-health/leadership/")

cat("=== BELLEVILLE QUINTE DEBUG ===\n\n")

li_elements <- page %>% html_nodes("li") %>% html_text(trim = TRUE)

cat("1. Total LI elements found:", length(li_elements), "\n\n")

# Look for all executives
exec_keywords <- c("CEO", "Chief", "President", "Vice President", "Director")

cat("2. All LI elements with executive titles:\n")
for (i in 1:length(li_elements)) {
  for (kw in exec_keywords) {
    if (grepl(kw, li_elements[i], ignore.case = TRUE)) {
      cat("   ", i, ":", li_elements[i], "\n")
      
      # Test splitting
      parts <- strsplit(li_elements[i], "\\s*,\\s*")[[1]]
      cat("      Split into", length(parts), "parts:", paste(parts, collapse=" || "), "\n")
      
      if (length(parts) >= 2) {
        name <- parts[1]
        title <- paste(parts[2:length(parts)], collapse=", ")
        cat("      → Name:", name, "| Title:", title, "\n")
      }
      cat("\n")
      break
    }
  }
}

# Specifically look for MacPherson
cat("3. Searching for MacPherson:\n")
for (i in 1:length(li_elements)) {
  if (grepl("MacPherson", li_elements[i], ignore.case = TRUE)) {
    cat("   FOUND at position", i, ":", li_elements[i], "\n")
  }
}


library(stringr)

test_name <- "Dr. Colin MacPherson"
patterns <- c(
  "^Dr\\.? [A-Z][a-z]+ [A-Z][a-z]+$",
  "^(Dr\\.?\\s+)?[A-Z][\\w'-]+(\\s+[A-Z][\\w'-]+)+$"
)

for (p in patterns) {
  result <- grepl(p, test_name)
  cat("Pattern:", p, "\n")
  cat("  Result:", result, "\n\n")
}