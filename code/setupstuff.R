#rm(list=ls())
setwd("E:/ExecutiveSearchYaml/code/")
source("pattern_based_scraper.R")
#source("test_all_configured_hospitals.R")
FAC<-968


#quick_test(FAC)
Name <- "Elliot Lake "
url <- "https://sjghel.ca/about/governance-board/"
quick_test(FAC)
helper$analyze_hospital_structure(FAC, Name, url)

dhelper$test_hospital_config(FAC, Name, url, "table_rows")# - Test configuration (reads from YAML)\n")  
helper$show_pattern_guide()# - Show pattern identification guide\n")
helper$generate_batch_config('file.csv')# - Generate config from CSV\n\n")

helper$analyze_hospital_structure(FAC, Name,url)

source("pattern_based_scraper.R")
quick_test(665)  # Test existing hospital still works
quick_test(967)  
helper$test_hospital_config(648, "DUNNVILLE", "https://www.hwmh.ca/about-us/senior-team/", "div_classes")
helper$test_hospital_config(648, "DUNNVILLE", "https://www.hwmh.ca/about-us/senior-team/", "h2_name_p_title")
time 