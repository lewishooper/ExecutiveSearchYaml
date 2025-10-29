# Review of Patterns
source<-"E:/ExecutiveSearchYaml/code"
library(tidyr)
library(tidyVerse)


#
pattern_summary<-readRDS("E:/ExecutiveSearchYaml/code/pattern_summary.rds")

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
  mutate(FACName=paste0(FAC,"->",Name))%>%
  select(-c(FAC,Name)) %>%
  group_by(pattern) %>%
  mutate(NumByPattern=n())%>%
  summarise(across(everything(), ~ paste(unique(na.omit(.)), collapse = " : "))) %>%
  ungroup() %>%
  mutate(NumByPattern=as.integer(NumByPattern))%>%
  relocate(NumByPattern)

# View the result
print(consolidated_df, n = 14)  # Show all 14 rows