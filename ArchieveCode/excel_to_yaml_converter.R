# excel_to_yaml_converter.R - Convert Excel hospital list to YAML template
# Save this in E:/ExecutiveSearchYaml/source/

library(readxl)
library(yaml)
library(dplyr)

ExcelToYamlConverter <- function() {
  
  # Convert Excel file to YAML template
  convert_excel_to_yaml_template <- function(excel_file, output_file = "hospital_template.yaml") {
    
    cat("=== CONVERTING EXCEL TO YAML TEMPLATE ===\n")
    cat("Reading:", excel_file, "\n")
    
    # Read Excel file
    tryCatch({
      # Try to read the Excel file
      hospital_data <- read_excel(excel_file)
      
      cat("Found", nrow(hospital_data), "hospitals in Excel file\n")
      cat("Columns:", paste(names(hospital_data), collapse = ", "), "\n\n")
      
      # Look for FAC and hospital name columns (flexible naming)
      fac_col <- NULL
      name_col <- NULL
      
      # Try different possible column names for FAC
      fac_possibilities <- c("FAC", "fac", "FAC_Number", "ID", "Hospital_ID", "HospitalID")
      for (col in fac_possibilities) {
        if (col %in% names(hospital_data)) {
          fac_col <- col
          break
        }
      }
      
      # Try different possible column names for hospital name
      name_possibilities <- c("Hospital_Name", "Name", "hospital_name", "Hospital", 
                              "HospitalName", "Facility_Name", "Organization")
      for (col in name_possibilities) {
        if (col %in% names(hospital_data)) {
          name_col <- col
          break
        }
      }
      
      if (is.null(fac_col) || is.null(name_col)) {
        cat("ERROR: Could not find FAC and Hospital Name columns\n")
        cat("Available columns:", paste(names(hospital_data), collapse = ", "), "\n")
        cat("Please ensure columns are named: FAC, Hospital_Name (or similar)\n")
        return(NULL)
      }
      
      cat("Using FAC column:", fac_col, "\n")
      cat("Using Name column:", name_col, "\n\n")
      
      # Create YAML template structure
      hospitals_list <- list()
      
      for (i in 1:nrow(hospital_data)) {
        fac_number <- hospital_data[[fac_col]][i]
        hospital_name <- hospital_data[[name_col]][i]
        
        # Skip if missing data
        if (is.na(fac_number) || is.na(hospital_name)) {
          next
        }
        
        # Create hospital entry template
        hospital_entry <- list(
          FAC = sprintf("%03d", as.numeric(fac_number)),
          name = as.character(hospital_name),
          url = "# TODO: Add leadership page URL",
          pattern = "h2_name_h3_title  # TODO: Update after HTML inspection",
          expected_executives = 5, # TODO: Update based on actual count
          html_structure = list(
            name_element = "h2  # TODO: Update after HTML inspection",
            title_element = "h3  # TODO: Update after HTML inspection", 
            notes = "# TODO: Add notes about HTML structure"
          ),
          status = "needs_configuration"
        )
        
        hospitals_list[[i]] <- hospital_entry
      }
      
      # Remove NULL entries
      hospitals_list <- hospitals_list[!sapply(hospitals_list, is.null)]
      
      # Create final YAML structure
      yaml_structure <- list(
        hospitals = hospitals_list,
        template_info = list(
          created_date = Sys.Date(),
          source_file = excel_file,
          total_hospitals = length(hospitals_list),
          status = "template_generated",
          instructions = list(
            "1. Replace all TODO items with actual values",
            "2. Add real leadership page URLs", 
            "3. Inspect HTML structure for each hospital",
            "4. Update patterns based on HTML inspection",
            "5. Test each hospital configuration",
            "6. Remove this template_info section when ready"
          )
        )
      )
      
      # Write YAML file
      yaml::write_yaml(yaml_structure, output_file)
      
      cat("SUCCESS: Created YAML template with", length(hospitals_list), "hospitals\n")
      cat("Template saved to:", output_file, "\n\n")
      
      cat("NEXT STEPS:\n")
      cat("1. Open", output_file, "in text editor\n")
      cat("2. Replace all TODO items with actual information\n")
      cat("3. Use helper$analyze_hospital_structure() for each hospital\n")
      cat("4. Test configurations before final use\n\n")
      
      return(yaml_structure)
      
    }, error = function(e) {
      cat("ERROR reading Excel file:", e$message, "\n")
      cat("Make sure the file exists and is a valid Excel file (.xlsx or .xls)\n")
      return(NULL)
    })
  }
  
  # Create a sample Excel template for hospitals
  create_sample_excel_template <- function(output_file = "hospital_template.xlsx") {
    
    sample_data <- data.frame(
      FAC = c("001", "002", "003", "004", "005"),
      Hospital_Name = c(
        "Example General Hospital",
        "Sample Medical Centre", 
        "Template Regional Hospital",
        "Demo Community Hospital",
        "Test Memorial Hospital"
      ),
      Location = c("City, ON", "Town, ON", "Village, ON", "Municipality, ON", "District, ON"),
      Notes = c("", "", "", "", "")
    )
    
    # Write Excel file
    writexl::write_xlsx(sample_data, output_file)
    
    cat("Created sample Excel template:", output_file, "\n")
    cat("Fill this template with your hospital data, then use convert_excel_to_yaml_template()\n")
  }
  
  return(list(
    convert_excel_to_yaml_template = convert_excel_to_yaml_template,
    create_sample_excel_template = create_sample_excel_template
  ))
}

# Initialize converter
converter <- ExcelToYamlConverter()
converter$convert_excel_to_yaml_template('E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx', 'E:/ExecutiveSearchYaml/source/hospitals_template.yaml')
cat("=== EXCEL TO YAML CONVERTER LOADED ===\n\n")
cat("USAGE:\n")
cat("converter$convert_excel_to_yaml_template('my_hospitals.xlsx', 'hospitals_template.yaml')\n")