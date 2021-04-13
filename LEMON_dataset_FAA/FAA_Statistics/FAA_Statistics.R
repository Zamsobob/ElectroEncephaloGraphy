## STATISTICAL ANALYSIS OF FRONTAL ALPHA ASYMMETRY (FAA) DATA

# LOAD REQUIRED PACKAGES
library(readxl)
library(dplyr)
library(writexl)
library(ggpubr)

# PATH
exportdir <- "D://MPI_LEMON//EEG_MPILMBB_LEMON//EEG_Statistics//FAAscores_CSD.xls"


# IMPORT DATA
Data <- data.frame(read_excel(exportdir, 1, col_names = TRUE))
Data$Gender <- factor(Data$Gender) # FOR GENDER, 0 = FEMALE, 1 = MALE
attach(Data)
str(Data)

#---------------------------

# DESCRIPTIVE STATISTICS, INCLUDING CORRELATIONS. PLOT CORR PLOTS (SUBPLOTS)
traits <- Data[,5:10]
cortraits <- cor(traits) # CORRELATION MATRIX OF THE BEHAVIOUR SCALES
cortraits

# REGRESSION - MIXED-EFFECTS MODELS. ALSO KNOWN AS MULTILEVEL MODELS, 
# HIERARCHICAL MODELS, AND RANDOM COEFFICIENTS MODELS

# MODEL 1 - FP. WHAT ABOUT TOTAL BAS?
mod1 <- lm(AF4AF3 ~ BAS.DR, data = Data)
mod2 <- lm(AF4AF3 ~ BAS.FS, data = Data)
summary(mod1)
summary(mod2)

BAS.DR + BAS.FS + BAS.RR + BIS.Anxiety + FFFS.Fear + Gender

# probability of frontal EEG asymmetry given the behavioral variable differs
# P(EEG asymmetry/behavioral measure)


# CALCULATING SAMPLE SIZE FOR REGRESSION: https://designingexperiments.shinyapps.io/BUCSS_ss_power_reg_all/

# diagnostic plots
layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page
plot(fit)

# RESIDUAL ANALYSIS. CORRECT FOR MULTIPLE TESTS. CHAP 9 COVARIATES

## END OF SCRIPT
