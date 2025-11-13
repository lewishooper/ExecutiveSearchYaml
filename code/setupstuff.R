#rm(list=ls())
setwd("E:/ExecutiveSearchYaml/code/")
config <- yaml::read_yaml("enhanced_hospitals.yaml")
source("pattern_based_scraper.R")
source("get_hosptial_info.R")
source("test_all_configured_hospitals.R")
FAC<-753
#test<-get_hospital_info(FAC)$name

#quick_test(FAC)
quick_test(FAC)
helper$analyze_hospital_structure(FAC, get_hospital_info(FAC)$name, get_hospital_info(FAC)$url)

dhelper$test_hospital_config(FAC, Name, url, "table_rows")# - Test configuration (reads from YAML)\n")  
helper$show_pattern_guide()# - Show pattern identification guide\n")
helper$generate_batch_config('file.csv')# - Generate config from CSV\n\n")
quick_test_batch(c(753,592,968,955,950))
