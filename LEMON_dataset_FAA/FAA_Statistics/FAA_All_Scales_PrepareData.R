## IMPORTING FRONTAL ALPHA ASYMMETRY (FAA) SCORES, BEHAVIOURAL DATA, AND DEMOGRAPHICS (ALL SCALES)
# EXPLAIN, I GUESS.

# PATHS TO FAA-SCORES, FOLDER CONTAINING EMOTION AND PERSIONALITY TEST BATTERY,
# DEMOGRAPHICS, FAA DIAGNOSTICS, AND OUTPUT FILE
faadir <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\FAAscores_CSD.xls"
emotdir <- "D:/MPI_LEMON/Behavioural_Data_MPILMBB_LEMON/Emotion_and_Personality_Test_Battery_LEMON/"
demodir <- "D:\\MPI_LEMON\\Behavioural_Data_MPILMBB_LEMON\\META_File_IDs_Age_Gender_Education_Drug_Smoke_SKID_LEMON.csv"
eegsubsdir <- "D:/MPI_LEMON/EEG_MPILMBB_LEMON/EEG_Statistics/Diagnostics.csv"
exportdirxls <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\DataLemon.xlsx"

# IMPORT LIST OF SUBJECTS (N = 213) AND FRONTAL ALPHA (FAA) ASYMMETRY SCORES
eegsubs <- read_csv(eegsubsdir, col_names = TRUE)
eegsubs <- eegsubs$Subject
FAA <- data.frame(read_excel(faadir, 3, col_names = FALSE))
row.names(FAA) <- eegsubs
FAA <- cbind(eegsubs, FAA)

# IMPORT ALL SCALES AS SEPARATE DATA FRAMES
setwd(emotdir) # FILE CONTAINING THE EMOTION AND PERSONALITY TEST BATTERY
temp = list.files(pattern="*.csv")
list2env(
    lapply(setNames(temp, make.names(gsub("*.csv$", "", temp))), 
           read.csv), envir = .GlobalEnv)
rm(MDBF_Day1,MDBF_Day2,MDBF_Day3, FTP) # REMOVE MDBF SCALES, FTP SCALE AND YFAS (TOO MUCH NA)

