## STATISTICAL ANALYSIS OF FRONTAL ALPHA ASYMMETRY (FAA) DATA

# LOAD REQUIRED PACKAGES
library(readxl)
library(dplyr)
library(writexl)
library(ggpubr)

exportdir <- "D:\\FAA_Study_2021\\Skovde\\Skovde_EEG\\EEG_Statistics\\FAA_Data.xlsx"

# IMPORT DATA
Data <- read_excel(exportdir, 1, col_names = TRUE);
View(Data)

# EXTRACT INDIVIDUAL ASYMMETRY SCORES
FP <- Data[,2]   # Frontopolar (AF4 - AF3)
FC <- Data[,3]   # Frontocentral (F4 - F3)
FR <- Data[,4]   # Frontal (F6 - F5)
FT <- Data[,5]   # Frontotemporal (F8 - F7)
View(Data)
View(FP)
View(FC)
View(FR)
View(FT)

#---------------------------
# REGRESSION - MIXED-EFFECTS MODELS. ALSO KNOWN AS MULTILEVEL MODELS, 
# HIERARCHICAL MODELS, AND RANDOM COEFFICIENTS MODELS

# CALCULATING SAMPLE SIZE FOR REGRESSION: https://designingexperiments.shinyapps.io/BUCSS_ss_power_reg_all/


# RESIDUAL ANALYSIS. CORRECT FOR MULTIPLE TESTS. CHAP 9 COVARIATES