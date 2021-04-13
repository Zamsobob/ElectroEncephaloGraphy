## IMPORTING FRONTAL ALPHA ASYMMETRY (FAA) SCORES, BEHAVIOURAL DATA (BIS-BAS), AND DEMOGRAPHICS

# LOAD REQUIRED PACKAGES
library(readxl)
library(writexl)
library(readr)

# PATHS TO SET (IN ORDER: FAA-SCORES, BIS-BAS SCORES, DEMOGRAPHICS, LIST OF SUBJECTS, OUTPUT DIRECTORY)
faadir <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\FAAscores_CSD.xls"
bisbasdir <- "D:\\MPI_LEMON\\Behavioural_Data_MPILMBB_LEMON\\Emotion_and_Personality_Test_Battery_LEMON\\BISBAS.csv"
demodir <- "D:\\MPI_LEMON\\Behavioural_Data_MPILMBB_LEMON\\META_File_IDs_Age_Gender_Education_Drug_Smoke_SKID_LEMON.csv"
eegsubsdir <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\subslist.csv"
exportdirxls <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\Data.xlsx"

#---------------------------
# IMPORT LIST OF SUBJECTS (N = 212)
eegsubs <- read_csv(eegsubsdir, col_names = FALSE)

#---------------------------
# IMPORT eyes-open (EO) and eyes-closed (EC) FRONTAL ASYMMETRY SCORES. DONT SEPARATE LATER IN MATLAB
EO_FAA <- data.frame(read_excel(faadir, 4, col_names = FALSE))
EC_FAA <- data.frame(read_excel(faadir, 5, col_names = FALSE))

# NORMALITY TESTS ON FAA DATA USING SHAPIRO-WILKS
shapiro.test(EO_FAA[,1]) # NOT NORMAL (F2-F1)
shapiro.test(EO_FAA[,2]) # NOT NORMAL (F4-F3)
shapiro.test(EO_FAA[,3]) # NORMAL (F6-F5)
shapiro.test(EO_FAA[,4]) # NORMAL (F8-F7)

shapiro.test(EC_FAA[,1]) # NOT NORMAL (F2-F1)
shapiro.test(EC_FAA[,2]) # NOT NORMAL (F4-F3)
shapiro.test(EC_FAA[,3]) # NORMAL (F6-F5)
shapiro.test(EC_FAA[,4]) # NORMAL (F8-F7)

# PAIRED T-TESTS TO TEST DIFFERENCE BETWEEN EO AND EC FOR EACH PAIR. NS
t.test(EO_FAA[,1], EC_FAA[,1], paired = TRUE, alternative = "two.sided")
t.test(EO_FAA[,2], EC_FAA[,2], paired = TRUE, alternative = "two.sided")

# TWO-SAMPLE WILCOXON SIGNED-RANK TEST (Hollander & Wolfe (1973), 69f) FOR THE
# NON-NORMAL DISTRIBUTED VARIABLES (2:4). BOTH SIGNIFICANT
wilcox.test(EO_FAA[,3], EC_FAA[,3], paired = TRUE, alternative = "two.sided", conf.int = TRUE)
wilcox.test(EO_FAA[,4], EC_FAA[,4], paired = TRUE, alternative = "two.sided", conf.int = TRUE)

# ADD EO AND EC EPOCHS TOGETHER, AS THERE IS NO DIFFERENCE BETWEEN THEM. CORRECTLY DONE?
FAA <- (EO_FAA + EC_FAA) / 2
colnames(FAA) <- c("FAA_F2F1", "FAA_F4F3", "FAA_F6F5", "FAA_F8F7")
FAA <- FAA[-7,] # DUPLICATE SUBJECT 10 ATM. REMOVE LATER AFTER PREPROCESSING AGAIN
rm(EO_FAA, EC_FAA) # remove later

#---------------------------
# IMPORT BIS-BAS DATA
bisbas <- read_csv(bisbasdir)
bisbas <- bisbas[order(bisbas$ID),] # SORT IN ORDER OF SUBJECT ID

# IDENTIFY SUBJECTS IN BIS-BAS DATA THAT DO NOT HAVE EEG-DATA, AND REMOVE THEM
setdiff(bisbas$ID, eegsubs$X1) # 9 SUBJECTS IDENTIFIED (3 REMOVED DURING PRE-PROCESSING)
setdiff(eegsubs$X1, bisbas$ID) # NULL (0)

# REMOVE THE 9 SUBJECTS FROM THE BIS-BAS DATA
bisbas <- bisbas[-c(35, 84, 87, 117, 131, 135, 157, 187, 213), ]
setdiff(bisbas$ID, eegsubs$X1) # DIFFERENCE SHOULD NOW BE NULL
setdiff(eegsubs$X1, bisbas$ID) # STILL NULL, AS IT SHOULD BE

# CALCULATE TOTAL BAS SCORES (THIS IS AVERAGE), LOOK INTO THIS
BAS <- (bisbas[,2] + bisbas[,3] + bisbas[,4]) / 3
colnames(BAS) <- "BAS"
behavioural <- cbind(bisbas, BAS)

# COMBINE FAA-SCORES AND BEHAVIOURAL DATA INTO ONE DATA.FRAME
Data <- cbind(behavioural, FAA)

#---------------------------
#IMPORT DEMOGRAPHICS
demographics <- read_csv(demodir)
demographics <- demographics[order(demographics$ID),] # SORT IN ORDER OF SUBJECT ID

# IDENTIFY SUBJECTS IN DEMOGRAPHICS DATA THAT DO NOT HAVE EEG-DATA, AND REMOVE THEM
setdiff(demographics$ID, eegsubs$X1) # 17 SUBJECTS IDENTIFIED
setdiff(eegsubs$X1, demographics$ID) # NULL (0)

# REMOVE THE 17 SUBJECTS FROM THE DEMOGRAPHICS DATA
demographics <- demographics[-c(35, 84, 85, 88, 104, 119, 133, 137, 143, 145, 161, 188, 192, 200, 219, 220, 227), ]
setdiff(demographics$ID, eegsubs$X1) # DIFFERENCE SHOULD NOW BE NULL
setdiff(eegsubs$X1, demographics$ID) # STILL NULL

# REMOVE ID COLUMN AND COMBINE ALL DATA INTO ONE DATA.FRAME
demographics <- demographics[,-1]
Data <- cbind(Data, demographics)

# EXPORT TO EXCEL (.XLSX) FILE
write_xlsx(Data, path = exportdirxls, col_names=TRUE, format_headers=TRUE)

## END OF SCRIPT
