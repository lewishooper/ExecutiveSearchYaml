# Let's manually inspect the page
library(rvest)
page <- read_html("https://www.haltonhealthcare.on.ca/about/leadership-team/executive-leadership-team")

# Check what's in the H3 elements
h3_elements <- page %>% html_nodes("h3")
h3_elements[1:3] %>% html_structure()

# Or see the raw HTML
h3_elements[1:3] %>% as.character()
library(rvest)
page <- read_html("https://www.bluewaterhealth.ca/executive-team")
