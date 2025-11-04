# PatternSummary.R - FIXED VERSION
# takes data from test configuration  and enhanced_hospitals.yaml 
# and creates a csv Excel summary  of the paterns for transfer to word, 
# this creates the QuickReference guide to patterns

library(yaml)
library(dplyr)
library(tibble)
setwd("E:/ExecutiveSearchYaml/code")
Working<-"E:/ExecutiveSearchYaml/code"
#rm(list=ls())
setwd("E:/ExecutiveSearchYaml/code")

source("test_all_configured_hospitals.R")
AllHospitals<-check_configuration_status()
saveRDS(AllHospitals,"pattern_summary.rds")
OKpatterns<-AllHospitals %>%
  filter(tolower(Status) %in% c('ok', 'ok-mp'))
saveRDS(OKpatterns,"GoodHospitals.rds")




cat("\n=== Starting Pattern Summary Creation ===\n\n")

# Load the good hospitals list
good_hospitals <- readRDS("GoodHospitals.rds")
cat("Loaded", nrow(good_hospitals), "successfully configured hospitals\n")

# Load the YAML configuration
yaml_data <- yaml::read_yaml("enhanced_hospitals.yaml")
hospitals_yaml <- yaml_data$hospitals

# Recursive function to remove all 'notes' fields
remove_notes <- function(obj) {
  if (is.list(obj)) {
    # Remove the 'notes' element if it exists
    obj$notes <- NULL
    
    # Recursively apply to all remaining elements
    obj <- lapply(obj, remove_notes)
  }
  return(obj)
}
remove_missing <- function(obj) {
  if (is.list(obj)) {
    # Remove the 'missing people' element if it exists
    obj$html_structure$missing_people <- NULL
    
    # Recursively apply to all remaining elements
    obj <- lapply(obj, remove_missing)
  }
  return(obj)
}
# Apply the function to strip out all notes
hospitals_yaml <- remove_notes(hospitals_yaml)
hospitals_yaml<-remove_missing(hospitals_yaml)
cat("Loaded", length(hospitals_yaml), "hospitals from YAML\n\n")

# Initialize list to store results
results_list <- list()
matched_count <- 0
not_found_count <- 0
i<-1
j<-1
# Process each hospital in the good_hospitals list
for(i in 1:nrow(good_hospitals)) {
  fac_num <- as.character(good_hospitals$FAC[i])
  fac_num <- trimws(fac_num)

  # Find matching hospital in YAML
  yaml_hospital <- NULL
  for(j in 1:length(hospitals_yaml)) {
    h <- hospitals_yaml[[j]]
    if(!is.null(h$FAC)) {
      yaml_fac <- trimws(as.character(h$FAC))
      
      if(yaml_fac == fac_num) {
        yaml_hospital <- h
        matched_count <- matched_count + 1
        break
      }
    }
  }
  
  if(is.null(yaml_hospital)) {
    cat("Warning: FAC", fac_num, "not found in YAML\n")
    not_found_count <- not_found_count + 1
    next
  }
  
  # Extract basic info
  row_data <- list(
    FAC = fac_num,
    Name = yaml_hospital$name %||% NA_character_,
    Hospital_type = good_hospitals$Hospital_type[i],
    pattern = yaml_hospital$pattern %||% NA_character_
  )
  
  # Extract html_structure items
  if(!is.null(yaml_hospital$html_structure)) {
    struct <- yaml_hospital$html_structure
    struct_names <- names(struct)
    
    # Add up to 4 HTML structure items
    for(k in 1:4) {
      if(k <= length(struct_names)) {
        item_name <- struct_names[k]
        item_value <- struct[[item_name]]
        
        # CRITICAL FIX: Handle NULL values properly
        if(is.null(item_value)) {
          item_value_str <- NA_character_
        } else if(is.list(item_value) || length(item_value) > 1) {
          item_value_str <- paste(item_value, collapse = ", ")
        } else if(length(item_value) == 0) {
          # Handle character(0) or empty vectors
          item_value_str <- NA_character_
        } else {
          item_value_str <- as.character(item_value)
        }
        
        row_data[[paste0("HTMLItem", k)]] <- as.character(item_name)
        row_data[[paste0("HTMLItemElement", k)]] <- item_value_str
      } else {
        row_data[[paste0("HTMLItem", k)]] <- NA_character_
        row_data[[paste0("HTMLItemElement", k)]] <- NA_character_
      }
    }
  } else {
    # No html_structure, set all to NA_character_
    for(k in 1:4) {
      row_data[[paste0("HTMLItem", k)]] <- NA_character_
      row_data[[paste0("HTMLItemElement", k)]] <- NA_character_
    }
  }
  
  results_list[[length(results_list) + 1]] <- row_data
}

cat("\n=== Matching Summary ===\n")
cat("Matched:", matched_count, "\n")
cat("Not found:", not_found_count, "\n")
cat("results_list length:", length(results_list), "\n\n")

# Convert list to dataframe
if(length(results_list) > 0) {
  pattern_summary <- bind_rows(results_list)
  
  cat("=== Pattern Summary Created ===\n")
  cat("Total hospitals:", nrow(pattern_summary), "\n")
  cat("Patterns represented:\n")
  print(table(pattern_summary$pattern))
  
  cat("\nFirst few rows:\n")
  print(head(pattern_summary, 3))
  
  saveRDS(pattern_summary, "pattern_summary.rds")
  write.csv(pattern_summary, "pattern_summary.csv", row.names = FALSE)
  
  cat("\nSaved to:\n")
  cat("  - pattern_summary.rds\n")
  cat("  - pattern_summary.csv\n")
} else {
  cat("ERROR: No hospitals matched!\n")
  pattern_summary <- NULL
}

pattern_summary
writexl::write_xlsx(pattern_summary,"PatternSummary.xlsx")



PatternsInSummary<-pattern_summary %>%
  select(pattern) %>%
  group_by(pattern) %>%
  mutate(Count=n()) %>%
  unique()
ConsolidatedPatterns<-pattern_summary %>%
  select(-c("Name","FAC")) %>%
  group_by(pattern) %>%
  mutate(NumPatterns=n()) %>%
  relocate(NumPatterns) %>%
  arrange(desc("NumPatterns")) %>%
  unique()
library(dplyr)

# Create the consolidated dataframe
consolidated_df <- pattern_summary %>%
  #mutate(FACName=paste0(FAC))%>%
  select(-c(Name)) %>%
  group_by(pattern) %>%
  mutate(NumByPattern=n())%>%
  summarise(across(everything(), ~ paste(unique(na.omit(.)), collapse = " ** "))) %>%
  ungroup() %>%
  mutate(NumByPattern=as.integer(NumByPattern))%>%
  relocate(NumByPattern)

# View the result
print(consolidated_df, n = 14)  # Show all 14 rows
consolidated_df <-consolidated_df%>%
  rename(
  Item1 = HTMLItem1 ,                      ,
  Element1 = HTMLItemElement1,
  Item2=HTMLItem2,
  Item3=HTMLItem3,
  Item4=HTMLItem4,
  Element2=HTMLItemElement2, 
  Element3=HTMLItemElement3,
  Element4=HTMLItemElement4) 
consolidated_df  <-consolidated_df%>%
  mutate(FAC=str_replace_all(FAC,"\\*\\*"," ")) %>%
  relocate( FAC, .after = last_col()) %>%
  arrange(desc(NumByPattern))

saveRDS(consolidated_df,"Pattern_summary_final.rds")
writexl::write_xlsx(consolidated_df,"PatternSummary_final.csv")
write.csv(consolidated_df,"PSF.csv")
