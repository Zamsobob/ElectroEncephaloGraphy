## STATISTICAL ANALYSIS OF FRONTAL ALPHA ASYMMETRY (FAA) DATA

# Load required packages
library(readxl)
library(ggpubr)
library(psych)
library(caret)
library(leaps)
library(MASS)
library(foreign)
library(Hmisc)
library(car)
library(lmtest)
library(corrplot)
library(broom)
library(tidyverse)

# Path to dataLemon file
exportdirxls <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\DataLemon.xlsx"

# Import data
Data <- data.frame(read_excel(exportdirxls, 1, col_names = TRUE))
row.names(Data) <- Data[,1]
Data <- Data[,-1]
Data <- Data[, c(1:8, 49:53, 59, 86:92)]
N = nrow(Data)

# Recoding of gender and age variables into Male/Female and Young/Old
for (i in 1:N) {
    if(Data[i,19] == 2){
        Data[i,19] <- "Male"
    } else {
        Data[i,19] <- "Female"
    }
}

for(j in 1:N) {
    if(Data[j,20] == "20-25"){
        Data[j, 20] <- "Young"
    } else if(Data[j,20] == "25-30"){
        Data[j,20] <- "Young"
    } else if(Data[j,20] == "30-35"){
        Data[j,20] <- "Young"
    } else {
        Data[j,20] <- "Old"
    }
}

Data[,19] <- factor(Data[,19]) 
Data[,20] <- factor(Data[,20]) 
na <- which(is.na(Data$Hamilton.Scale)) # find two missing values in Hamilton.Scale
Data <- Data[-na, ] # remove them
str(Data)

# Create separate datasets for each model
dataF2F1 <- Data[,-c(2:4)]
dataF4F3 <- Data[,-c(1, 3, 4)]
dataF6F5 <- Data[,-c(1,2, 4)]
dataF8F7 <- Data[,-c(1:3)]

## Run four OLF regression models, one for each electrode pair
summary(full.modelF2F1 <- lm(FAA.F2F1 ~ ., data = dataF2F1))
summary(full.modelF4F3 <- lm(FAA.F4F3 ~ ., data = dataF4F3))
summary(full.modelF6F5 <- lm(FAA.F6F5 ~ ., data = dataF6F5))
summary(full.modelF8F7 <- lm(FAA.F8F7 ~ ., data = dataF8F7))

## **Checking of Assumptions for Ordinary Least Squares (OLS) Regression**
### 1. Unusual Observations

#### 1.1 Outliers

opar <- par(mfrow = c(2,2))
plot(full.modelF2F1, las = 1) # subejcts 191, 246, 261 are possibly problematic
plot(full.modelF4F3, las = 1) # obs. 166, 274, 283 are possibly problematic
plot(full.modelF6F5, las = 1) # obs. 83, 91, 166 are possibly problematic
plot(full.modelF8F7, las = 1) # obs. 92, 166, 247 are possibly problematic
par(opar)

# Test for outliers
outlierTest(full.modelF2F1) # sub-010261
outlierTest(full.modelF4F3) # sub-010166
outlierTest(full.modelF6F5) # sub-010091
outlierTest(full.modelF8F7) # sub-010092

#### 1.2 Influential Observations
# Cook's distances. Cut-off point of 4/N
d1 <- cooks.distance(full.modelF2F1) # Cook's distance
d2 <- cooks.distance(full.modelF4F3)
d3 <- cooks.distance(full.modelF6F5)
d4 <- cooks.distance(full.modelF8F7)
r1 <- stdres(full.modelF2F1) # standardized residuals
r2 <- stdres(full.modelF4F3)
r3 <- stdres(full.modelF6F5)
r4 <- stdres(full.modelF8F7)
a1 <- cbind(dataF2F1, d1, r1)
a2 <- cbind(dataF4F3, d2, r2)
a3 <- cbind(dataF6F5, d3, r3)
a4 <- cbind(dataF8F7, d4, r4)
dcutoff1 <- a1[d1 > 4/N, ] # 12 INFLUENTIAL OBSERVATIONS
dcutoff2 <- a2[d2 > 4/N, ] # 17 INFLUENTIAL OBSERVATIONS
dcutoff3 <- a3[d3 > 4/N, ] # 15 INFLUENTIAL OBSERVATIONS
dcutoff4 <- a4[d4 > 4/N, ] # 17 INFLUENTIAL OBSERVATIONS

### 2. Residuals are Normaly Distributed
resid.modelF2F1 <- residuals(full.modelF2F1)
resid.modelF4F3 <- residuals(full.modelF4F3)
resid.modelF6F5 <- residuals(full.modelF6F5)
resid.modelF8F7 <- residuals(full.modelF8F7)

opar <- par(mfrow = c(2,2))
hist(resid.modelF2F1)
hist(resid.modelF4F3)
hist(resid.modelF6F5)
hist(resid.modelF8F7)

shapiro.test(resid.modelF2F1) # not normal - indicates assumption of multivariate normality may not hold
shapiro.test(resid.modelF4F3)
shapiro.test(resid.modelF6F5)
shapiro.test(resid.modelF8F7)
ad.test(resid.modelF2F1) # The Anderson - Darling test, which is generally considered better than
# Shaprio-Wilks, does not reject the null hypothesis of normally distributed residuals for any of the models
ad.test(resid.modelF4F3)
ad.test(resid.modelF6F5)
ad.test(resid.modelF8F7)

