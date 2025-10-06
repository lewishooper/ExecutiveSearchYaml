# boardcard_pattern_handler.R - Handle special patterns like Thunder Bay (FAC=935)
# Save this in E:/ExecutiveSearchYaml/code/

# Add this function to the pattern_based_scraper.R or source it separately

# Pattern 7: Boardcard gallery pattern (for Thunder Bay FAC=935)
scrape_boardcard_pattern <- function(page, hospital_info, config) {
  tryCatch({
    # Get all boardcard divs
    boardcard_elements <- page %>% html_nodes("div.boardcard") %>% html_text(trim = TRUE)
    
    pairs <- list()
    
    for (boardcard_text in boardcard_elements) {
      # Clean the text
      clean_text <- clean_text_data(boardcard_text)
      
      # Look for name and title separated by comma
      # Pattern: "Name, Title" or "Dr. Name, Title"
      if (grepl(",", clean_text)) {
        parts <- strsplit(clean_text, ",")[[1]]
        
        if (length(parts) >= 2) {
          potential_name <- trimws(parts[1])
          potential_title <- trimws(parts[2])
          
          # Additional cleaning - sometimes there's extra text after title
          # Take only the first sentence/phrase of the title
          potential_title <- trimws(strsplit(potential_title, "\\.")[[1]][1])
          
          if (is_executive_name(potential_name, config) && 
              is_executive_title(potential_title, config)) {
            
            pairs[[length(pairs) + 1]] <- list(
              name = potential_name,
              title = potential_title
            )
          }
        }
      }
    }
    
    return(pairs)
    
  }, error = function(e) {
    return(list())
  })
}

# Update the enhanced_hospitals.yaml to include Thunder Bay configuration:
thunderbay_config <- '
# Thunder Bay - Special boardcard gallery pattern
- FAC: "935"
  name: "Thunder Bay Regional Health Sciences Centre" 
  url: "https://tbrhsc.net/about-us/leadership/"
  pattern: "boardcard_gallery"
  expected_executives: 8
  html_structure:
    container_class: "boardcard"
    text_format: "name_comma_title"
    separator: ","
    notes: "Gallery of senior leaders, each in div.boardcard with Name, Title format"
  status: "configured"
'

cat("=== BOARDCARD PATTERN HANDLER ===\n")
cat("Add this configuration to enhanced_hospitals.yaml:\n")
cat(thunderbay_config)
cat("\nThen update pattern_based_scraper.R to include 'boardcard_gallery' in the switch statement\n")
