# Load both baseline files
#rm(list=ls())
#setwd("E:/ExecutiveSearchYaml/code")

#source(pattern_based_scraper.r)
baseline_nov6 <- read.csv("E:/ExecutiveSearchYaml/output/BaseLineNov62025.csv")
baseline_nov9 <- read.csv("E:/ExecutiveSearchYaml/output/BaseLineNov92025.csv")

# Load hospital config to get pattern info
library(yaml)
config <- read_yaml("E:/ExecutiveSearchYaml/code2/enhanced_hospitals.yaml")

# Create lookup: FAC -> Pattern
fac_to_pattern <- sapply(config$hospitals, function(h) {
  c(FAC = h$FAC, pattern = h$pattern)
})
fac_to_pattern <- as.data.frame(t(fac_to_pattern))

# Analyze failures by pattern
nov6_by_fac <- table(baseline_nov6$FAC)
nov9_by_fac <- table(baseline_nov9$FAC)

all_facs <- unique(c(names(nov6_by_fac), names(nov9_by_fac)))

failure_analysis <- data.frame(
  FAC = all_facs,
  nov6_count = nov6_by_fac[all_facs],
  nov9_count = nov9_by_fac[all_facs],
  stringsAsFactors = FALSE
)

#failure_analysis$nov6_count[is.na(failure_analysis$nov6_count)] <- 0
#failure_analysis$nov9_count[is.na(failure_analysis$nov9_count)] <- 0
#failure_analysis$lost_execs <- failure_analysis$nov6_count - failure_analysis$nov9_count

# Add pattern info
failure_analysis <- merge(failure_analysis, fac_to_pattern, by = "FAC", all.x = TRUE) %>%
  rename(nov6_count=3) %>%
  rename(nov9_count=5) %>%
  mutate(lost_execs=nov6_count-nov9_count)

# Summarize by pattern
pattern_summary <- aggregate(
  cbind(nov6_count, nov9_count, lost_execs) ~ pattern, 
  data = failure_analysis, 
  FUN = sum
)
pattern_summary$failure_rate <- round(100 * pattern_summary$lost_execs / pattern_summary$nov6_count, 1)
pattern_summary <- pattern_summary[order(-pattern_summary$lost_execs), ]

cat("\n=== PATTERN FAILURE SUMMARY ===\n")
print(pattern_summary)

# Save detailed analysis
write.csv(failure_analysis, "E:/ExecutiveSearchYaml/output/failure_analysis_by_hospital.csv", row.names = FALSE)
write.csv(pattern_summary, "E:/ExecutiveSearchYaml/output/pattern_failure_summary.csv", row.names = FALSE)

cat("\n\nFiles saved:\n")
cat("  - failure_analysis_by_hospital.csv (detailed by FAC)\n")
cat("  - pattern_failure_summary.csv (summary by pattern)\n")

