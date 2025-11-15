# Let's examine the actual page structure
library(rvest)
url <- "https://kingstonhsc.ca/about-khsc/senior-leadership-team"
page <- read_html(url)

# Find all names
names <- page %>% html_elements(".field--name-title") %>% html_text2()
cat("Found", length(names), "names:\n")
print(names)

# Find all titles
titles <- page %>% html_elements(".field--name-field-position") %>% html_text2()
cat("\nFound", length(titles), "titles:\n")
print(titles)

# Check if there's a container we should be using
cat("\n=== Looking for containers ===\n")
# The HTML shows a div.teaser-title-header - let's check that
containers <- page %>% html_elements("div.teaser-title-header")
cat("Found", length(containers), "teaser-title-header containers\n")
