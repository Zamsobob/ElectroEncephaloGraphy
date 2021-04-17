## STATISTICAL ANALYSIS OF FRONTAL ALPHA ASYMMETRY (FAA) DATA. MULTIVARIATE FAA AS DV?

# LOAD REQUIRED PACKAGES
library(readxl)
library(ggpubr)
library(tidyverse)
library(caret)
library(leaps)
library(MASS)
library(foreign)
library(Hmisc)

# PATH TO DATA FILE
exportdirxls <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\Data.xlsx"

# IMPORT DATA
Data <- data.frame(read_excel(exportdirxls, 1, col_names = TRUE))
Data <- Data[,1:15]
N = nrow(Data)

#---------------------------------
# RECODING OF GENDER AND AGE TO INDICATOR/DUMMY (0/1) VARIABLES
# THE INTERCEPT WILL BE THE ESTIMATED Y-VALUE FOR THE REFERENCE GROUP (AGE AND GENDER EQUAL TO 0)
for (i in 1:N) {
    if(Data[i,14] == 2){
        Data[i,14] <- 0
    }
}

for(j in 1:N) {
    if(Data[j,15] == "20-25"){
        Data[j, 15] <- 1
    } else if(Data[j,15] == "25-30"){
        Data[j,15] <- 1
    } else if(Data[j,15] == "30-35"){
        Data[j,15] <- 1
    } else {
        Data[j,15] <- 0
    }
}

Data[,14] <- factor(Data[,14]) # FOR GENDER, 1 = FEMALE, 0 = MALE
Data[,15] <- factor(Data[,15]) # FOR AGE, 1 = YOUNG, 0 = OLD
str(Data)

#---------------------------

##### STATISTICS - ROBUST REGRESSION

# CREATE SEPARATE DATASETS FOR EACH MODEL (EACH DEPENDENT VARIABLE)
dataF2F1 <- Data[,-c(7:9)]
dataF4F3 <- Data[,-c(6, 8, 9)]
dataF6F5 <- Data[,-c(6,7, 9)]
dataF8F7 <- Data[,-c(6:8)]

## RUN FOUR OLS REGRESSION MODELS, ONE FOR EACH ELECTRODE PAIR
summary(full.modelF2F1 <- lm(FAA.F2F1 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF2F1))
summary(full.modelF4F3 <- lm(FAA.F4F3 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF4F3))
summary(full.modelF6F5 <- lm(FAA.F6F5 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF6F5))
summary(full.modelF8F7 <- lm(FAA.F8F7 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF8F7))

# DIAGNOSTICS

# SCATTER PLOTS - LINEARITY (HAVE IN ASSUMPTIONS ATM - MAKE ONE SCRIPT FOR DESCRIPTIVE/EXPLORATORY)


opar <- par(mfrow = c(2,2), oma = c(0, 0, 1.1, 0))
plot(full.modelF2F1, las = 1) # obs. 144, 153, 157 are possibly problematic
plot(full.modelF4F3, las = 1) # obs. 167, 174, 207 are possibly problematic
plot(full.modelF6F5, las = 1) # obs. 69, 77, 174 are possibly problematic
plot(full.modelF8F7, las = 1) # obs. 78, 145, 204 are possibly problematic
par(opar)

# COOK'S DISTANCES. CUT-OFF POINT OF 4/N, WHERE N = 211
d1 <- cooks.distance(full.modelF2F1)
d2 <- cooks.distance(full.modelF4F3)
d3 <- cooks.distance(full.modelF6F5)
d4 <- cooks.distance(full.modelF8F7)
r1 <- stdres(full.modelF2F1) # STANDARDIZED RESIDUALS
r2 <- stdres(full.modelF4F3)
r3 <- stdres(full.modelF6F5)
r4 <- stdres(full.modelF8F7)
a1 <- cbind(dataF2F1, d1, r1)
a2 <- cbind(dataF4F3, d2, r2)
a3 <- cbind(dataF6F5, d3, r3)
a4 <- cbind(dataF8F7, d4, r4)
dcutoff1 <- a1[d1 > 4/N, ]
dcutoff2 <- a2[d1 > 4/N, ]
dcutoff3 <- a3[d1 > 4/N, ]
dcutoff4 <- a4[d1 > 4/N, ]
# SAME 10 SUBJECTS IN ALL MODELS

