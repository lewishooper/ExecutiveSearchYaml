# Check for br tags
br_count <- page %>% html_nodes("br") %>% length()
cat("Number of <br> tags:", br_count, "\n")

# Look at a specific paragraph structure
first_person_p <- page %>% html_nodes("p") %>% .[[7]]
cat("\nHTML of first person paragraph:\n")
print(html_structure(first_person_p))