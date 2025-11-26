library(yaml)
library(dplyr)

# Function to extract manually entered executives from enhanced_hospitals.yaml
extract_manual_entries <- function(yaml_path = "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml") {
  
  # Read the YAML file
  yaml_data <- yaml::read_yaml(yaml_path)
  hospitals_list <- yaml_data$hospitals
  
  # Initialize results list
  manual_entries <- list()
  
  # Process each hospital
  for (i in seq_along(hospitals_list)) {
    hospital <- hospitals_list[[i]]
    
    # Get FAC, hospital name and URL - handle NULL values
    fac <- if (is.null(hospital$FAC)) NA else hospital$FAC
    hospital_name <- if (is.null(hospital$name)) NA else hospital$name
    url <- if (is.null(hospital$url)) NA else hospital$url
    
    # Check for manual_entry_required pattern
    if (!is.null(hospital$pattern) && hospital$pattern == "manual_entry_required") {
      
      # Extract executives from known_executives field
      if (!is.null(hospital$known_executives)) {
        for (j in seq_along(hospital$known_executives)) {
          exec <- hospital$known_executives[[j]]
          manual_entries[[length(manual_entries) + 1]] <- list(
            FAC = as.character(fac),
            Hospital_Name = hospital_name,
            URL = url,
            Name = if (is.null(exec$name)) NA else exec$name,
            Title = if (is.null(exec$title)) NA else exec$title,
            Source = "manual_entry_required"
          )
        }
      }
    }
    
    # Check for missing_people entries
    if (!is.null(hospital$missing_people)) {
      for (k in seq_along(hospital$missing_people)) {
        person <- hospital$missing_people[[k]]
        manual_entries[[length(manual_entries) + 1]] <- list(
          FAC = as.character(fac),
          Hospital_Name = hospital_name,
          URL = url,
          Name = if (is.null(person$name)) NA else person$name,
          Title = if (is.null(person$title)) NA else person$title,
          Source = "missing_people"
        )
      }
    }
  }
  
  # Convert to data frame
  if (length(manual_entries) > 0) {
    df <- bind_rows(manual_entries)
    
    # Reorder columns for clarity
    df <- df %>%
      select(FAC, Hospital_Name, URL, Name, Title, Source)
    
    return(df)
  } else {
    message("No manual entries found.")
    return(NULL)
  }
}

# Example usage:
# manual_execs <- extract_manual_entries()
# View(manual_execs)
# 
# # Export to CSV for review/editing
# write.csv(manual_execs, "manual_entries_for_update.csv", row.names = FALSE)
# 
# # Filter by source if needed
# manual_pattern_only <- manual_execs %>% filter(Source == "manual_entry_required")
# missing_people_only <- manual_execs %>% filter(Source == "missing_people")

# Run the function
manual_execs <- extract_manual_entries()

# Display summary
if (!is.null(manual_execs)) {
  cat("\n=== MANUAL ENTRIES SUMMARY ===\n")
  cat("Total manual entries:", nrow(manual_execs), "\n")
  cat("\nBreakdown by source:\n")
  print(table(manual_execs$Source))
  cat("\nBreakdown by hospital (top 10):\n")
  print(head(sort(table(manual_execs$Hospital_Name), decreasing = TRUE), 10))
  
  # Display the data
  cat("\n=== MANUAL ENTRIES DATA ===\n")
  print(manual_execs)
}

manual_execs <- extract_manual_entries()
write.csv(manual_execs, "E:/ExecutiveSearchYaml/output/manual_entries_for_update.csv", row.names = FALSE)
saveRDS(manual_execs,"E:/ExecutiveSearchYaml/output/manual_entries_for_updateNov25.rds")

