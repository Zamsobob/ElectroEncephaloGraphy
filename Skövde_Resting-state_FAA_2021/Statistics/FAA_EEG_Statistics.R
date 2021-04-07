## STATISTICAL ANALYSIS OF FRONTAL ALPHA ASYMMETRY (FAA) DATA

# LOAD REQUIRED PACKAGES
library(readxl)
library(dplyr)
library(ggpubr)

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
shapiro.test(EO_FAA[,2]) # NOT NORMAL
shapiro.test(EO_FAA[,3]) # NOT NORMAL
shapiro.test(EO_FAA[,4]) # NOT NORMAL

shapiro.test(EC_FAA[,1])
shapiro.test(EC_FAA[,2]) # NOT NORMAL
shapiro.test(EC_FAA[,3]) # NOT NORMAL
shapiro.test(EC_FAA[,4]) # NOT NORMAL

# VARIANCES SIMILAR? ASSUMPTION FOR T-TEST
var(EO_FAA[,1]) - var(EC_FAA[,1])
var(EO_FAA[,2]) - var(EC_FAA[,2])
var(EO_FAA[,3]) - var(EC_FAA[,3])
var(EO_FAA[,2]) - var(EC_FAA[,2])

# PAIRED T-TESTS TO TEST DIFFERENCE BETWEEN EO AND EC FOR EACH PAIR. ALL NS
t.test(EO_FAA[,1], EC_FAA[,1], paired = TRUE, alternative = "two.sided")

# TWO-SAMPLE WILCOXON SIGNED-RANK TEST (Hollander & Wolfe (1973), 69f) FOR THE
# NON-NORMAL DISTRIBUTED VARIABLES (F8-F7). NS
wilcox.test(EO_FAA[,2], EC_FAA[,2], paired = TRUE, alternative = "two.sided", conf.int = TRUE)
wilcox.test(EO_FAA[,3], EC_FAA[,3], paired = TRUE, alternative = "two.sided", conf.int = TRUE)
wilcox.test(EO_FAA[,4], EC_FAA[,4], paired = TRUE, alternative = "two.sided", conf.int = TRUE)

# HOW TO ADD THE EPOCHS TOGETHER? MATLAB? EO + EC / 2 ?
FAA <- (EO_FAA + EC_FAA) /2

#---------------------------
# IMPORT BEHAVIOURAL DATA
exceldirBIS <- "D:/FAA_Study_2021/Skovde/Skovde_EEG/EEG_Statistics/Behavioural_Data.xls"
behavioural <- read_excel(exceldirBIS, 1, col_names = TRUE);
behavioural <- as.matrix(behavioural)
View(behavioural)

FAAdata <- cbind(FAA, behavioural)
View(FAAdata)

# EXTRACT INDIVIDUAL ASYMMETRY SCORES
FP <- FAAdata[,1]   # Frontopolar (AF4 - AF3)
FC <- FAAdata[,2]   # Frontocentral (F4 - F3)
FR <- FAAdata[,3]   # Frontal (F6 - F5)
FT <- FAAdata[,4]   # Frontotemporal (F8 - F7)

#---------------------------
# REGRESSION - MIXED-EFFECTS MODELS. ALSO KNOWN AS MULTILEVEL MODELS, 
# HIERARCHICAL MODELS, AND RANDOM COEFFICIENTS MODELS

# RESIDUAL ANALYSIS
