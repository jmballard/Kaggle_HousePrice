# Kaggle_HousePrice
The House Price competition from Kaggle

### File descriptions
- train.csv - the training set
- test.csv - the test set
- data_description.txt - full description of each column, originally prepared by Dean De Cock but lightly edited to match the column names used here

### Data fields
Here's a brief version of what you'll find in the data description file.

- SalePrice - the property's sale price in dollars. This is the target variable that you're trying to predict.
- MSSubClass: The building class
- MSZoning: The general zoning classification
- LotFrontage: Linear feet of street connected to property
- LotArea: Lot size in square feet
- Street: Type of road access
- Alley: Type of alley access
- LotShape: General shape of property
- LandContour: Flatness of the property
- Utilities: Type of utilities available
- LotConfig: Lot configuration
- LandSlope: Slope of property
- Neighborhood: Physical locations within Ames city limits
- Condition1: Proximity to main road or railroad
- Condition2: Proximity to main road or railroad (if a second is present)
- BldgType: Type of dwelling
- HouseStyle: Style of dwelling
- OverallQual: Overall material and finish quality
- OverallCond: Overall condition rating
- YearBuilt: Original construction date
- YearRemodAdd: Remodel date
- RoofStyle: Type of roof
- RoofMatl: Roof material
- Exterior1st: Exterior covering on house
- Exterior2nd: Exterior covering on house (if more than one material)
- MasVnrType: Masonry veneer type
- MasVnrArea: Masonry veneer area in square feet
- ExterQual: Exterior material quality
- ExterCond: Present condition of the material on the exterior
- Foundation: Type of foundation
- BsmtQual: Height of the basement
- BsmtCond: General condition of the basement
- BsmtExposure: Walkout or garden level basement walls
- BsmtFinType1: Quality of basement finished area
- BsmtFinSF1: Type 1 finished square feet
- BsmtFinType2: Quality of second finished area (if present)
- BsmtFinSF2: Type 2 finished square feet
- BsmtUnfSF: Unfinished square feet of basement area
- TotalBsmtSF: Total square feet of basement area
- Heating: Type of heating
- HeatingQC: Heating quality and condition
- CentralAir: Central air conditioning
- Electrical: Electrical system
- 1stFlrSF: First Floor square feet
- 2ndFlrSF: Second floor square feet
- LowQualFinSF: Low quality finished square feet (all floors)
- GrLivArea: Above grade (ground) living area square feet
- BsmtFullBath: Basement full bathrooms
- BsmtHalfBath: Basement half bathrooms
- FullBath: Full bathrooms above grade
- HalfBath: Half baths above grade
- Bedroom: Number of bedrooms above basement level
- Kitchen: Number of kitchens
- KitchenQual: Kitchen quality
- TotRmsAbvGrd: Total rooms above grade (does not include bathrooms)
- Functional: Home functionality rating
- Fireplaces: Number of fireplaces
- FireplaceQu: Fireplace quality
- GarageType: Garage location
- GarageYrBlt: Year garage was built
- GarageFinish: Interior finish of the garage
- GarageCars: Size of garage in car capacity
- GarageArea: Size of garage in square feet
- GarageQual: Garage quality
- GarageCond: Garage condition
- PavedDrive: Paved driveway
- WoodDeckSF: Wood deck area in square feet
- OpenPorchSF: Open porch area in square feet
- EnclosedPorch: Enclosed porch area in square feet
- 3SsnPorch: Three season porch area in square feet
- ScreenPorch: Screen porch area in square feet
- PoolArea: Pool area in square feet
- PoolQC: Pool quality
- Fence: Fence quality
- MiscFeature: Miscellaneous feature not covered in other categories
- MiscVal: $Value of miscellaneous feature
- MoSold: Month Sold
- YrSold: Year Sold
- SaleType: Type of sale
- SaleCondition: Condition of sale

## Analysis

### Step 1: Check the format of the dataset

We note that 19 columns have missing data. By decreasing percentage of NA:

- PoolQC is pool quality, where NA means no pool. We need to keep it even with 99% of NAs. It is an ordered factor
- MiscFeature is Misc features of the house, and is probably not interesting (96% NA)
- Alley is the type of alley to the house. NA is not any alley. We keep it (93% NA)
- Fence is the type of Fence. Na is no fence. We keep it (80% missing). It is an ordered factor
- FireplaceQu  is Fireplace quality, where NA means no fireplace.We keep it(47% NA). It is an ordered factor
- LotFrontage. Linear feet of street connected to property. Keep, replace NA by median.
- GarageXXX. Garage related data, where NA is no garage. Keep, replace NA with lower values. ordered factors
- BsmtXXX. Basement related data, where NA is no basement. Keep, replace NA with lower values. ordered factors
- BsmtExposure has 1 more missing value than the other Bsmt columns. May need to replace it
- MasVnrXXX. Masonry veneer related data, where NA is no Masonry veneer. Keep, replace NA with lower values. ordered factors
- Electrical. Only one missing value, replacing it with "SBrkr" as it's the most common value.

On top of that, we have:
- Street has 6/1460 Gravel and the rest Pavement. May not be useful, but after looking at the boxplot we see that it may be a good idea to keep it for now.
- Utilities has 1/1460 NoSeWa, the rest AllPub. Not useful, we remove it.
- MasVnrArea and BsmtFinSF1 have some outliers
- BsmtFinSF2 and LowQualFinSF have nearly only 0's. May not be useful. We will remove them.


Finally, some numerical variables may be a good idea to transform into categories, and inversely for some categories.

We will remove the following columns: Utilities, LandSlope, Fence, and MiscFeature,BsmtFinSF2,LowQualFinSF


### Step 2: Pre-processing of the datasets