# CALCULATE ABSOLUTE VALUE OF RESIDUALS. VIEW 20 OBS. WITH HIGHEST RESIDUALS
rabs1 <- abs(r1)
a1 <- cbind(dataF2F1, d1, r1, rabs1)
a1sorted <- a1[order(-rabs1), ]
absresids1 <- a1sorted[1:20, ]
View(absresids1)

rabs2 <- abs(r2)
a2 <- cbind(dataF4F3, d2, r2, rabs2)
a2sorted <- a2[order(-rabs2), ]
absresids2 <- a2sorted[1:20, ]
View(absresids2)

rabs3 <- abs(r3)
a3 <- cbind(dataF6F5, d3, r3, rabs3)
a3sorted <- a3[order(-rabs3), ]
absresids3 <- a3sorted[1:20, ]
View(absresids3)

rabs4 <- abs(r4)
a4 <- cbind(dataF8F7, d4, r4, rabs4)
a4sorted <- a4[order(-rabs4), ]
absresids4 <- a4sorted[1:20, ]
View(absresids4)

#----------------RR TESTS------------------
# RUN ROBUST (IRLS) REGRESSION WITH HUBER WEIGHTING FUNCTION
summary(rr.huber.F2F1 <- rlm(FAA.F2F1 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF2F1))
summary(rr.huber.F4F3 <- rlm(FAA.F4F3 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF4F3))
summary(rr.huber.F6F5 <- rlm(FAA.F6F5 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF6F5))
summary(rr.huber.F8F7 <- rlm(FAA.F8F7 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age, data = dataF8F7))

hweights1 <- data.frame(subject = dataF2F1$ID, resid = rr.huber.F2F1$resid, weight = rr.huber.F2F1$w)
hweights12 <- hweights1[order(rr.huber.F2F1$w), ]
hweights12[1:15, ] # We can see that subjects with large residuals get down-weighted


# RUN ROBUST (IRLS) REGRESSION WITH BISQUARE WEIGHTING FUNCTION
summary(rr.bisquare.F2F1 <- rlm(FAA.F2F1 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age,
                                data = dataF2F1, psi = psi.bisquare))
summary(rr.bisquare.F4F3 <- rlm(FAA.F4F3 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age,
                                data = dataF4F3, psi = psi.bisquare))
summary(rr.bisquare.F6F5 <- rlm(FAA.F6F5 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age,
                                data = dataF6F5, psi = psi.bisquare))
summary(rr.bisquare.F8F7 <- rlm(FAA.F8F7 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+Gender+Age,
                                data = dataF8F7, psi = psi.bisquare))

biweights1 <- data.frame(subject = dataF2F1$ID, resid = rr.bisquare.F2F1$resid, weight = rr.bisquare.F2F1$w)
biweights12 <- biweights1[order(rr.bisquare.F2F1$w), ]
biweights12[1:15, ] # We can see that subjects with large residuals get down-weighted


# When comparing the results of a regular OLS regression and a robust regression,
# if the results are very different, you will most likely want to use the results from the
# robust regression. Large differences suggest that the model parameters are being highly
# influenced by outliers. Different functions have advantages and drawbacks. Huber weights can
# have difficulties with severe outliers, and bisquare weights can have difficulties converging or
# may yield multiple solutions.






# STEPWISE MODELS - NOT STEPAIC. EITHER REGSUBSETS 

models <- regsubsets(Fertility~., data = , nvmax = 5, method = "seqrep")
summary(models)
step.modelF2F1 <- stepAIC(full.modelF2F1, direction = "both", trace = FALSE)
step.modelF4F3 <- stepAIC(full.modelF4F3, direction = "both", trace = FALSE)
step.modelF6F5 <- stepAIC(full.modelF6F5, direction = "both", trace = FALSE)
step.modelF8F7 <- stepAIC(full.modelF8F7, direction = "both", trace = FALSE)
summary(step.modelF2F1)
#----------------NOTES-------------------------------------------------------

# REGRESSION - MIXED-EFFECTS MODELS. ALSO KNOWN AS MULTILEVEL MODELS, 
# HIERARCHICAL MODELS, AND RANDOM COEFFICIENTS MODELS

# probability of frontal EEG asymmetry given the behavioral variable differs
# P(EEG asymmetry/behavioral measure)


# CALCULATING SAMPLE SIZE FOR REGRESSION: https://designingexperiments.shinyapps.io/BUCSS_ss_power_reg_all/

# diagnostic plots
# layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page

# RESIDUAL ANALYSIS. CORRECT FOR MULTIPLE TESTS.

## END OF SCRIPT
