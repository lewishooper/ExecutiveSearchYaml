# Validate Phase 2 YAML additions
library(yaml)

cat("=== VALIDATING YAML STRUCTURE ===\n\n")

# Try to load config
tryCatch({
  config <- yaml::read_yaml("enhanced_hospitals.yaml")
  cat("✓ YAML loads successfully\n\n")
  
  # Check for new sections
  if (!is.null(config$recognition_config)) {
    cat("✓ recognition_config section found\n")
    
    # Check title_keywords
    if (!is.null(config$recognition_config$title_keywords)) {
      cat("  ✓ title_keywords found\n")
      cat("    - Primary keywords:", 
          length(config$recognition_config$title_keywords$primary), "\n")
      cat("    - Secondary keywords:", 
          length(config$recognition_config$title_keywords$secondary), "\n")
      cat("    - Medical keywords:", 
          length(config$recognition_config$title_keywords$medical_specific), "\n")
    } else {
      cat("  ✗ title_keywords MISSING\n")
    }
    
    # Check exclusions
    if (!is.null(config$recognition_config$name_exclusions)) {
      cat("  ✓ name_exclusions found:", 
          length(config$recognition_config$name_exclusions), "patterns\n")
    } else {
      cat("  ✗ name_exclusions MISSING\n")
    }
    
    if (!is.null(config$recognition_config$title_exclusions)) {
      cat("  ✓ title_exclusions found:", 
          length(config$recognition_config$title_exclusions), "patterns\n")
    } else {
      cat("  ✗ title_exclusions MISSING\n")
    }
  } else {
    cat("✗ recognition_config section MISSING\n")
  }
  
  # Check hospital_overrides
  if (!is.null(config$hospital_overrides)) {
    cat("\n✓ hospital_overrides section found\n")
    cat("  Overrides configured for", length(config$hospital_overrides), "hospitals\n")
    cat("  Hospitals with overrides:", 
        paste(names(config$hospital_overrides), collapse=", "), "\n")
  } else {
    cat("\n✗ hospital_overrides section MISSING\n")
  }
  
  cat("\n=== VALIDATION COMPLETE ===\n")
  
}, error = function(e) {
  cat("✗ ERROR loading YAML:\n")
  cat(e$message, "\n")
  cat("\nCheck YAML syntax and indentation\n")
})

