# Please cite [paper] and this github (github.com/s-kotwal).

# Part two of data curation for bitter compound screening.
# This .py script automates query search and data collection from BitterX
# Requires .csv input file with two columns: Compound, SMILES
    # Example: after running the inchikey_to_smiles.R script on the bitter_screen_example.csv
# To run, use terminal
    # Example:
    # (.venv) PS D:\you_directory> python bitterx_pipeliine.py -i bitter_screen_example_BitterX_run.csv
    #  -o bitter_screen_example_BitterX_run_output.csv
# Important: The output file must be named the same as the 'tas2r_data' assignment in the process_bx_r_script.R

import subprocess
import argparse
import pandas as pd
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException

# Function to set up the webdriver and open the webpage
def setup():
    driver = webdriver.Chrome()
    driver.get("https://mdl.shsmu.edu.cn/BitterX/module/mainpage/mainpage.jsp")
    return driver

# Function to close the WebDriver session
def teardown(driver):
    driver.quit()

# Function to handle the main page
def main_page(smiles):
    job_name = "Job"
    try:
        job_name_input = driver.find_element(by=By.ID, value="jobName")
        smiles_input = driver.find_element(by=By.ID, value="smilesText")
        run_button = driver.find_element(by=By.ID, value="smilesRun")

        job_name_input.send_keys(job_name)
        smiles_input.send_keys(smiles)
        run_button.click()

        view_job_button = driver.find_element(
            by=By.ID, value="jobInfoWindow").find_element(
            by=By.ID, value="ext-gen114").find_elements(
            by=By.CSS_SELECTOR, value="button")[1]
        view_job_button.click()

        second_page_handler(smiles)

    except NoSuchElementException:
        main_page(smiles)

# Function to find the button on the second page
def second_page_button():
    try:
        button = driver.find_element(
            by=By.XPATH,
            value="/html/body/div[1]/div[2]/div/div/div/div/div/div[1]/div/div/div/div[2]/div/div/div/div/div/div/div[2]/div/div[1]/div[2]/div/div/table/tbody/tr/td[8]/div/input")
        return button
    except NoSuchElementException:
        driver.refresh()
        return second_page_button()

# Function to handle the second page
def second_page_handler(smiles):
    button = second_page_button()
    try:
        if 'Error' in button.accessible_name:
            print(button.accessible_name)
            driver.back()
            return

        is_bitter = driver.find_element(
            by=By.XPATH,
            value="/html/body/div[1]/div[2]/div/div/div/div/div/div[1]/div/div/div/div[2]/div/div/div/div/div/div/div[2]/div/div[1]/div[2]/div/div/table/tbody/tr/td[7]/div/span").text.strip()

        if is_bitter == "Yes":
            button.click()
            final_page(smiles)

        driver.back()
    except NoSuchElementException:
        driver.refresh()
        second_page_handler(smiles)

# Function to handle the final page
def final_page(smiles):
    try:
        receptor_list = driver.find_element(
            by=By.XPATH,
            value="/html/body/div[1]/div[2]/div/div/div/div/div/div[1]/div/div/div/div[2]/div/div[2]/div/div/div/div/div/div[2]/div[2]/div[2]/div/div[1]/div[2]").find_elements(
            by=By.CSS_SELECTOR, value="tbody")

        for i in range(len(receptor_list)):
            tmp_xpath = f"/html/body/div[1]/div[2]/div/div/div/div/div/div[1]/div/div/div/div[2]/div/div[2]/div/div/div/div/div/div[2]/div[2]/div[2]/div/div[1]/div[2]/div/div[{i + 1}]/table/tbody/tr/td[3]/div/a/span"
            bitter_id = driver.find_element(by=By.XPATH, value=tmp_xpath).text.strip()

            tmp_xpath = f"/html/body/div[1]/div[2]/div/div/div/div/div/div[1]/div/div/div/div[2]/div/div[2]/div/div/div/div/div/div[2]/div[2]/div[2]/div/div[1]/div[2]/div/div[{i + 1}]/table/tbody/tr/td[8]/div/span"
            probability = driver.find_element(by=By.XPATH, value=tmp_xpath).text.strip()

            if bitter_id not in df.columns:
                df[bitter_id] = 'NA'

            df.loc[df["SMILES"] == smiles, bitter_id] = probability

    except NoSuchElementException:
        driver.refresh()
        final_page(smiles)

# ========== Argument Parser ==========
parser = argparse.ArgumentParser()
parser.add_argument("-i", "--Input", help="Input File, default is \"input.csv\"")
parser.add_argument("-o", "--Output", help="Output File, default is \"output.csv\"")
parser.add_argument("-r", "--r_script", default="process_bx_r_script.R", help="Path to R script for post-processing")
parser.add_argument("-t", "--time", default=30, type=int, help="Timeout (seconds)")
args = parser.parse_args()

# ========== Step 1: Selenium Scraper ==========
input_file = args.Input
output_file = args.Output
time_out = args.time

# Load the input CSV
df = pd.read_csv(input_file, encoding="ISO-8859-1")

# Set up browser
driver = setup()
driver.implicitly_wait(time_out)

# Loop through SMILES
for i, row in df.iterrows():
    print(f"⏳ Processing SMILES #{i + 2}")
    main_page(df.loc[i].iloc[1])
    print("🛑 Waiting 2 minutes before next SMILES...")
    time.sleep(120)

teardown(driver)  # Close the WebDriver session
df.to_csv(output_file, index=False)  # Save the scraped data to CSV

print(f"✅ BitterX data collection completed and saved to: {output_file}")


