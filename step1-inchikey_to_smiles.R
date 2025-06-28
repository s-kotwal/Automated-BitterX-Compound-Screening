# Please cite [paper] or this GitHub repo (gitHub.com/s-kotwal/)

# 
# Part one of data curation for bitter compound screening.
# R Script to prepare .csv file for Bitter compound screening using BitterX
# Converts InChIKey to SMILES
# Requires two columns: Compound, InChIKey
# Refer to bitter_screen_example.csv to run example .csv file

# Install required packages if not already installed
if (!requireNamespace("readr", quietly = TRUE)) install.packages("readr")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
devtools::install_github("selcukorkmaz/PubChemR")

library(readr)
library(dplyr)
library(PubChemR)

# === INPUT FILE ===
input_file <- "bitter_screen_example.csv"

# === STEP 1: Filter unique InChIKeys ===
df_original <- read_csv(input_file)

df_unique <- df_original %>%
  filter(!is.na(InChIKey)) %>%
  distinct(InChIKey, .keep_all = TRUE)

# === STEP 2: Retrieve SMILES from PubChem with retry logic ===
inchikey_list <- df_unique$InChIKey

results_df <- data.frame(
  InChIKey = character(), CID = character(),
  CanonicalSMILES = character(), IsomericSMILES = character(),
  Identifier = character(), stringsAsFactors = FALSE
)

max_attempts <- 3

for (key in inchikey_list) {
  if (!is.na(key) && key != "null") {
    attempt <- 1
    success <- FALSE
    while (attempt <= max_attempts && !success) {
      props <- tryCatch({
        get_properties(
          properties = c("CanonicalSMILES", "IsomericSMILES"),
          identifier = key,
          namespace = "inchikey"
        ) %>% retrieve(.combine.all = TRUE)
      }, error = function(e) NULL)
      
      if (!is.null(props) && nrow(props) > 0) {
        props$CID <- as.character(props$CID)
        results_df <- bind_rows(results_df, props)
        success <- TRUE
      } else {
        attempt <- attempt + 1
        if (attempt <= max_attempts) Sys.sleep(1)
      }
    }
    
    if (!success) {
      results_df <- bind_rows(results_df, data.frame(
        InChIKey = key, CID = NA,
        CanonicalSMILES = NA, IsomericSMILES = NA,
        Identifier = key
      ))
    }
  } else {
    results_df <- bind_rows(results_df, data.frame(
      InChIKey = key, CID = NA,
      CanonicalSMILES = NA, IsomericSMILES = NA,
      Identifier = key
    ))
  }
}

# === STEP 3: Clean and Merge with Original ===
# Clean up identifier column
results_df <- results_df %>%
  mutate(InChIKey = ifelse(is.na(InChIKey) | InChIKey == "null", Identifier, InChIKey)) %>%
  select(-Identifier)

# Merge SMILES into the original full dataset
df_supplementary <- df_original %>%
  left_join(results_df, by = "InChIKey") %>%
  mutate(SMILES = ifelse(!is.na(IsomericSMILES), IsomericSMILES, CanonicalSMILES))

# Save Supplementary File. Contains: Compound, InChIKey, SMILES, CID
# write_csv(df_supplementary, "bitter_screen_example_supplementary.csv")

# Create final file to run bitterx_pipeline.py
df_run <- df_supplementary %>%
  select(Compound, SMILES) %>%
  distinct()

write_csv(df_run, "bitter_screen_example_BitterX_run.csv")
