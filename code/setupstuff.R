setwd("E:/ExecutiveSearchYaml/code/")
source("pattern_based_scraper.R")
 #source("session_startup.R")
FAC<-676

quick_test(FAC)
Name <- "hanover and district"
url <- "https://www.hanoverhospital.on.ca/our-team"
quick_test(FAC)
helper$analyze_hospital_structure(FAC, Name, url)

helper$test_hospital_config(FAC, Name, url, "div_classes")# - Test configuration (reads from YAML)\n")  
helper$show_pattern_guide()# - Show pattern identification guide\n")
helper$generate_batch_config('file.csv')# - Generate config from CSV\n\n")

helper$analyze_hospital_structure(967, "Cornwall", "https://www.cornwallhospital.ca/en/SeniorAdmin")

source("pattern_based_scraper.R")
quick_test(665)  # Test existing hospital still works
quick_test(967)  
helper$test_hospital_config(648, "DUNNVILLE", "https://www.hwmh.ca/about-us/senior-team/", "div_classes")
helper$test_hospital_config(648, "DUNNVILLE", "https://www.hwmh.ca/about-us/senior-team/", "h2_name_p_title")
time 