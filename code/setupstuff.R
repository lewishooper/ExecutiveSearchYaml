
setwd("E:/ExecutiveSearchYaml/code/")

source("test_10_hospitals.R")
source("pattern_based_scraper.R")
source("quick_test_single.R")
# Test all hospitals in your YAML file
#make sure all programs loaded
# Pattern_based_scraper.r, quick_TEST_SINGLE.R, hospital_configuration_helper.r setupstuff.r and Enhanced_hospitals.yaml
quick_test(790)
quick_test(957)
 
URL<-'https://www.thp.ca/aboutus/Pages/Seniorleadership.aspx'
helper$analyze_hospital_structure(975,"test","https://www.hoteldieushaver.org/site/team")

results <- test_all_hospitals_from_yaml()

debug
975, Trillium Health Partners  
URL<-'https://www.thp.ca/aboutus/Pages/Seniorleadership.aspx'
html <h2> 
  <span>Karli Farrow<img width="150" height="210" align="right" alt="Karli Farrow" src="/aboutus/PublishingImages/slt/Karli_Farrow.jpg" style="border-left:10px solid #ffffff;"></span><br><span class="h4"><em>President &amp; CEO</em></span></h2>

  Which pattern should I use 