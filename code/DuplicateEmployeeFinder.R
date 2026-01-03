#Diagnostic: Check for duplicate names at same hospital in December
dec_all <- bind_rows(
  dec_employees %>% mutate(person_type = "Employee"),
  dec_volunteers %>% mutate(person_type = "Volunteer")
)

duplicates_dec <- dec_all %>%
  group_by(fac_number, person_name) %>%
  filter(n() > 1) %>%
  arrange(fac_number, person_name)

cat(sprintf("\nFound %d duplicate name entries in December data\n", nrow(duplicates_dec)))

if (nrow(duplicates_dec) > 0) {
  View(duplicates_dec)
}

# Check January too
jan_all <- bind_rows(
  jan_employees %>% mutate(person_type = "Employee"),
  jan_volunteers %>% mutate(person_type = "Volunteer")
)

duplicates_jan <- jan_all %>%
  group_by(fac_number, person_name) %>%
  filter(n() > 1) %>%
  arrange(fac_number, person_name)

cat(sprintf("Found %d duplicate name entries in January data\n", nrow(duplicates_jan)))

if (nrow(duplicates_jan) > 0) {
  View(duplicates_jan)
}
