library(rvest)
library(xml2)

url <- "https://www.hanoverhospital.on.ca/our-team"
page <- read_html(url)

# Get all <strong> tags with font-size: 19px (these seem to be names)
names <- page %>% 
  html_nodes("strong[style*='font-size: 19px']") %>%
  html_text(trim = TRUE)

# Get all <strong> tags that are NOT styled (these seem to be titles)
all_strong <- page %>% 
  html_nodes("strong") %>%
  html_text(trim = TRUE)

cat("Names (with font-size 19px):\n")
print(names)

cat("\n\nAll strong tags:\n")
print(all_strong)