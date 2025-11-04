# Test the Sr. pattern we added
test_names <- c(
  "Sr. Sarah Quackenbush",
  "Sr. Bonnie Chesser", 
  "Sr. Frances Carter",
  "Tony Niro",
  "Stephanie Lefebvre",
  "Andre Thibert",
  "Suzanne Lemieux"
)

# Load config patterns
config <- yaml::read_yaml("enhanced_hospitals.yaml")

# Check if Sr. patterns are there
cat("Checking for Sr. patterns in with_titles:\n")
sr_patterns <- grep("^Sr", config$name_patterns$with_titles, value=TRUE)
if(length(sr_patterns) > 0) {
  cat("Found Sr. patterns:\n")
  print(sr_patterns)
} else {
  cat("NO Sr. patterns found!\n")
}

# Test each name against all patterns
all_patterns <- unlist(config$name_patterns)
cat("\n\nTesting names:\n")
for(name in test_names) {
  matches <- sapply(all_patterns, function(p) grepl(p, name))
  cat(name, ": ", sum(matches), " patterns match\n", sep="")
}