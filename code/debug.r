# Find the broken pattern
for(i in 1:length(name_patterns)) {
  if(!is.null(name_patterns[[i]]) && !is.na(name_patterns[[i]])) {
    result <- tryCatch({
      grepl(name_patterns[[i]], test_name)
      "OK"
    }, error = function(e) {
      paste("ERROR:", e$message)
    })
    
    if(result != "OK") {
      cat("Pattern", i, "BROKEN:", name_patterns[[i]], "\n")
      cat("  Error:", result, "\n\n")
    }
  }
}


config <- yaml::read_yaml("enhanced_hospitals.yaml")
