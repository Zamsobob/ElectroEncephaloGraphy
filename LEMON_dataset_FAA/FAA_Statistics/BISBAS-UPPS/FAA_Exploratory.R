#### OLS Regression FAA (F4-F3) ~ BIS/BAS-scores + UPPS-scores + Gender + Age
```{r}
# LOAD REQUIRED PACKAGES
library(readxl)
library(ggpubr)
library(psych)
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

# CREATE SEPARATE DATASETS FOR EACH MODEL (EACH DEPENDENT VARIABLE)
dataF2F1 <- Data[,-c(7:9)]
dataF4F3 <- Data[,-c(6, 8, 9)]
dataF6F5 <- Data[,-c(6,7, 9)]
dataF8F7 <- Data[,-c(6:8)]

# RUN FOUR OLS REGRESSION MODELS, ONE FOR EACH ELECTRODE PAIR. ONLY F4-F3 HERE
summary(full.modelF4F3 <- lm(FAA.F4F3 ~ BAS.Drive+BAS.Fun+BAS.Reward+BIS+UPPS.Urgency+UPPS.Lack.Premed+UPPS.Lack.Persev+UPPS.Sens.Seek+Gender+Age, data = dataF4F3))
```


## **Checking of Assumptions for Ordinary Least Squares (OLS) Regression**
### 1. Unusual Observations
Unusual observations may disproportionately influence the outcomes of the models.
Multiple linear regression is not very robust against these types of observations.

In  the  absence  of  outliers  and  with  the  fulfillment  of  the  assumptions  of  zero mean, constant variance and uncorrelated errors the OLS provides the Best Linear Unbiased Estimators (BLUE) of the regression parameters. But any anomalous point can disproportionately pull the line and distort the predictions. Detection of outlying observations is a very  essential  part  of  good  regression  analysis.

An influential observation is one which either individually or together with several other observations has a demonstrably larger impact on the calculated values of various estimates (coefficient, standard errors, t-values, etc.) than to the case for most of the other observation (Belsley et al., 1980).

#### 1.1 Outliers
An outlier is an observation with a large absolute residual. The plot on the top left shows three observations that are possible outliers. The Q-Q plot indicate decent normality of residuals.

<center>**MODEL 2 (F4-F3)**</center>
```{r}
par(mfrow = c(2,2))
plot(full.modelF4F3, las = 1) # obs. 100, 172, 180 are possibly problematic
```
```{r}
# TEST FOR OUTLIERS
outlierTest(full.modelF4F3) # OBS 100 IS AN OUTLIER
```
From the plots, observations 100, 172, 180 are possibly problematic.
Observation 100 is identified as an outlier in the outlier test.


#### 1.2 Influential Observations
Cook's Distance. Cut-off points of *4/n*. A measure that combines the information of leverage and the residual of the observation.
```{r}
d2 <- cooks.distance(full.modelF4F3) # COOK'A DISTANCE
r2 <- stdres(full.modelF4F3) # STANDARDIZED RESIDUALS
a2 <- cbind(dataF4F3, d2, r2)
a2[d2 > 4/N, ]
```

### 2. Residuals are Normaly Distributed
```{r}
resid.modelF4F3 <- residuals(full.modelF4F3)
hist(resid.modelF4F3)
```
```{r}
shapiro.test(resid.modelF4F3) # NOT NORMAL - INDICATES ASSUMPTION DOES NOT HOLD
```
The significant Shapiro-Wilks test indicates that the assumption of multivariate normality does not hold

### 3. Homoscedasticity
This assumption states that the variance of error terms are similar across the values of the independent variables.  A plot of standardized residuals versus predicted values can show whether points are equally distributed across all values of the independent variables.
```{r}
par(mfrow = c(2,2))
plot(full.modelF4F3, las = 1) # obs. 100, 172, 180 are possibly problematic
```
The plots of interest here are at the top-left and bottom-left. The top-left is the chart of residuals vs fitted values, while in the bottom-left one, it is standardised residuals on Y axis. If there is absolutely no heteroscedastity, there should be a completely random, equal distribution of points throughout the range of X axis and a flat red line. As previously seen, observations 100, 172, and 180 are possibly problematic, and the red line is not entirely flat. The Breush-Pagan test and the NCV test can be used to test for heteroscedasticity.

### 4. Linear Relationship Between the Dependent Variable (FAA) and the Independent Variables

#### 4.1 Matrices of Pearson and Spearman correlations
##### 4.1.1 Pearson
```{r}
# MATRICES OF PEARSON AND SPEARMAN CORRELATIONS (.r) AND THEIR P-VALUES (.p)
corrplot <- rcorr(as.matrix(Data[,-c(1, 14,15)]), type = "pearson")
round(corrplot[["r"]], digits = 3)
round(corrplot[["P"]], digits = 3)
```
##### 4.1.2 Spearman
```{r}
corrplot2 <- rcorr(as.matrix(Data[,-c(1, 14,15)]), type = "spearman")
round(corrplot2[["r"]], digits = 3)
round(corrplot2[["P"]], digits = 3)
```
### 5. No Multicollinearity
The correlation matrices show low correlations between the independent variables. Variance Inflation Factor (VIF) test shows the same, no collinearity (< 2.5 is very low).
```{r}
# VARIANCE INFLATION FACTOR (VIF)
car::vif(full.modelF4F3)
```

There are a couple of outliers and some influential observations. Several variables (not tested here) are non-normal, which does not matter for regression but for correlations. Residuals failed the Shapiro-Wilks test, despite the fact that the Q-Q plot did not look too bad. I am considering robust regression, which is based around down-weighting observations with large residuals.  


### References:
Belsley, D.A., Kuh. E and Welsch, R.E., Regression Diagnostics: Identifying Influential Data and Sources of Collinearity, Wiley, New York, (1980).

### Useful Links:
[Assumptions of Multiple Linear Regression](https://www.statisticssolutions.com/assumptions-of-multiple-linear-regression/)  
[Identifying Unusual Observations in R](https://towardsdatascience.com/how-to-detect-unusual-observations-on-your-regression-model-with-r-de0eaa38bc5b)  
[Robust Regression in R](https://stats.idre.ucla.edu/r/dae/robust-regression/)  
[Properites of OLS Estimates](https://www.albert.io/blog/ultimate-properties-of-ols-estimators-guide/)  
[Correlations in R](http://www.sthda.com/english/wiki/correlation-test-between-two-variables-in-r)  
