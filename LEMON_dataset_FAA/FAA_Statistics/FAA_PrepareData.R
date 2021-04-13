## IMPORTING FRONTAL ALPHA ASYMMETRY (FAA) SCORES, BEHAVIOURAL DATA, AND DEMOGRAPHICS

# LOAD REQUIRED PACKAGES
library(readxl)
library(dplyr)
library(writexl)
library(readr)

# PATHS TO SET (IN ORDER: FAA-SCORES, BIS-BAS SCORES, DEMOGRAPHICS, OUTPUT FOLDER)
faadir <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\FAAscores_CSD.xls"
bisbasdir <- "D:\\MPI_LEMON\\Behavioural_Data_MPILMBB_LEMON\\Emotion_and_Personality_Test_Battery_LEMON\\BISBAS.csv"
demodir <- "D:\\MPI_LEMON\\Behavioural_Data_MPILMBB_LEMON\\META_File_IDs_Age_Gender_Education_Drug_Smoke_SKID_LEMON.csv"
exportdir <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\Data.xls"

#---------------------------
# IMPORT eyes-open (EO) and eyes-closed (EC) FRONTAL ASYMMETRY SCORES
EO_FAA <- data.frame(read_excel(faadir, 4, col_names = FALSE))
EC_FAA <- data.frame(read_excel(faadir, 5, col_names = FALSE))

#---------------------------
# NORMALITY TESTS ON FAA DATA USING SHAPIRO-WILKS
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
#IMPORT DEMOGRAPHICS
demographics <- read_csv(demodir)

#---------------------------
# IMPORT BEHAVIOURAL DATA
behavioural <- read_excel(bisbasdir, 1, col_names = TRUE);
behavioural <- data.frame(behavioural)
BAS <- (behavioural[,1] + behavioural[,2] + behavioural[,3]) / 3 # SEE shorturl.at/aixX7
behavioural <- cbind(BAS, behavioural)

# COMBINE FAA-SCORES AND BEHAVIOURAL DATA INTO ONE DATA.FRAME
Data <- cbind(FAA, behavioural)
str(Data)

# EXPORT TO EXCEL FILE
write_xlsx(Data, path = exportdir, col_names=TRUE, format_headers=TRUE)

## END OF SCRIPT

# NOTES

# read.table to import csv bis-bas. Chang all paths to MPI. Look up calculating cronbach's alpha with
# library(psych) - alpha(mydata)