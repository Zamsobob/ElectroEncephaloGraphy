# BEST PRACTISE PREPARING DATA FOR R. DO IT ON SCHOOL LOG IN IF I NEED EXCEL.

## LAPLACIAN TRANSFORMED DATA

# LOAD REQUIRE PACKAGES
library(readxl)
library(dplyr)
# if(!require(devtools)) install.packages("devtools")
# devtools::install_github("kassambara/ggpubr")
# install.packages("ggpubr")
# library(ggpubr)

#---------------------------
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

#---------------------------
# NORMALITY TESTS USING SHAPIRO-WILKS
shapiro.test(EO_FAA[,1])
shapiro.test(EO_FAA[,2])
shapiro.test(EO_FAA[,3])
shapiro.test(EO_FAA[,4]) # NOT NORMAL

shapiro.test(EC_FAA[,1])
shapiro.test(EC_FAA[,2])
shapiro.test(EC_FAA[,3])
shapiro.test(EC_FAA[,4]) # NOT NORMAL

# PAIRED T-TESTS TO TEST DIFFERENCE BETWEEN EO AND EC FOR EACH PAIR. ALL NS
t.test(EO_FAA[,1], EC_FAA[,1], paired = TRUE, alternative = "two.sided")
t.test(EO_FAA[,2], EC_FAA[,2], paired = TRUE, alternative = "two.sided")
t.test(EO_FAA[,3], EC_FAA[,3], paired = TRUE, alternative = "two.sided")

# WILCOXON SIGNED-RANK TEST FOR THE NON-NORMAL DISTRIBUTED VARIABLES (F8-F7). NS
wilcox.test(EO_FAA[,4], EC_FAA[,4], paired = TRUE, alternative = "two.sided")

# HOW TO ADD THE EPOCHS TOGETHER? MATLAB? EO + EC / 2 ?


# EXTRACT INDIVIDUAL ASYMMETRY SCORES. DO I NEED TO?
#EO_FP <- EO_FAA[,1] # eyes-open frontopolar (AF4 - AF3)
#EO_FC <- EO_FAA[,2]   # eyes-open frontocentral (F4 - F3)
#EO_F <- EO_FAA[,3]   # eyes-open frontal (F6 - F5)
#EO_FT <- EO_FAA[,4]   # eyes-open frontotemporal (F8 - F7)

#EC_FP <- EC_FAA[1,] # eyes-open frontopolar (AF4 - AF3)
#EC_FC <- EC_FAA[2,] # eyes-open frontocentral (F4 - F3)
#EC_F <- EC_FAA[3,]  # eyes-open frontal (F6 - F5)
#EC_FT <- EC_FAA[4,]  # eyes-open frontotemporal (F8 - F7)
