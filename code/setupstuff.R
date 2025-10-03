
source("test_10_hospitals.R")

setwd("E:/ExecutiveSearchYaml/code/")
source("pattern_based_scraper.R")

# Test all hospitals in your YAML file

quick_test(970)



results <- test_all_hospitals_from_yaml()
helper$analyze_hospital_structure(970,"test","https://www.bchsys.org/en/about-us/senior-leadership-team.aspx")
