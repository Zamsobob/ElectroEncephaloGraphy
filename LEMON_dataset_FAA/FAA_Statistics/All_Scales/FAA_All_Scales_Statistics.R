# LOAD REQUIRED PACKAGES
library(readxl)
library(minerva)

# PATH TO DATA FILE
exportdirxls <- "D:\\MPI_LEMON\\EEG_MPILMBB_LEMON\\EEG_Statistics\\DataLemon.xlsx"

Data <- data.frame(read_excel(exportdirxls, 1, col_names = TRUE))
row.names(Data) <- Data[,1]
Data <- Data[,-1]
N = nrow(Data)

# RECODING OF GENDER AND AGE TO INDICATOR/DUMMY (0/1) VARIABLES
# THE INTERCEPT WILL BE THE ESTIMATED Y-VALUE FOR THE REFERENCE GROUP (AGE AND GENDER EQUAL TO 0)
for (i in 1:N) {
    if(Data[i,90] == 2){
        Data[i,90] <- 0
    }
}

for(j in 1:N) {
    if(Data[j,91] == "20-25"){
        Data[j, 91] <- 1
    } else if(Data[j,91] == "25-30"){
        Data[j,91] <- 1
    } else if(Data[j,91] == "30-35"){
        Data[j,91] <- 1
    } else {
        Data[j,91] <- 0
    }
}

Data[,90] <- factor(Data[,90]) # FOR GENDER, 1 = FEMALE, 0 = MALE
Data[,91] <- factor(Data[,91]) # FOR AGE, 1 = YOUNG, 0 = OLD
