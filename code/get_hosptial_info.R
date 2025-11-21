library(yaml)
fac<-999
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
        FAC=hospital$FAC,
        pattern = hospital$pattern,
        type= hospital$hospital_type
      ))
    }
  }
  
  # Not found
  #return(NULL)
}
test<-as.data.frame(get_hospital_info(592))
