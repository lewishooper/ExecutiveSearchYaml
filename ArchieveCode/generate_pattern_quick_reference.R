# generate_pattern_quick_reference.R
# Automatically generate Pattern Quick Reference Guide from enhanced_hospitals.yaml
# Save in: E:/ExecutiveSearchYaml/code/

library(yaml)
library(dplyr)

cat("═══════════════════════════════════════════════════════════════\n")
cat("GENERATING PATTERN QUICK REFERENCE GUIDE\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Read enhanced_hospitals.yaml
yaml_file <- "E:/ExecutiveSearchYaml/code/enhanced_hospitals.yaml"
config <- yaml::read_yaml(yaml_file)

cat("Reading configuration from:", yaml_file, "\n")
cat("Total hospitals:", length(config$hospitals), "\n\n")

# Extract pattern information
pattern_info <- list()

for (hospital in config$hospitals) {
  pattern <- hospital$pattern
  
  if (is.null(pattern) || pattern == "") {
    next
  }
  
  # Initialize pattern entry if it doesn't exist
  if (!pattern %in% names(pattern_info)) {
    pattern_info[[pattern]] <- list(
      structure_fields = list(),
      elements = list(),
      hospitals = list()
    )
  }
  
  # Get html_structure fields
  if (!is.null(hospital$html_structure)) {
    structure_fields <- names(hospital$html_structure)
    # Store unique structure fields for this pattern
    pattern_info[[pattern]]$structure_fields <- unique(c(
      pattern_info[[pattern]]$structure_fields, 
      structure_fields
    ))
    
    # Store example values for elements
    for (field in structure_fields) {
      value <- hospital$html_structure[[field]]
      # Skip NULL, lists, and check for empty strings safely
      if (!is.null(value) && !is.list(value)) {
        # Convert to character and check length
        value_char <- as.character(value)
        if (length(value_char) > 0 && value_char[1] != "") {
          pattern_info[[pattern]]$elements[[field]] <- unique(c(
            pattern_info[[pattern]]$elements[[field]], 
            value_char[1]  # Only take first element
          ))
        }
      }
    }
  }
  
  # Store hospital FAC and name
  fac <- hospital$FAC
  name <- hospital$name
  if (!is.null(fac) && !is.null(name)) {
    pattern_info[[pattern]]$hospitals <- c(
      pattern_info[[pattern]]$hospitals,
      paste0("FAC-", fac, " ", name)
    )
  }
}

cat("Patterns found:", length(pattern_info), "\n\n")

# Sort patterns alphabetically
pattern_names <- sort(names(pattern_info))

# Generate HTML table
html_content <- '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Hospital Scraper - Pattern Quick Reference Guide</title>
    <style>
        @page {
            size: landscape;
            margin: 0.5in;
        }
        body {
            font-family: "Calibri", "Arial", sans-serif;
            margin: 0;
            padding: 20px;
        }
        h1 {
            text-align: center;
            font-size: 18pt;
            margin-bottom: 20px;
            color: #2C3E50;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 10pt;
        }
        th {
            background-color: #2C3E50;
            color: white;
            padding: 10px;
            text-align: left;
            font-weight: bold;
            border: 1px solid #34495E;
        }
        td {
            padding: 8px;
            border: 1px solid #BDC3C7;
            vertical-align: top;
        }
        tr:nth-child(even) {
            background-color: #ECF0F1;
        }
        tr:nth-child(odd) {
            background-color: white;
        }
        .pattern-col {
            width: 18%;
            font-weight: bold;
            color: #2C3E50;
        }
        .structure-col {
            width: 30%;
            font-family: "Courier New", monospace;
            white-space: pre-line;
            background-color: #F8F9FA;
        }
        .elements-col {
            width: 28%;
            font-size: 9pt;
        }
        .examples-col {
            width: 24%;
            font-size: 9pt;
        }
        .footer {
            margin-top: 20px;
            text-align: center;
            font-size: 10pt;
            color: #7F8C8D;
        }
    </style>
</head>
<body>
    <h1>Hospital Scraper - Pattern Quick Reference Guide</h1>
    <p style="text-align: center; color: #7F8C8D; margin-bottom: 20px;">
        Generated from enhanced_hospitals.yaml | Total Patterns: ' 

html_content <- paste0(html_content, length(pattern_info), ' | Total Hospitals: ', 
                       length(config$hospitals), '</p>
    
    <table>
        <thead>
            <tr>
                <th class="pattern-col">Pattern</th>
                <th class="structure-col">HTML Structure Items<br>(copy/paste into YAML)</th>
                <th class="elements-col">Elements in the Structure</th>
                <th class="examples-col">FAC & Hospital Examples</th>
            </tr>
        </thead>
        <tbody>
')

# Generate table rows
for (pattern in pattern_names) {
  info <- pattern_info[[pattern]]
  
  # Column 2: Structure fields (with colons)
  structure_fields <- paste0(info$structure_fields, ":", collapse = "\n")
  
  # Column 3: Example values for each field
  elements_text <- ""
  for (field in info$structure_fields) {
    if (field %in% names(info$elements)) {
      values <- info$elements[[field]]
      # Limit to first 3 examples
      values <- head(values, 3)
      elements_text <- paste0(elements_text, paste(values, collapse = ", "), "\n")
    } else {
      elements_text <- paste0(elements_text, "(varies)\n")
    }
  }
  elements_text <- trimws(elements_text)
  
  # Column 4: Hospital examples (limit to first 3)
  hospitals <- head(info$hospitals, 3)
  hospitals_text <- paste(hospitals, collapse = "\n")
  
  # Add row
  html_content <- paste0(html_content, '
            <tr>
                <td class="pattern-col">', pattern, '</td>
                <td class="structure-col">', structure_fields, '</td>
                <td class="elements-col">', elements_text, '</td>
                <td class="examples-col">', hospitals_text, '</td>
            </tr>')
}

# Close HTML
html_content <- paste0(html_content, '
        </tbody>
    </table>
    
    <div class="footer">
        <p>Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</p>
        <p>Print in landscape mode for best viewing</p>
    </div>
</body>
</html>')

# Write HTML file
output_file <- "E:/ExecutiveSearchYaml/code/Pattern_Quick_Reference.html"
writeLines(html_content, output_file)

cat("═══════════════════════════════════════════════════════════════\n")
cat("✅ PATTERN QUICK REFERENCE GUIDE GENERATED\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
cat("Output file:", output_file, "\n\n")

cat("SUMMARY:\n")
cat("  Patterns documented:", length(pattern_info), "\n")
cat("  Total hospitals:", length(config$hospitals), "\n\n")

cat("Pattern breakdown:\n")
for (pattern in pattern_names) {
  count <- length(pattern_info[[pattern]]$hospitals)
  cat(sprintf("  %-30s: %2d hospitals\n", pattern, count))
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("NEXT STEPS:\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
cat("1. Open:", output_file, "\n")
cat("2. View in web browser\n")
cat("3. Save as PDF or open in Word\n")
cat("4. Print in landscape mode\n\n")

cat("The guide now reflects the ACTUAL structure items used in your\n")
cat("enhanced_hospitals.yaml file, with real hospital examples.\n\n")