# Check the structure of the problem rows
results_list <- readRDS("pattern_summary_debug.rds")  # Actually we need to save results_list

# Actually, let's check the YAML structure for those 4
library(yaml)
yaml_data <- yaml::read_yaml("enhanced_hospitals.yaml")
hospitals_yaml <- yaml_data$hospitals

problem_facs <- c("686", "662", "611", "814")
problem_positions <- c(2, 12, 26, 44)

cat("Checking html_structure for problem FACs:\n\n")

for(i in 1:length(problem_facs)) {
  fac <- problem_facs[i]
  pos <- problem_positions[i]
  
  cat("FAC", fac, "(YAML position", pos, "):\n")
  h <- hospitals_yaml[[pos]]
  
  cat("  Pattern:", h$pattern, "\n")
  cat("  html_structure present:", !is.null(h$html_structure), "\n")
  
  if(!is.null(h$html_structure)) {
    cat("  html_structure items:\n")
    struct_names <- names(h$html_structure)
    for(sname in struct_names) {
      sval <- h$html_structure[[sname]]
      cat("    ", sname, ": ", class(sval), " - ", 
          if(is.list(sval)) paste(sval, collapse=", ") else as.character(sval), "\n", sep="")
    }
  }
  cat("\n")
}