# Manual setup steps
#rm(list=ls())
#rm(list=ls())
project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}
source("E:/ExecutiveSearchYaml/code/PreMonthlyRun.R")
# runs self
# output in E:/ExecutiveSearchYaml/temp/hospitals_to_capture.rds

source("E:/ExecutiveSearchYaml/code/pattern_based_scraper.r")
run_pattern_scraping()
# output in E:/ExecutiveSearchYaml/output/hospital_executives_YYYYMMDD.csv



source("E:/ExecutiveSearchYaml/code/step1_screenshot_capture.R")
#runs self
# output in E:/ExecutiveSearchYaml/temp/screenshots/FAC-XXX_YYYYMMDD.png

## Compare screenshots with prior and check for changes.  There are usually several
## check if changes and copy replace faulty Screenshots.

source("E:/ExecutiveSearchYaml/code/step2_api_extraction.R")




#runs Self

#outputE:/ExecutiveSearchYaml/output/api_executives_YYYYMMDD.csv
#### May2 needed adjustments
source("E:/ExecutiveSearchYaml/code/append_raw_data.R")
#runs self
#output  E:/ExecutiveSearchYaml/output/combined_raw_YYYYMMDD.csv

source("E:/ExecutiveSearchYaml/code/process_hospital_data.R")
## NOTE  you wil need to update the file name...
result <- process_hospital_data(
  input_file = "E:/ExecutiveSearchYaml/output/combined_raw_20260601.csv"
)
#Output -->  E:/ExecutiveSearchYaml/processed/HospitalExecutives_Employees_YYYY-MM-DD.csv
# and -->E:/ExecutiveSearchYaml/processed/HospitalExecutives_Volunteers_YYYY-MM-DD.csv

## final step
source("E:/ExecutiveSearchYaml/code/monthly_executive_collection.R")
summary <- summarize_monthly_collection(as.Date("2026-01-15"))
# outputE:/ExecutiveSearchYaml/tracking/monthly_summary_2026-01-15.log
