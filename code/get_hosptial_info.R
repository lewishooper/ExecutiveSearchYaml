library(yaml)

get_hospital_info <- function(fac) {
  # Format FAC with leading zeros
  fac_formatted <- sprintf("%03d", as.numeric(fac))
  
  # Load YAML
  config <- read_yaml("enhanced_hospitals.yaml")
  
  # Find and return hospital info
  for (hospital in config$hospitals) {
    if (hospital$FAC == fac_formatted) {
      return(list(
        name = hospital$name,
        url = hospital$url,
        pattern = hospital$pattern
      ))
    }
  }
  
  # Not found
  return(NULL)
}
get_hospital_info(753)
