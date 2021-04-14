## STATISTICAL ANALYSIS OF FRONTAL ALPHA ASYMMETRY (FAA) DATA. MULTIVARIATE FAA AS DV?

# LOAD REQUIRED PACKAGES
library(readxl)
library(ggpubr)
library(tidyverse)
library(caret)
library(leaps)
library(MASS)

# PATH
exportdirxls <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\Data.xlsx"

# IMPORT DATA --- RECODE AGE AND HANDEDNESS? BINARY
Data <- data.frame(read_excel(exportdirxls, 1, col_names = TRUE))
Data <- Data[,2:11]

#---------------------------------
# RECODING OF GENDER AND AGE TO BINARY (0/1) VARIABLES
for (i in 1:nrow(Data)) {
    if(Data[i,9] == 2){
        Data[i,9] <- 0
    }
}

for(j in 1:nrow(Data)) {
    if(Data[j,10] == "20-25"){
        Data[j, 10] <- 1
    } else if(Data[j,10] == "25-30"){
        Data[j,10] <- 1
    } else if(Data[j,10] == "30-35"){
        Data[j,10] <- 1
    } else {
        Data[j,10] <- 0
    }
}

Data[,9] <- factor(Data[,9]) # FOR GENDER, 1 = FEMALE, 0 = MALE
Data[,10] <- factor(Data[,10]) # FOR AGE, 1 = YOUNG, 0 = OLD
str(Data)

#---------------------------

# ASSUMPTIONS OF REGRESSION







##### STATISTICS - ROBUST REGRESSION? CHECK ALL ASSUMPTIONS FIRST BEFORE DECIDING WHICH MODEL TO USE!
# https://en.wikipedia.org/wiki/Robust_regression   |   https://www.statmethods.net/stats/regression.html
  
# CREATE SEPARATE DATASETS FOR EACH MODEL (EACH DEPENDENT VARIABLE)
dataF2F1 <- Data[,-c(6:8)]
dataF4F3 <- Data[,-c(5, 7, 8)]
dataF6F5 <- Data[,-c(5,6, 8)]
dataF8F7 <- Data[,-c(5:7)]

## FULL MODELS
full.modelF2F1 <- lm(FAA.F2F1 ~ ., data = dataF2F1)
full.modelF4F3 <- lm(FAA.F4F3 ~ ., data = dataF4F3)
full.modelF6F5 <- lm(FAA.F6F5 ~ ., data = dataF6F5)
full.modelF8F7 <- lm(FAA.F8F7 ~ ., data = dataF8F7)

# STEPWISE MODELS - NOT STEPAIC. EITHER REGSUBSETS OR

models <- regsubsets(Fertility~., data = , nvmax = 5, method = "seqrep")
summary(models)
step.modelF2F1 <- stepAIC(full.modelF2F1, direction = "both", trace = FALSE)
step.modelF4F3 <- stepAIC(full.modelF4F3, direction = "both", trace = FALSE)
step.modelF6F5 <- stepAIC(full.modelF6F5, direction = "both", trace = FALSE)
step.modelF8F7 <- stepAIC(full.modelF8F7, direction = "both", trace = FALSE)
summary(step.modelF2F1)

#1: The relationship between the IVs and the DV is linear

# DESCRIPTIVE STATISTICS - LAYOUT() FOR PLOTTING SEE HELP
summary(Data)

## END OF SCRIPT
