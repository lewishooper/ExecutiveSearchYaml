# hospital_audit_tool.R - Audit and track hospital processing
# Save this in E:/ExecutiveSearchYaml/code/
rm(list=ls())
library(dplyr)
library(yaml)

HospitalAuditTool <- function() {
  master_list_file<-"E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx"
  # Audit current progress against master hospital list
  audit_hospital_progress <- function(master_list_file, config_file = "enhanced_hospitals.yaml", 
                                      output_folder = "E:/ExecutiveSearchYaml/output") {
    
    cat("=== HOSPITAL PROGRESS AUDIT ===\n\n")
    
    # Read master hospital list
    if (grepl("\\.xlsx?$", master_list_file)) {
      master_list <- readxl::read_excel(master_list_file)
    } else if (grepl("\\.csv$", master_list_file)) {
      master_list <- read.csv(master_list_file, stringsAsFactors = FALSE)
    } else {
      cat("ERROR: Master list must be .xlsx, .xls, or .csv file\n")
      return(NULL)
    }
    
    cat("Master list loaded:", nrow(master_list), "hospitals\n")
    
    # Read current configuration
    configured_hospitals <- data.frame()
    if (file.exists(config_file)) {
      config <- yaml::read_yaml(config_file)
      if (!is.null(config$hospitals)) {
        configured_hospitals <- data.frame(
          FAC = sapply(config$hospitals, function(x) x$FAC),
          name = sapply(config$hospitals, function(x) x$name),
          status = sapply(config$hospitals, function(x) x$status %||% "unknown"),
          pattern = sapply(config$hospitals, function(x) x$pattern),
          stringsAsFactors = FALSE
        )
      }
    }
    
    cat("Configured hospitals:", nrow(configured_hospitals), "\n")
    
    # Read scraped results
    scraped_hospitals <- data.frame()
    result_files <- list.files(output_folder, pattern = "hospital_executives_.*\\.csv$", full.names = TRUE)
    
    if (length(result_files) > 0) {
      # Use most recent results file
      latest_file <- result_files[which.max(file.mtime(result_files))]
      scraped_results <- read.csv(latest_file, stringsAsFactors = FALSE)
      
      scraped_hospitals <- scraped_results %>%
        group_by(FAC, hospital_name) %>%
        summarise(
          executives_found = sum(!is.na(executive_name)),
          last_scraped = max(date_gathered, na.rm = TRUE),
          .groups = "drop"
        )
      
      cat("Scraped hospitals (latest results):", nrow(scraped_hospitals), "\n")
      cat("Latest results file:", basename(latest_file), "\n")
    } else {
      cat("No scraped results found in output folder\n")
    }
    
    # Identify FAC column in master list
    fac_col <- NULL
    name_col <- NULL
    
    fac_possibilities <- c("FAC", "fac", "FAC_Number", "ID", "Hospital_ID", "HospitalID")
    for (col in fac_possibilities) {
      if (col %in% names(master_list)) {
        fac_col <- col
        break
      }
    }
    
    name_possibilities <- c("Hospital_Name", "Name", "hospital_name", "Hospital", "HospitalName")
    for (col in name_possibilities) {
      if (col %in% names(master_list)) {
        name_col <- col
        break
      }
    }
    
    if (is.null(fac_col)) {
      cat("ERROR: Could not find FAC column in master list\n")
      return(NULL)
    }
    
    # Create audit report
    master_list$FAC_formatted <- sprintf("%03d", as.numeric(master_list[[fac_col]]))
    
    audit_report <- master_list %>%
      select(FAC_formatted, all_of(name_col)) %>%
      rename(FAC = FAC_formatted, master_name = all_of(name_col)) %>%
      left_join(configured_hospitals, by = "FAC", suffix = c("_master", "_config")) %>%
      left_join(scraped_hospitals, by = "FAC") %>%
      mutate(
        is_configured = !is.na(name),
        is_scraped = !is.na(executives_found),
        needs_attention = case_when(
          !is_configured ~ "Not configured",
          is.na(executives_found) ~ "Configured but not scraped",
          executives_found == 0 ~ "Scraped but no results",
          TRUE ~ "Complete"
        )
      ) %>%
      arrange(FAC)
    
    # Summary statistics
    cat("\n=== AUDIT SUMMARY ===\n")
    total_hospitals <- nrow(audit_report)
    configured_count <- sum(audit_report$is_configured, na.rm = TRUE)
    scraped_count <- sum(audit_report$is_scraped, na.rm = TRUE)
    successful_count <- sum(audit_report$executives_found > 0, na.rm = TRUE)
    
    cat("Total hospitals in master list:", total_hospitals, "\n")
    cat("Configured hospitals:", configured_count, "/", total_hospitals, 
        "(", round(configured_count/total_hospitals*100, 1), "%)\n")
    cat("Scraped hospitals:", scraped_count, "/", total_hospitals,
        "(", round(scraped_count/total_hospitals*100, 1), "%)\n") 
    cat("Successful scrapes:", successful_count, "/", total_hospitals,
        "(", round(successful_count/total_hospitals*100, 1), "%)\n\n")
    
    return(audit_report)
  }
  
  # Get next batch of hospitals to work on
  get_next_batch <- function(master_list_file, batch_size = 10) {
    audit_report <- audit_hospital_progress(master_list_file)
    
    next_batch <- audit_report %>%
      filter(needs_attention == "Not configured") %>%
      head(batch_size)
    
    if (nrow(next_batch) > 0) {
      cat("=== NEXT BATCH OF", batch_size, "HOSPITALS ===\n")
      
      for (i in 1:nrow(next_batch)) {
        cat("FAC-", next_batch$FAC[i], ": ", next_batch$master_name[i], "\n")
      }
      
      return(next_batch)
    } else {
      cat("All hospitals are configured!\n")
      return(data.frame())
    }
  }
  
  return(list(
    audit_hospital_progress = audit_hospital_progress,
    get_next_batch = get_next_batch
  ))
}

# Initialize audit tool
auditor <- HospitalAuditTool()

cat("=== HOSPITAL AUDIT TOOL LOADED ===\n")
cat("USAGE:\n")
cat("auditor$audit_hospital_progress('master_list.xlsx')\n")
cat("auditor$get_next_batch('master_list.xlsx', 10)\n")

next_batch <- auditor$get_next_batch("E:/Public/ResourceFiles/LeadershipURLYAMLNotes.xlsx", batch_size = 30)
