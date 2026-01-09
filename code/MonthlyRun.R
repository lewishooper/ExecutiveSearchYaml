project_root <- "E:/ExecutiveSearchYaml"
if (getwd() != project_root) {
  setwd(project_root)
}

# Run the full monthly collection
source("code/monthly_executive_collection.R")