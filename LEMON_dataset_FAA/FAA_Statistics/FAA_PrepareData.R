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

# ADD EO AND EC EPOCHS TOGETHER, AS THERE IS NO DIFFERENCE BETWEEN THEM. CORRECTLY DONE?
FAA <- (EO_FAA + EC_FAA) / 2
colnames(FAA) <- c("FAA.F2F1", "FAA.F4F3", "FAA.F6F5", "FAA.F8F7")
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

# COMBINE FAA-SCORES AND BEHAVIOURAL DATA INTO ONE DATA.FRAME
Data <- cbind(bisbas, FAA)

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
# CHANGE NAMES OF SOME VARIABLES (FOR R STANDARD)
colnames(Data)[10] <- "Gender"
colnames(Data)[2] <- "BAS.Drive"
colnames(Data)[3] <- "BAS.Fun"
colnames(Data)[4] <- "BAS.Reward"

# EXPORT TO EXCEL (.XLSX) FILE IN EGG_Statistics folder
write_xlsx(Data, path = exportdirxls, col_names=TRUE, format_headers=TRUE)

## END OF SCRIPT
