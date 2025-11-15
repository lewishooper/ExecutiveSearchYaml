library(rvest)
url <- "HOSPITAL_URL_HERE"
page <- read_html(url)

# Test your suspected container class
test_class <- "YOUR_CLASS_HERE"  # e.g., "team-member"
containers <- page %>% html_elements(paste0(".", test_class))

cat("Found", length(containers), "containers\n\n")

# Check first 3 containers
for (i in 1:min(3, length(containers))) {
  cat("=== Container", i, "===\n")
  
  # Try to find name within this container
  name <- containers[[i]] %>% 
    html_element(".name-class-here") %>%  # Use your name_class
    html_text2()
  
  # Try to find title within this container
  title <- containers[[i]] %>% 
    html_element(".title-class-here") %>%  # Use your title_class
    html_text2()
  
  cat("Name:", name, "\n")
  cat("Title:", title, "\n\n")
}