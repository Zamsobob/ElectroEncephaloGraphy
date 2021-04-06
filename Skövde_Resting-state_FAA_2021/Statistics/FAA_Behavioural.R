# BEST PRACTISE PREPARING DATA FOR R. DO IT ON SCHOOL LOG IN IF I NEED EXCEL.

## LAPLACIAN TRANSFORMED DATA

# LOAD REQUIRE PACKAGES
library(readxl)
library(dplyr)
# if(!require(devtools)) install.packages("devtools")
# devtools::install_github("kassambara/ggpubr")
# install.packages("ggpubr")
# library(ggpubr)

# IMPORT EO FRONTAL ASYMMETRY SCORES
exceldirBIS <- "D:/FAA_Study_2021/Skovde/Skovde_EEG/EEG_Statistics/Behavioural_Data.xls"
behavioural <- read_excel(exceldirBIS, 1, col_names = TRUE);
behavioural <- as.matrix(behavioural)

# SET COLUMN NAMES FOR EASE OF VIEWING
#row.names(behavioural) <- c("sub-002","sub-005", "sub-006", "sub-008", "sub-009", "sub-011", "sub-013", 
#                      "sub-014", "sub-015", "sub-019", "sub-020", "sub-021", "sub-022", "sub-025",
#                      "sub-027", "sub-028", "sub-029", "sub-030", "sub-031", "sub-032")

View(behavioural)


#---------------------------
## IMPORT EC FRONTAL ASYMMETRY SCORES
