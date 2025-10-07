# packages you may need:
# install.packages(c("readxl", "dplyr", "stringr", "yaml", "janitor", "purrr"))

library(readxl)
library(dplyr)
library(stringr)
library(yaml)
library(janitor)
library(purrr)

# >>> EDIT THESE PATHS <<<
input_excel <- "E:/Public/ResourceFiles/FACTypeURLLeads.xlsx"     # your Excel file path
sheet_name  <- 1                    # or the sheet name, e.g. "Sheet1"
output_yaml <- "E:/ClaudeExecScraper/code/batch_test_hospitals.yaml"

# 1) Read & normalize columns
raw <- read_excel(input_excel, sheet = sheet_name) %>%
  clean_names()  # makes names like hospital, fac, url (lower snake_case)

# Expecting columns: hospital, fac, url
#stopifnot(all(c("hospital", "fac", "url") %in% names(raw)))

# 2) Basic cleaning & padding FAC to keep leading zeros (3 digits typical; adjust if needed)
df <- raw %>%
  mutate(
    hospital = str_squish(as.character(hospital)),
    fac      = str_pad(as.character(fac), width = 3, side = "left", pad = "0"),
    url      = str_squish(as.character(leadership_url))
  ) %>%
  filter(!is.na(hospital), !is.na(fac), !is.na(url), hospital != "", fac != "", url != "")

# 3) Build the list for YAML
#    location / expected_executives / structure_notes are left as placeholders to edit later
hosp_list <- pmap(
  df,
  function(hospital, fac, url, ...) {
    list(
      FAC               = fac,                # we will force quotes later
      name              = hospital,
      url               = url,
      system            = hospital,           # as requested: same as hospital name
      location          = NA,                 # placeholder; edit later e.g., "City, Province"
      expected_executives = NA,               # placeholder; edit later with a number
      structure_notes   = ""                  # placeholder; edit later e.g., "h2 names, h3 titles"
    )
  }
)

yaml_body <- as.yaml(
  list(hospitals = hosp_list),
  indent = 2,
  line.sep = "\n"
)

# 4) Force FAC values to be quoted (so "001" stays as a string in YAML)
#    This post-processing step finds lines like "- FAC: 001" and turns into '- FAC: "001"'
yaml_body <- gsub('(^\\s*-\\s*FAC:\\s*)(\\d+)(\\s*$)', '\\1"\\2"\\3', yaml_body, perl = TRUE)

# 5) Add header comments and an example template comment block at the top
header_comments <- paste0(
  "# batch_test_hospitals.yaml - List for larger test run\n",
  "# Add your test hospitals here\n\n"
)

template_comment <- paste0(
  "# Template for new hospitals (example):\n",
  "# - FAC: \"002\"\n",
  "#   name: \"Your Second Hospital Name\"\n",
  "#   url: \"https://hospital2.com/leadership\"\n",
  "#   system: \"Health System Name\"\n",
  "#   location: \"City, Province\"\n",
  "#   expected_executives: 8\n",
  "#   structure_notes: \"Add notes about page structure if known\"\n\n"
)

# 6) Write file
final_text <- paste0(header_comments, template_comment, yaml_body)
writeLines(final_text, con = output_yaml)

message("YAML written to: ", normalizePath(output_yaml))
