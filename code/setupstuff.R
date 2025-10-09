setwd("E:/ExecutiveSearchYaml/code/")

source("test_10_hospitals.R")
source("pattern_based_scraper.R")
source("quick_test_single.R")
# Test all hospitals in your YAML file
#make sure all programs loaded
# Pattern_based_scraper.r, quick_TEST_SINGLE.R, hospital_configuration_helper.r setupstuff.r and Enhanced_hospitals.yaml
#quick_test(790)
quick_test(777)

WorkingURL<-'https://www.oakvalleyhealth.ca/about-us/meet-our-team/senior-leadership-team/ '
FAC<-
  helper$analyze_hospital_structure(777,"test",URL)
results <- test_all_hospitals_from_yaml()
source("pattern_based_scraper.R")
