# FindOKHospitals
setwd("E:/ExecutiveSearchYaml/code")

source("test_all_configured_hospitals.R")
AllHospitals<-check_configuration_status()
saveRDS(AllHospitals,"pattern_summary.rds")
OKpatterns<-AllHospitals %>%
  filter(tolower(Status)=='ok') %>%
  filter(!Has_Missing)
saveRDS(OKpatterns,"GoodHospitals.rds")