### 3. Homoscedasticity
opar <- par(mfrow = c(2,2))
plot(full.modelF2F1, las = 1) # subejcts 191, 246, 261 are possibly problematic
plot(full.modelF4F3, las = 1) # obs. 166, 274, 283 are possibly problematic
plot(full.modelF6F5, las = 1) # obs. 83, 91, 166 are possibly problematic
plot(full.modelF8F7, las = 1) # obs. 92, 166, 247 are possibly problematic
par(opar) # The plots do not look great

# Studentized Breusch-Pagan tests to test for heteroscedasticity.
bp1 <- bptest(full.modelF2F1, studentize = TRUE) # looks good
bp2 <- bptest(full.modelF4F3, studentize = TRUE) # looks good
bp3 <- bptest(full.modelF6F5, studentize = TRUE) # looks good
bp4 <- bptest(full.modelF8F7, studentize = TRUE) # looks good
# Assumption holds

### 4. Linear Relationship Between the Dependent Variable (FAA) and the Independent Variables

#### 5.3 Testing normality of single variables, for correlation
shapiro.test(Data[,1]) # Not normal (F2-F1)
shapiro.test(Data[,2]) # Not normal (F4-F3)
shapiro.test(Data[,3]) # Not normal (F6-F5)
shapiro.test(Data[,4]) # Normal (F8-F7)
shapiro.test(Data[,5]) # Not normal (BAS.Drive)
shapiro.test(Data[,6]) # Not normal (BAS.Fun)
shapiro.test(Data[,7]) # Not normal (BAS.Reward)
shapiro.test(Data[,8]) # Normal (BIS)
shapiro.test(Data[,9]) # Not normal (NEOFFI.Neuroticism)
shapiro.test(Data[,10]) # Normal (NEOFFI.Extraversion)
shapiro.test(Data[,11]) # Not normal (NEOFFI.OpennessForExperiences)
shapiro.test(Data[,12]) # Normal (NEOFFI.Agreeableness)
shapiro.test(Data[,13]) # Not normal (NEOFFI.Conscientiousness)
shapiro.test(Data[,14]) # Not normal (STAI.TRAIT.ANXIETY)
shapiro.test(Data[,15]) # Normal (UPPS.Urgency)
shapiro.test(Data[,16]) # Not normal (UPPS.Lack.Premeditation)
shapiro.test(Data[,17]) # Not normal (UPPS.Lack.Perseverance)
shapiro.test(Data[,18]) # Not normal (UPPS.Sens.Seek)
shapiro.test(Data[,21]) # Not normal (Hamilton.Scale)
# Mostly non-normal variables

#### 4.1 Matrices of Pearson and Spearman correlations

##### 4.1.1 Pearson
cor.data <- rcorr(as.matrix(Data[, - c(19:20)], type = "pearson"))
View(round(cor.data[["r"]], digits = 3))
View(round(cor.data[["P"]], digits = 3)) # p-values

##### 4.1.2 Spearman
cor.data.s <- rcorr(as.matrix(Data[, - c(19:20)], type = "spearman"))
View(round(cor.data.s[["r"]], digits = 3))
View(round(cor.data.s[["P"]], digits = 3))

plot(full.modelF2F1, 1)
plot(full.modelF4F3, 1)
plot(full.modelF6F5, 1)
plot(full.modelF8F7, 1)

#### 4.2 Correlation plot, with Pearson correlations above abs(0.15)
cont.data <- Data[, - c(19:20)]
corr_simple <- function(data=Data, sig=0.15){
    
    #run a correlation and drop the insignificant ones
    corr <- cor(cont.data)
    #prepare to drop duplicates and correlations of 1     
    corr[lower.tri(corr,diag=TRUE)] <- NA 
    #drop perfect correlations
    corr[corr == 1] <- NA 
    
    #turn into a 3-column table
    corr <- as.data.frame(as.table(corr))
    #remove the NA values from above 
    corr <- na.omit(corr) 
    
    #select significant values  
    corr <- subset(corr, abs(Freq) > sig) 
    #sort by highest correlation
    corr <- corr[order(-abs(corr$Freq)),] 
    
    #print table
    print(corr)
    
    #turn corr back into matrix in order to plot with corrplot
    mtx_corr <- reshape2::acast(corr, Var1~Var2, value.var="Freq")
    
    #plot correlations visually
    corrplot(mtx_corr, is.corr=FALSE, tl.col="black", na.label=" ")
}
corr_simple(cont.data)

### 5. No multicollinearity
#### 5.1 Variance Inflation Factor (VIF)
car::vif(full.modelF2F1)
car::vif(full.modelF4F3)
car::vif(full.modelF6F5)
car::vif(full.modelF8F7)


theme_set(theme_classic())
model.diag.metrics <- augment(full.modelF2F1)
head(model.diag.metrics)

# plot residuals (red) between observed values and fitted regression line.
ggplot(model.diag.metrics, aes(BAS.Drive, FAA.F2F1)) +
    geom_point() +
    stat_smooth(method = lm, se = FALSE) +
    geom_segment(aes(xend = BAS.Drive, yend = .fitted), color = "red", size = 0.3)