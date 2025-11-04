# Extract Hospital FAC, Name, and Status from enhanced_hospitals.yaml
# This script reads the enhanced_hospitals.yaml file and creates a dataframe
# with FAC, Hospital Name, and Status columns
#rm(list=ls())
library(yaml)
library(dplyr)

# Read the YAML file
hospitals_data <- read_yaml("E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml")

# Extract the hospitals list
hospitals_list <- hospitals_data$hospitals

# Create a dataframe with FAC, name, and status
# Using a more robust approach to handle NULL values
hospital_df <- do.call(rbind, lapply(hospitals_list, function(hospital) {
  # Check if hospital is NULL or empty
  if (is.null(hospital) || length(hospital) == 0) {
    return(NULL)
  }
  
  # Extract values with safe defaults
  fac_value <- if (is.null(hospital$FAC)) NA_character_ else as.character(hospital$FAC)
  name_value <- if (is.null(hospital$name)) NA_character_ else as.character(hospital$name)
  notes_value <- if (is.null(hospital$notes)) NA_character_ else as.character(hospital$notes)
  
  status_value <- if (is.null(hospital$status)) NA_character_ else as.character(hospital$status)
  
  data.frame(
    FAC = fac_value,
    Hospital_Name = name_value,
    Status = status_value,
    Notes= notes_value,
    stringsAsFactors = FALSE
  )
}))

# Remove any NULL rows
hospital_df <- hospital_df[!is.na(hospital_df$FAC), ]

# Replace remaining NA values with appropriate defaults
hospital_df$FAC[is.na(hospital_df$FAC)] <- ""
hospital_df$Hospital_Name[is.na(hospital_df$Hospital_Name)] <- ""
hospital_df$Status[is.na(hospital_df$Status)] <- "unknown"

# Display the dataframe
print(paste("Total hospitals:", nrow(hospital_df)))
print(head(hospital_df, 10))

# Summary of status values
print("\nStatus Summary:")
print(table(hospital_df$Status))

# Return the dataframe (useful if sourcing this script)
hospital_df

JustMER<-hospital_df %>%
  filter(Status=="ok-MER")
