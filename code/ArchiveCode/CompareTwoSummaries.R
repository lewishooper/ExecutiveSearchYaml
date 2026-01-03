# compare  two different summaries from test_all_configured_hospitals.R
# over two different runs (days, etc)
rm(list=ls())
source<-"E:/ExecutiveSearchYaml/output"
OlderVersion<-"all_hospitals_20251028_105948.csv"
NewVersion<-  "all_hospitals_20251030_183600.csv"

NewDF<-read.csv(file.path(source,NewVersion)) %>%
  select(-c(date_gathered,error_message))

OldDF<-read.csv(file.path(source,OlderVersion)) %>%
  select(-c(date_gathered,error_message))
diff<-anti_join(NewDF,OldDF)                
