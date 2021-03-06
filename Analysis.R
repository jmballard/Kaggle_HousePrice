# 0 Libraries =================================================================

# 0.1 Import the libraries ----------------------------------------------------
library(tidyverse)
library(tidymodels)
library(data.table)


# 0.2 Import datasets ---------------------------------------------------------

train <- fread("train.csv",
               stringsAsFactors = TRUE,
               data.table = FALSE)
test <- fread("test.csv",
               stringsAsFactors = TRUE,
              data.table = FALSE)


# 1 Check the dataset =========================================================

# 1.1 missing data ------------------------------------------------------------
nb_na <- apply(X =train,MARGIN = 2, FUN = function(x){sum(is.na(x))})
nb_na <- nb_na[nb_na>0] / nrow(train)
nb_na <- nb_na[order(nb_na)]

# 1.2 summaries ---------------------------------------------------------------
summary(train)


# 1.3 histogram distributions for some strange ones ---------------------------

ggplot(train) + geom_histogram(aes(MasVnrArea)) # outliers
ggplot(train) + geom_histogram(aes(BsmtFinSF1)) # outliers
ggplot(train) + geom_histogram(aes(LowQualFinSF)) # remove
ggplot(train) + geom_histogram(aes(BsmtFinSF2)) # outliers, or remove:
ggplot(train) + geom_point(aes(BsmtFinSF2,SalePrice)) # outliers


ggplot(train) + geom_boxplot(aes(Street, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(Alley, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(LandContour, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(Condition2, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(RoofMatl, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(ExterCond, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(BsmtCond, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(Heating, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(CentralAir, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(PavedDrive, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(PoolQC, SalePrice)) # keep
ggplot(train) + geom_boxplot(aes(SaleType, SalePrice)) # keep

ggplot(train) + geom_boxplot(aes(Utilities, SalePrice)) # remove
ggplot(train) + geom_boxplot(aes(LandSlope, SalePrice)) # remove
ggplot(train) + geom_boxplot(aes(Fence, SalePrice)) # remove
ggplot(train) + geom_boxplot(aes(MiscFeature, SalePrice)) # remove



# 1.4 remove the columns we think will be useless -----------------------------

train <- train %>%
  select(-c(Utilities,LandSlope,Fence,MiscFeature,LowQualFinSF,BsmtFinSF2))
test <- test %>%
  select(-c(Utilities,LandSlope,Fence,MiscFeature,LowQualFinSF,BsmtFinSF2))

# 1.5 remove outliers ---------------------------------------------------------

train <- train %>%
  filter(is.na(MasVnrArea) | 
           MasVnrArea <= quantile(MasVnrArea,0.995, na.rm = TRUE) ,
         BsmtFinSF1 <= quantile(BsmtFinSF1,0.995, na.rm = TRUE),
         BsmtFinSF2 <= quantile(BsmtFinSF2,0.995, na.rm = TRUE)  )

# removed 23 rows, aka 1.5% of the dataset

# 2 Pre-processing ============================================================






# 3 Training Models ===========================================================






# 4 Testing ===================================================================