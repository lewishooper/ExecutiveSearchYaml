
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
quick_test(916)
FAC<-967
Name <- "Cornwall"
url <- "https://www.cornwallhospital.ca/en/SeniorAdmin"
helper$analyze_hospital_structure(FAC, Name, url)

helper$test_hospital_config(fac, name, url, pattern)# - Test configuration (reads from YAML)\n")  
helper$show_pattern_guide()# - Show pattern identification guide\n")
helper$generate_batch_config('file.csv')# - Generate config from CSV\n\n")


test_all_configured_hospitals()
