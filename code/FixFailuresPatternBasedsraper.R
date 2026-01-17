library(dplyr)

# Load scraper
source("E:/ExecutiveSearchYaml/code/pattern_based_scraper.R")
scraper <- PatternBasedScraper()
config <- scraper$load_config("code/enhanced_hospitals.yaml")

# Find WRHN hospitals in config
wrhn_699 <- config$hospitals[[which(sapply(config$hospitals, function(h) h$FAC == 699))]]
wrhn_930 <- config$hospitals[[which(sapply(config$hospitals, function(h) h$FAC == 930))]]

# Scrape both WRHN hospitals
Result699_raw <- scraper$scrape_hospital(wrhn_699)
Result930_raw <- scraper$scrape_hospital(wrhn_930)

# Standardize WRHN data to match API format
standardize_pattern_data <- function(df, hospital_info) {
  df %>%
    mutate(
      # Ensure FAC is 3-digit string with leading zeros
      FAC = sprintf("%03d", as.numeric(FAC)),
      
      # Add missing columns to match API format
      hospital_type = ifelse(!is.null(hospital_info$hospital_type), 
                             hospital_info$hospital_type, NA),
      source_url = hospital_info$url,
      pattern_used = hospital_info$pattern,
      data_status = "pattern_based_scraper"  # Distinguish from API data
    ) %>%
    # Reorder columns to match API format
    select(FAC, hospital_name, hospital_type, executive_name, executive_title,
           date_gathered, source_url, pattern_used, data_status, 
           robots_status, robots_message)
}

# Apply standardization
Result699 <- standardize_pattern_data(Result699_raw, wrhn_699)
Result930 <- standardize_pattern_data(Result930_raw, wrhn_930)

# Load Pembroke API data
# Load Pembroke API data
Result763 <- read.csv("E:/ExecutiveSearchYaml/output/temp/pembroke_recovery_2026-01-01.csv",
                      stringsAsFactors = FALSE)

# FIX: Convert date_gathered to Date object
Result763$date_gathered <- as.Date(Result763$date_gathered)

# Ensure Pembroke FAC is also 3-digit format
Result763 <- Result763 %>%
  mutate(FAC = sprintf("%03d", as.numeric(FAC)))

# Now combine - should work without error
FinalJanFix <- bind_rows(Result699, Result930, Result763)

# Verify the combination
cat("\n=== RECOVERY DATA SUMMARY ===\n")
cat(sprintf("Total records: %d\n", nrow(FinalJanFix)))
cat(sprintf("FAC 699 (WRHN St Mary's): %d executives\n", 
            sum(FinalJanFix$FAC == "699")))
cat(sprintf("FAC 930 (WRHN Grand River): %d executives\n", 
            sum(FinalJanFix$FAC == "930")))
cat(sprintf("FAC 763 (Pembroke): %d executives\n", 
            sum(FinalJanFix$FAC == "763")))

# Check column consistency
cat("\nColumns in final dataset:\n")
print(names(FinalJanFix))

# Save combined recovery file
write.csv(FinalJanFix,
          "E:/ExecutiveSearchYaml/output/temp/recovery_2026-01-01.csv",
          row.names = FALSE)

cat("\n✓ Combined recovery file saved!\n")
cat("Location: E:/ExecutiveSearchYaml/output/temp/recovery_2026-01-01.csv\n\n")

# Display sample
cat("Sample of combined data:\n")
print(FinalJanFix %>% 
        select(FAC, hospital_name, executive_name, executive_title, data_status) %>%
        head(10))

