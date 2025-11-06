BaseLineReview<-GoodHospitals %>%
  group_by(Status) %>%
  mutate(statusNumbers=n()) %>%
  select(Status,statusNumbers) %>%
  unique()
NumHospitals<-GoodHospitals %>%
  group_by(FAC) %>%
  mutate(DupsCheck=n())

test_all_configured_hospitals()