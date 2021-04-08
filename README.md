# Kaggle_HousePrice
The House Price competition from Kaggle

## Pre-analysis

### File descriptions
- train.csv - the training set
- test.csv - the test set
- data_description.txt - full description of each column, originally prepared by Dean De Cock but lightly edited to match the column names used here

### Data fields
See "data_description.txt" file for more details on the columns



## Analysis

### Step 1: Check the format of the dataset

#### 1.0 ID column

We remove the ID column from the training dataset. Shouldn't have any impact.


#### 1.1 Log transform target
We can see that the SalePrice column has a right tail. We will log the predictions to have a normal distributed target.


#### 1.2 Missing dataset
We note that 19 columns have missing data. By decreasing percentage of NA:

- PoolQC is pool quality, where NA means no pool. It is an ordered factor with 99% of NAs. It seems to have an impact on the sale price. We keep it
- Alley is the type of alley to the house. NA is not any alley. We keep it (93% NA) but change the factor to be "With" / "Without".
- Fence is the type of Fence. Na is no fence. We keep it (80% missing). It is an ordered factor but add "No" as a level in the factor
- FireplaceQu  is Fireplace quality, where NA means no fireplace.We keep it(47% NA). It is an ordered factor, add "No" as a level in the factor
- LotFrontage. Linear feet of street connected to property. We keep it, we fill with knn
- GarageXXX. Garage related data, where NA is no garage. We keep its. ordered factors, we fill with knn
- BsmtXXX. Basement related data, where NA is no basement. We keep it. ordered factors, we fill with knn
- Electrical. Only one missing value due to error, we fill with knn

We remove the colums MiscFeature, add another level for Alley, PoolQC, Fence and FireplaceQu and use knn_input to fill the other missing dataset.

We look at the Fence column, as it contains 2 details: the quality of privacy and quality of wood.



#### 1.3 Distribution of categorical values

By looking at the categorical variables, we see that 7 of them have a category that will take >95% of the rows. We remove them from the features, but only 1 has no impact on the Sale Price:  "Utilities".




#### 1.4 Distribution of numerical values

While looking at the distribution of numerical variables, we found that some variables should be in fact factors and not numerical variables.

Some of them can be removed because they have one of the variable that contains > 95% of the data and the impact on Sale price is small:

- 3SsnPorch
- BsmtHalfBath
- PoolArea
- KitchenAbvGr
- LowQualFinSF
- MiscVal



#### 1.5 Factor to numerical

Some of the columns that are factors could be seen as numerical: 

- all the "Cond" columns (Except SaleCondition and ConditionX), noting the condition of some aspect of a house
- all the "Qual" and "QC" columns, noting the quality of some aspect of a house
- BsmtExposure, BsmtFinType1 and BsmtFinType2 are specific columns that are similar




#### 1.6 Numerical to factor

Some of the columns that are numericals could be seen as factors instead:
- BsmtFullBath, Fireplaces, FullBath, and HalfBath will count some aspect of a house
- MoSold, YrSold will give details when the house has been sold.


#### 1.7 'Other' level for factors with levels that are "too low"

In all the factors except the one we talked about before this section, we create a new level "other" for all categories that have < 10% of data.

The full list is:

- MSZoning
- Street
- LotShape
- LandContour
- LotConfig
- LandSlope
- Neighborhood
- Condition1
- Condition2
- BldgType
- HouseStyle
- RoofStyle
- RoofMatl
- Exterior1st
- Exterior2nd
- MasVnrType
- Foundation
- BsmtCond
- Heating
- CentralAir
- Electrical
- Functional
- GarageType
- PavedDrive
- SaleType
- SaleCondition"


#### 1.8 Center and Scale the numerical values

We center and Scale the numerical values, except the output.
It will help with the columns with outliers




### Step 2: Pre-processing of the datasets

We pre-process the dataset following chapter 1 above, then create dummy variables from all the factors left.


### Step 3: XGBoost and workflow


### Step 4: Predicting on Test file

For future version, to add:

- step_ordinalscore() to replace ordered factors first, before the dummy step
- step_pca() for some pca
- step_novel(all_categories) in case we have new categories in the test file 
- step_interact( ~ x1:x2)  to add interactions


