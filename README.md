# Automated-BitterX-Compound-Screening
In silico workflow to screen for bitter compounds using BitterX (https://mdl.shsmu.edu.cn/BitterX/module/mainpage/mainpage.jsp).

3 steps:
1. Convert InChIkey to SMILES using PubChemR package. (https://github.com/selcukorkmaz/PubChemR)
2. Run python script to collect data from BitterX.
3. Merge data from step 1 and 2 using R.
Refer to bitter_screen_example.csv for example CSV.

Requirements: R (4.4.2), Python 3.9

Huang, W. et al. BitterX: a tool for understanding bitter taste in humans. Sci. Rep. 6, 23450; doi: 10.1038/srep23450 (2016).

Korkmaz S, Yamasan BE, Goksuluk D (2023). PubChemR: Interface to the ‘PubChem’ Database for Chemical Data Retrieval. R package version 0.99-1, https://CRAN.R-project.org/package=PubChemR.
