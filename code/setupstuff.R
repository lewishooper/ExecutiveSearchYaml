
source("test_10_hospitals.R")

setwd("E:/ExecutiveSearchYaml/code/")
source("pattern_based_scraper.R")
source("quick_test_single.R")
# Test all hospitals in your YAML file

quick_test(781)
 
URL<-'https://sjcg.net/aboutus/leadership.aspx'
helper$analyze_hospital_structure(827,"test",URL)

results <- test_all_hospitals_from_yaml()

<div class="boardcard"><img src="https://tbrhsc.net/wp-content/uploads/2025/05/Dr-Adam-Exley-headshot-scaled.jpg" alt="SLC Headshot">Dr. Adam Exley, Vice President, Medical Affairs</div>