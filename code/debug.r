# Find people who appear at multiple hospitals (expected for partnerships)
employee_multi <- employees %>%
  group_by(person_name) %>%
  filter(n() > 1) %>%
  arrange(person_name, hospital_name)

cat("Employees appearing at multiple hospitals:", nrow(employee_multi), "\n")
if(nrow(employee_multi) > 0) {
  print(employee_multi[, c("person_name", "hospital_name", "title")])
}