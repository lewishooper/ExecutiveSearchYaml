
setwd("E:/ExecutiveSearchYaml/code/")
source("session_startup.R") 
# stop and review


# Compare both YAML files (comprehensive)
source("compare_yaml_status.R")

# Full project status
source("project_status.R")

# Next batch specific status
source("test_next_batch.R")
status_next()
quick_test(726)
FAC<-726
Name<-"tesst"
url<-"https://gbgh.on.ca/about-us/senior-leadership-team/"
helper$analyze_hospital_structure(FAC, "Name",url)
helper$test_hospital_config(FAC, 'Hospital Name', 'URL', 'pattern')

helper$analyze_hospital_structure(
  701, 
  "RICHMOND HILL MACKENZIE HEALTH", 
  "https://www.mackenziehealth.ca/about-us/executive-leadership-team"
)
