## IMPORTING FRONTAL ASYMMETRY SCORES AND BEHAVIOURAL DATA

# LOAD REQUIRED PACKAGES
library(readxl)
library(dplyr)
library(writexl)

# PATHS
exceldir <- "D:\\FAA_Study_2021\\Skovde\\Skovde_EEG\\EEG_Statistics\\FAAscores_CSD.xls"
exceldirBIS <- "D:\\FAA_Study_2021\\Skovde\\Skovde_EEG\\EEG_Statistics\\Behavioural_Data.xls"
exportdir <- "D:\\FAA_Study_2021\\Skovde\\Skovde_EEG\\EEG_Statistics\\FAA_Data.xlsx"

#---------------------------
# IMPORT EO FRONTAL ASYMMETRY SCORES
EO_FAA <- read_excel(exceldir, 2, col_names = FALSE);
EO_FAA <- as.matrix(EO_FAA)


## IMPORT EC FRONTAL ASYMMETRY SCORES
EC_FAA <- read_excel(exceldir, 3, col_names = FALSE);
EC_FAA <- as.matrix(EC_FAA)

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

# PAIRED T-TESTS TO TEST DIFFERENCE BETWEEN EO AND EC FOR EACH PAIR. NS
t.test(EO_FAA[,1], EC_FAA[,1], paired = TRUE, alternative = "two.sided")

# TWO-SAMPLE WILCOXON SIGNED-RANK TEST (Hollander & Wolfe (1973), 69f) FOR THE
# NON-NORMAL DISTRIBUTED VARIABLES (2:4). ALL NS
wilcox.test(EO_FAA[,2], EC_FAA[,2], paired = TRUE, alternative = "two.sided", conf.int = TRUE)
wilcox.test(EO_FAA[,3], EC_FAA[,3], paired = TRUE, alternative = "two.sided", conf.int = TRUE)
wilcox.test(EO_FAA[,4], EC_FAA[,4], paired = TRUE, alternative = "two.sided", conf.int = TRUE)

# ADD EO AND EC EPOCHS TOGETHER, AS THERE IS NO DIFFERENCE BETWEEN THEM. CORRECTLY DONE?
FAA <- (EO_FAA + EC_FAA) / 2
colnames(FAA) <- c("AF4AF3", "F4F3", "F6F5", "F8F7")

#---------------------------
# IMPORT BEHAVIOURAL DATA
behavioural <- read_excel(exceldirBIS, 1, col_names = TRUE);
behavioural <- as.matrix(behavioural)
## FOR GENDER, 0 = FEMALE, 1 = MALE

FAAdata <- cbind(FAA, behavioural) # COMBINE FAA-SCORES AND BEHAVIOURAL DATA

FAA_means <- apply(FAAdata, MARGIN=2, FUN=mean) # GROUP MEANS
FAA_means = t(FAA_means)
Data <- rbind(FAAdata, FAA_means)
Data[length(Data)] <- NaN

# SET COLUMN NAMES AND ROW NAMES
Subjects <- c("sub-002","sub-005", "sub-006", "sub-008", "sub-009", "sub-011", "sub-013", 
                       "sub-014", "sub-015", "sub-019", "sub-020", "sub-021", "sub-022", "sub-025",
                       "sub-027", "sub-028", "sub-029", "sub-030", "sub-031", "sub-032", "Grp.Mean")
Data <- cbind(Subjects, Data)
View(Data)

# EXPORT TO EXCEL FILE
Data <- as.data.frame(Data)
write_xlsx(Data, path = exportdir, col_names=TRUE, format_headers=TRUE)
