# Please cite [paper] or this GitHub repo (gitHub.com/s-kotwal/)

# Script to merge data after running 'Compound, SMILES' list through BitterX. 

# Must have this R script in same directory as bitterx_pipeline.py
# Important, the 'tas2r_data' .csv file should be the same output file generated after running 'bitterx_pipeline.py'

# Load required libraries
library(dplyr)
library(readr)
library(openxlsx)
library(stringi)

# Step 1: Read output file after running bitterx_pipeline.py. Contains columns: Compound, SMILES, hTAS2R
tas2r_data <- read_csv("bitter_screen_example_BitterX_run_output.csv", col_types = cols()) %>%
  select(-Compound)

# Step 2: Define .csv file containing: Compound, SMILES
original_files <- c(
  "bitter_screen_example_BitterX_run.csv"
)

# Step 3: Safe UTF-8 reader
safe_read_csv <- function(file) {
  raw_lines <- readLines(file, warn = FALSE, encoding = "latin1")
  utf8_lines <- iconv(raw_lines, from = "latin1", to = "UTF-8", sub = "byte")
  read_csv(paste(utf8_lines, collapse = "\n"), col_types = cols())
}

# Step 4: Process each file and export final .xlsx with 3 sheets
process_and_export <- function(file) {
  df_original <- safe_read_csv(file)
  
  # Deduplicate TAS2R data before merging
  tas2r_data_clean <- tas2r_data %>%
    distinct(SMILES, .keep_all = TRUE)
  
  # Merge using clean TAS2R data
  df_merged <- df_original %>%
    left_join(tas2r_data_clean, by = "SMILES")
  
  # Deduplicate SMILES
  df_unique <- df_merged %>% distinct(SMILES, .keep_all = TRUE)
  
  # Identify TAS2R columns and filter hits
  tas2r_cols <- grep("^hTAS2R", names(df_unique), value = TRUE)
  tas2r_hits <- df_unique %>% filter(if_any(all_of(tas2r_cols), ~ !is.na(.)))
  
  # Convert to UTF-8 safely
  df_unique <- df_unique %>% mutate(across(where(is.character), stri_enc_toutf8))
  tas2r_hits <- tas2r_hits %>% mutate(across(where(is.character), stri_enc_toutf8))
  
  # Notes text to add to final sheet
  notes <- data.frame(
    Sheets = c("Full Data", "TAS2R Hits"),
    Description = c(
      "TAS2R % with all hits and no hits",
      "TAS2R % only hits, no hits are excluded"
    )
  )
  
  # Create Excel workbook
  wb <- createWorkbook()
  addWorksheet(wb, "Full Data")
  addWorksheet(wb, "TAS2R Hits")
  addWorksheet(wb, "Notes")
  
  writeData(wb, "Full Data", df_unique)
  writeData(wb, "TAS2R Hits", tas2r_hits)
  writeData(wb, "Notes", notes)
  
  output_file <- sub(".csv", "_TAS2R_merged.xlsx", file)
  saveWorkbook(wb, output_file, overwrite = TRUE)
  cat("Final Excel written:", output_file, "\n")
}

# Step 5: Run for each file
lapply(input_files, merge_and_export)