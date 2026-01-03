# get_next_batch_simple.R - Simple script to identify next hospitals to configure
# Save this in E:/ExecutiveSearchYaml/code/

library(readxl)
library(dplyr)
library(yaml)

# Configuration
master_list_file <- "E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx"
config_file <- "enhanced_hospitals.yaml"
batch_size <- 30

cat("=== IDENTIFYING NEXT BATCH OF HOSPITALS ===\n\n")

# Read master hospital list
cat("Reading master list...\n")
master_list <- read_excel(master_list_file)
cat("  Found", nrow(master_list), "total hospitals\n\n")

# Read current configuration
cat("Reading current configuration...\n")
config <- yaml::read_yaml(config_file)

# Get list of already configured FAC numbers
configured_facs <- sapply(config$hospitals, function(h) h$FAC)
cat("  Found", length(configured_facs), "configured hospitals\n\n")

# Identify FAC column in master list
# Try common column names
fac_col <- NULL
possible_fac_names <- c("FAC", "fac", "FAC_Number", "FacilityID", "ID", "Hospital_ID")

for (col_name in possible_fac_names) {
  if (col_name %in% names(master_list)) {
    fac_col <- col_name
    cat("Found FAC column:", col_name, "\n")
    break
  }
}

if (is.null(fac_col)) {
  cat("ERROR: Could not find FAC column in master list\n")
  cat("Available columns:", paste(names(master_list), collapse = ", "), "\n")
  stop("Please specify FAC column name manually")
}

# Identify name column
name_col <- NULL
possible_name_cols <- c("Hospital_Name", "Name", "hospital_name", "Hospital", "HospitalName", "Facility_Name")

for (col_name in possible_name_cols) {
  if (col_name %in% names(master_list)) {
    name_col <- col_name
    cat("Found Name column:", col_name, "\n")
    break
  }
}

if (is.null(name_col)) {
  cat("ERROR: Could not find Name column in master list\n")
  cat("Available columns:", paste(names(master_list), collapse = ", "), "\n")
  stop("Please specify Name column manually")
}

# Identify URL column (optional)
url_col <- NULL
possible_url_cols <- c("URL", "url", "Website", "Link", "Leadership_URL", "LeadershipURL")

for (col_name in possible_url_cols) {
  if (col_name %in% names(master_list)) {
    url_col <- col_name
    cat("Found URL column:", col_name, "\n")
    break
  }
}

cat("\n")

# Format FAC numbers consistently
master_list$FAC_formatted <- sprintf("%03d", as.numeric(master_list[[fac_col]]))

# Find unconfigured hospitals
unconfigured <- master_list %>%
  filter(!FAC_formatted %in% configured_facs) %>%
  arrange(FAC_formatted)

cat("=== SUMMARY ===\n")
cat("Total hospitals:", nrow(master_list), "\n")
cat("Configured:", length(configured_facs), "\n")
cat("Remaining:", nrow(unconfigured), "\n\n")

# Get next batch
if (nrow(unconfigured) == 0) {
  cat("🎉 All hospitals are configured!\n")
} else {
  next_batch <- unconfigured %>%
    head(batch_size) %>%
    select(FAC = FAC_formatted, 
           Name = all_of(name_col),
           if (exists("url_col") && !is.null(url_col)) all_of(url_col) else NULL)
  
  cat("=== NEXT", min(batch_size, nrow(unconfigured)), "HOSPITALS TO CONFIGURE ===\n\n")
  
  for (i in 1:nrow(next_batch)) {
    cat(sprintf("%-4s FAC-%s: %s\n", 
                paste0("[", i, "]"),
                next_batch$FAC[i], 
                next_batch$Name[i]))
    
    if (!is.null(url_col) && url_col %in% names(next_batch)) {
      url_value <- next_batch[[url_col]][i]
      if (!is.na(url_value) && nchar(url_value) > 0) {
        cat("     URL:", url_value, "\n")
      }
    }
    cat("\n")
  }
  
  # Save to CSV for reference
  output_file <- "E:/ExecutiveSearchYaml/next_batch.csv"
  write.csv(next_batch, output_file, row.names = FALSE)
  cat("Next batch saved to:", output_file, "\n\n")
  
  cat("TO START WORKING ON THESE:\n")
  cat("1. Use helper$analyze_hospital_structure(FAC, 'Name', 'URL')\n")
  cat("2. Add configuration to enhanced_hospitals.yaml\n")
  cat("3. Test with quick_test(FAC)\n\n")
}