## STATISTICAL ANALYSIS OF FRONTAL ALPHA ASYMMETRY (FAA) DATA - CORRELATIONS

# Load required packages
library(readxl)
library(ggpubr)
library(corrplot)

# Path to dataLemon file
exportdirxls <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\DataLemon.xlsx"

# Import data
Data <- data.frame(read_excel(exportdirxls, 1, col_names = TRUE))
row.names(Data) <- Data[,1]
Data <- Data[,-1]
Data <- Data[, c(1:8, 49:53, 59, 86:93)]
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

# Recoding SKID Diagnoses variable into categorical with 3 levels (none, current, past diagnosis)
Data$SKID.Diagnoses[grepl("past", Data$SKID.Diagnoses)] <- "past"
Data$SKID.Diagnoses[grepl("current", Data$SKID.Diagnoses)] <- "current"
Data$SKID.Diagnoses[grepl("T74.1", Data$SKID.Diagnoses)] <- "past"
Data$SKID.Diagnoses[grepl("alcohol", Data$SKID.Diagnoses)] <- "current"
Data$SKID.Diagnoses[grepl("specific", Data$SKID.Diagnoses)] <- "current"

Data[,19] <- factor(Data[,19]) 
Data[,20] <- factor(Data[,20])
Data[,21] <- factor(Data[,21])
attach(Data)
str(Data)

#### Testing normality of single variables
shapiro.test(FAA.F2F1) # Not normal  (F2-F1)
shapiro.test(FAA.F4F3) # Not normal  (F4-F3)
shapiro.test(FAA.F6F5) # Not normal  (F6-F5)
shapiro.test(FAA.F8F7) # Normal      (F8-F7)
shapiro.test(BAS.Drive) # Not normal  (BAS.Drive)
shapiro.test(BAS.Fun) # Not normal  (BAS.Fun)
shapiro.test(BAS.Reward) # Not normal  (BAS.Reward)
shapiro.test(BIS) # Normal      (BIS)
shapiro.test(NEOFFI.Neuroticism) # Not normal  (NEOFFI.Neuroticism)
shapiro.test(NEOFFI.Extraversion) # Normal     (NEOFFI.Extraversion)
shapiro.test(NEOFFI.OpennessForExperiences) # Not normal (NEOFFI.OpennessForExperiences)
shapiro.test(NEOFFI.Agreeableness) # Normal     (NEOFFI.Agreeableness)
shapiro.test(NEOFFI.Conscientiousness) # Not normal (NEOFFI.Conscientiousness)
shapiro.test(STAI.TRAIT.ANXIETY) # Not normal (STAI.TRAIT.ANXIETY)
shapiro.test(UPPS.urgency) # Normal     (UPPS.Urgency)
shapiro.test(UPPS.lack.premeditation) # Not normal (UPPS.Lack.Premeditation)
shapiro.test(UPPS.lack.perseverance) # Not normal (UPPS.Lack.Perseverance)
shapiro.test(UPPS.sens.seek) # Not normal (UPPS.Sens.Seek)
shapiro.test(Hamilton.Scale) # Not normal (Hamilton.Scale)
# Mostly non-normal variables

##### Scatter plots of the different frontal alpha asymmetry (FAA) scores. Spearman's rho
ggscatter(Data, x = "FAA.F2F1", y = c("FAA.F4F3","FAA.F6F5","FAA.F8F7"), combine = TRUE, 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "spearman",
          xlab = "FAA (F2-F1)")

ggscatter(Data, x = "FAA.F4F3", y = c("FAA.F6F5","FAA.F8F7"), combine = TRUE, 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "spearman",
          xlab = "FAA (F4-F3)")

ggscatter(Data, x = "FAA.F8F7", y = "FAA.F6F5", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "spearman",
          xlab = "FAA (F8-F7)", ylab = "FAA (F6-F5)")

#### Matrices of Pearson and Spearman correlations

##### Pearson
cor.data <- corr.test(Data[, - c(19:21)],y = NULL, method="pearson",
                        adjust="fdr", alpha=0.05, minlength=10)
View(cor.data)

##### Spearman
cor.data.s <- corr.test(Data[, - c(19:21)],y = NULL, method="spearman",
                      adjust="fdr", alpha=0.05, minlength=10)
View(cor.data.s)

##### Construct matrix of FDR corrected p-values
###### Spearman's rho
cor.s.p.adj <- matrix(ncol = ncol(cor.s.p), nrow = nrow(cor.s.p))
for(i in 1:ncol(cor.s.p)){
    cor.s.p.adj[,i] <- p.adjust(cor.s.p[,i], method = "fdr")
}
colnames(cor.s.p.adj) <- colnames(cor.data.s$r)
row.names(cor.s.p.adj) <- colnames(cor.data.s$r)
View(round(cor.s.p.adj, 3))

#### Correlation plot, with Pearson correlations above abs(0.15)
cont.data <- Data[, - c(19:21)]
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

    
# END OF SCRIPT