# IDENTIFY AND REMOVE SUBJECTS WITH BEHAVIOURAL DATA THAT DO NOT HAVE EEG-DATA
BISBAS <- BISBAS[order(BISBAS$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(BISBAS$ID, eegsubs) # 7 SUBJECTS IDENTIFIED
setdiff(eegsubs, BISBAS$ID) # NULL (0)
BISBAS <- BISBAS[- which(BISBAS$ID %in% differ), - 1] # 7 SUBJECTS AND $ID REMOVED

CERQ <- CERQ[order(CERQ$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(CERQ$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, CERQ$ID) # NULL (0)
CERQ <- CERQ[- which(CERQ$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

COPE <- COPE[order(COPE$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(COPE$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, COPE$ID) # 1 SUBJECT IDENTIFIED
COPE <- rbind(COPE, c(as.character(setdiff(eegsubs, COPE$ID)), 0,0,0,0,0,0,0,0,0,0,0,0,0,0)) # FOR NOW ADD SUB-146 WITH ZEROS
COPE <- COPE[- which(COPE$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

ERQ <- ERQ[order(ERQ$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(ERQ$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, ERQ$ID) # NULL (0)
ERQ <- ERQ[- which(ERQ$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

F.SozU_K.22 <- F.SozU_K.22[order(F.SozU_K.22$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(F.SozU_K.22$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, F.SozU_K.22$ID) # NULL (0)
F.SozU_K.22 <- F.SozU_K.22[- which(F.SozU_K.22$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

FEV <- FEV[order(FEV$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(FEV$ID, eegsubs) # 15 SUBJECTS IDENTIFIED
setdiff(eegsubs, FEV$ID) # NULL (0)
FEV <- FEV[- which(FEV$ID %in% differ), - 1] # 15 SUBJECTS AND $ID REMOVED

LOT.R <- LOT.R[order(LOT.R$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(LOT.R$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, LOT.R$ID) # NULL (0)
LOT.R <- LOT.R[- which(LOT.R$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

MARS <- MARS[order(MARS$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(MARS$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, MARS$ID) # 12 SUBJECTS!
MARS <- MARS[- which(MARS$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

MSPSS <- MSPSS[order(MSPSS$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(MSPSS$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, MSPSS$ID) # NULL (0)
MSPSS <- MSPSS[- which(MSPSS$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

NEO_FFI <- NEO_FFI[order(NEO_FFI$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(NEO_FFI$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, NEO_FFI$ID) # NULL (0)
NEO_FFI <- NEO_FFI[- which(NEO_FFI$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

PSQ <- PSQ[order(PSQ$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(PSQ$ID, eegsubs) # 15 SUBJECTS IDENTIFIED
setdiff(eegsubs, PSQ$ID) # NULL (0)
PSQ <- PSQ[- which(PSQ$ID %in% differ), - 1] # 15 SUBJECTS AND $ID REMOVED

STAI_G_X2 <- STAI_G_X2[order(STAI_G_X2$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(STAI_G_X2$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, STAI_G_X2$ID) # NULL (0)
STAI.TRAIT.ANXIETY <- STAI_G_X2[- which(STAI_G_X2$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED
rm(STAI_G_X2) # CHANGED NAME

STAXI <- STAXI[order(STAXI$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(STAXI$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, STAXI$ID) # NULL (0)
STAXI <- STAXI[- which(STAXI$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

TAS <- TAS[order(TAS$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(TAS$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, TAS$ID) # NULL (0)
TAS <- TAS[- which(TAS$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

TEIQue.SF <- TEIQue.SF[order(TEIQue.SF$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(TEIQue.SF$ID, eegsubs) # 8 SUBJECTS IDENTIFIED
setdiff(eegsubs, TEIQue.SF$ID) # NULL (0)
TEIQue.SF <- TEIQue.SF[- which(TEIQue.SF$ID %in% differ), - 1] # 8 SUBJECTS AND $ID REMOVED

TICS <- TICS[order(TICS$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(TICS$ID, eegsubs) # 15 SUBJECTS IDENTIFIED
setdiff(eegsubs, TICS$ID) # NULL (0)
TICS <- TICS[- which(TICS$ID %in% differ), - 1] # 15 SUBJECTS AND $ID REMOVED

UPPS <- UPPS[order(UPPS$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(UPPS$ID, eegsubs) # 15 SUBJECTS IDENTIFIED
setdiff(eegsubs, UPPS$ID) # NULL (0)
UPPS <- UPPS[- which(UPPS$ID %in% differ), - 1] # 15 SUBJECTS AND $ID REMOVED

demographics <- data.frame(read_csv(demodir)) # IMPORT DEMOGRAPHICS
demographics <- demographics[order(demographics$ID),] # SORT IN ORDER OF SUBJECT ID
differ <- setdiff(demographics$ID, eegsubs) # 15 SUBJECTS IDENTIFIED
setdiff(eegsubs, demographics$ID) # NULL (0)
demographics <- demographics[- which(demographics$ID %in% differ), - 1] # 15 SUBJECTS AND $ID REMOVED
demographics <- demographics[c(1,2,14)] # GENDER, AGE, AND HAMILTON DEPRESSION SCALE

# MARS?

# COMBINE INTO ONE DATA FRAME
Data <- cbind(FAA, BISBAS, CERQ, COPE, ERQ, F.SozU_K.22, FEV, LOT.R, MSPSS, NEO_FFI,
              PSQ, STAI.TRAIT.ANXIETY, STAXI, TAS, TEIQue.SF, TICS, UPPS, demographics)
colnames(Data)[c(1:5, 91)] <- c("Subject", "FAA.F2F1", "FAA.F4F3", "FAA.F6F5", "FAA.F8F7", "Gender")
names(Data) <- gsub("_", ".", names(Data)) # CHANGE TO DOTS IN THE NAMES. R STANDARD

# EXPORT TO EXCEL (.XLSX) FILE IN EGG_Statistics folder
write_xlsx(Data, path = exportdirxls, col_names=TRUE, format_headers=TRUE)

## END OF SCRIPT