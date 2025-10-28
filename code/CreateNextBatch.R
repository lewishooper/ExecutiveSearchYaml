# Create next batch
#!/usr/bin/env Rscript
rm(list=ls())
# Load required libraries
library(readxl)
library(yaml)
sourceFile<-"E:/ExecutiveSearchYaml/Archives/remaining.xlsx"
# Read the Excel file
excel_data <- read_excel(sourceFile)

# Verify the expected columns exist
required_cols <- c("FAC", "Hospital", "Type")
if (!all(required_cols %in% names(excel_data))) {
  stop("Excel file must contain columns: FAC, Hospital, Type")
}

# Create the YAML structure
yaml_list <- list()

for (i in 1:nrow(excel_data)) {
  entry <- list(
    FAC = as.character(excel_data$FAC[i]),
    name = as.character(excel_data$Hospital[i]),
    hospital_type = as.character(excel_data$Type[i]),
    url = NULL,
    pattern = "div_classes",
    expected_executives = NULL,
    html_structure = list(
      NULL,
      NULL
    ),
    notes = NULL,
    status = NULL
  )
  
  yaml_list[[i]] <- entry
}

# Convert to YAML with custom formatting
yaml_text <- as.yaml(yaml_list, 
                     indent = 2,
                     indent.mapping.sequence = TRUE)

# Post-process to ensure proper formatting
# Add blank lines between html_structure and notes
yaml_text <- gsub("(html_structure:\n    - null\n    - null\n)", 
                  "html_structure:\n    \n    \n  ", 
                  yaml_text)

# Ensure single quotes around FAC, name, and hospital_type values
lines <- strsplit(yaml_text, "\n")[[1]]
formatted_lines <- character(length(lines))

for (i in seq_along(lines)) {
  line <- lines[i]
  
  # Add quotes around FAC, name, and hospital_type values
  if (grepl("^  FAC:", line)) {
    line <- sub("FAC: (.+)$", "FAC: '\\1'", line)
  } else if (grepl("^  name:", line)) {
    line <- sub("name: (.+)$", "name: '\\1'", line)
  } else if (grepl("^  hospital_type:", line)) {
    line <- sub("hospital_type: (.+)$", "hospital_type: '\\1'", line)
  }
  
  formatted_lines[i] <- line
}

yaml_text <- paste(formatted_lines, collapse = "\n")

# Write to file
writeLines(yaml_text, "E:/ExecutiveSearchYaml/Archives/next_batch_template.yaml")

cat("Successfully created next_batch_template.yaml with", nrow(excel_data), "entries\n")
