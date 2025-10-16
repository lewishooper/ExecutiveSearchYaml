
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
quick_test(932)
FAC <- 804
Name <- "Norfolk General"
url <- "https://www.ngh.on.ca/senior-leadership-team/"
helper$analyze_hospital_structure(FAC, Name, url)
