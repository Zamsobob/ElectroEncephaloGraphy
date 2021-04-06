# BEST PRACTISE PREPARING DATA FOR R. DO IT ON SCHOOL LOG IN IF I NEED EXCEL.

## LAPLACIAN TRANSFORMED DATA

# LOAD REQUIRE PACKAGES
library(readxl)
library(dplyr)
# if(!require(devtools)) install.packages("devtools")
# devtools::install_github("kassambara/ggpubr")
# install.packages("ggpubr")
# library(ggpubr)

# IMPORT EO FRONTAL ASYMMETRY SCORES
exceldir <- "D:/FAA_Study_2021/Skovde/Skovde_EEG/EEG_Statistics/FAAscores_CSD.xls"
EO_FAA <- read_excel(exceldir, 2, col_names = FALSE);
EO_FAA <- as.matrix(EO_FAA)

# SET COLUMN NAMES AND ROWNAMES
row.names(EO_FAA) <- c("sub-002","sub-005", "sub-006", "sub-008", "sub-009", "sub-011", "sub-013", 
                              "sub-014", "sub-015", "sub-019", "sub-020", "sub-021", "sub-022", "sub-025",
                              "sub-027", "sub-028", "sub-029", "sub-030", "sub-031", "sub-032")

colnames(EO_FAA) <- c("AF4AF3", "F4F3", "F6F5", "F8F7")
View(EO_FAA)

# EXTRACT INDIVIDUAL ASYMMETRY SCORES. DO I NEED TO?
EO_FP <- EO_FAA[1,] # eyes-open frontopolar (AF4 - AF3)
EO_FC <- EO_FAA[2,]   # eyes-open frontocentral (F4 - F3)
EO_F <- EO_FAA[3,]   # eyes-open frontal (F6 - F5)
EO_FT <- EO_FAA[4,]   # eyes-open frontotemporal (F8 - F7)

#---------------------------
## IMPORT EC FRONTAL ASYMMETRY SCORES
EC_FAA <- read_excel(exceldir, 3, col_names = FALSE);
EC_FAA <- as.matrix(EC_FAA)

# SET COLUMN NAMES AND ROW NAMES
row.names(EC_FAA) <- c("sub-002","sub-005", "sub-006", "sub-008", "sub-009", "sub-011", "sub-013", 
                       "sub-014", "sub-015", "sub-019", "sub-020", "sub-021", "sub-022", "sub-025",
                       "sub-027", "sub-028", "sub-029", "sub-030", "sub-031", "sub-032")

colnames(EC_FAA) <- c("AF4AF3", "F4F3", "F6F5", "F8F7")
View(EC_FAA)

# EXTRACT INDIVIDUAL ASYMMETRY SCORES
EC_FP <- EC_FAA[1,] # eyes-open frontopolar (AF4 - AF3)
EC_FC <- EC_FAA[2,] # eyes-open frontocentral (F4 - F3)
EC_F <- EC_FAA[3,]  # eyes-open frontal (F6 - F5)
EC_FT <- EC_FAA[4,]  # eyes-open frontotemporal (F8 - F7)


# NORMALITY TESTS USING SHAPIRO-WILKS
shapiro.test(EO_FP)
shapiro.test(EO_FC)
shapiro.test(EO_F)
shapiro.test(EO_FT)
shapiro.test(EC_FP)
shapiro.test(EC_FC)
shapiro.test(EC_F)
shapiro.test(EC_FT)

# PAIRED-SAMPLES T-TEST TO COMPARE EO AND EC
t.test(EO_FP, EC_FP, paired = TRUE, alternative = "two.sided")
t.test(EO_FC, EC_FC, paired = TRUE, alternative = "two.sided")
t.test(EO_F, EC_F, paired = TRUE, alternative = "two.sided")
t.test(EO_FT, EC_FT, paired = TRUE, alternative = "two.sided")

EO_tot <- EO_FP + EO_FC + EO_F + EO_FT
EC_tot <- EC_FP + EC_FC + EC_F + EC_FT
EO_tot <- t(EO_tot)
EC_tot <- t(EC_tot)
t.test(EO_tot, EC_tot, paired = TRUE, alternative = "two.sided")

