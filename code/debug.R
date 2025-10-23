library(rvest)
page <- read_html("https://www.theroyal.ca/about-royal/leadership/senior-leadership-team")

# Check if names are in bold/strong tags
cat("=== Checking for bold/strong in p elements ===\n")
p_with_bold <- page %>% html_nodes("p strong, p b")
cat("Number of p elements with bold/strong:", length(p_with_bold), "\n")
print(p_with_bold %>% html_text(trim = TRUE))

# Also check the actual structure
cat("\n=== First executive p element structure ===\n")
first_exec_p <- page %>% html_nodes("p") %>% .[grepl("Cara Vaccarino", as.character(.))]
print(first_exec_p %>% as.character())

