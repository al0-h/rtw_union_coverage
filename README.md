# Right-to-Work Laws, Union Decline, and Employer Power  
**Evidence from Staggered Reforms in U.S. Labor Markets**  

**Author:** Alexander Leon-Hernandez  
**Replication Do Files** — *version dated 08 .06 .2025*  

---

## Table of Contents
1. [Overview](#overview)  
2. [Folder Structure](#folder-structure)  
3. [Quick Start](#quick-start)  
4. [Citation](#citation)  
5. [Contact](#contact)  
6. [License](#license)  

---

## Overview
This repository contains all **Stata .do** scripts and auxiliary materials required to reproduce the empirical results in **“Right-to-Work Laws, Union Decline, and Employer Power: Evidence from Staggered Reforms in U.S. Labor Markets.”**  
The replication package:

* Downloads and cleans the raw data sources.  
* Constructs the key variables and analytic datasets.  
* Generates all tables and figures in the paper and online appendix.  

---

## Folder Structure
```
├── Code/            # Replication .do files
│   ├── _Archive  # Stores older code
│   ├── ...       # Scripts Generating Figures and Tables
│   └── Logs/     # Keeps logs of code
├── Data/                  # Raw data; empty; .gitignored
│   └── CPS_Extract/
├── Intm/                  # Processed data
├── Presentations/
│  ├── _Archive/              # Previous versions
│  ├── Bibliography/
│  ├── Figures/               # Final figures (.pdf, .png)
│  ├── Formatting/
│  │  └── Formatting Ref/         # AEJ LaTeX reference
│  ├── Sections/
│  └── Tables/
├── LICENSE.txt
├── .gitignore
├── README.txt
└── README.md              # This file
```

## Quick Start

git clone https://github.com/al0-h/rtw_union_power.git
cd rtw_union_power
make demo            # builds a 100-row sample and runs a toy DiD
make clean           # removes temp files

## Step-by-Step Replication Guide
```bash
git clone https://github.com/al0-h/rtw_union_power.git
cd rtw_union_power

# 1) Create your local env file with your own IPUMS key
cp .env.example .env
# then open .env and set:
# IPUMS_MICRODATA_API_KEY=your_own_ipums_key_here

# 2) Run the full pipeline (Python -> Stata -> R)
snakemake --cores 1



## Troubleshooting (short FAQ)
* “file RTW_Years.xlsx not found” → place RTW_Years.xlsx in Data/.
* Make sure that if you you have csdid install by typing "ssc install csdid" in the Stata console

## Citation 
Leon-Hernandez, Alexander (2025).
"Right-to-Work, Union Coverage, and the Structure of Pay” Replication files, GitHub.

## Contact
alexander.leon-hernandez@utexas.edu

## License
(This repo is released under the MIT License; see LICENSE.)
