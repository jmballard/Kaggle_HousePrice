# Kaggle_HousePrice

The House Price competition from Kaggle

## Folder's description

This folder contains the following files important for the analysis:

- train.csv - the training set
- test.csv - the test set
- data_description.txt - full description of each column, originally prepared by Dean De Cock but lightly edited to match the column names used here
- Modelling.R - the file containing the preprocessing and modelling code.
- EDA.Rmd - Exploratory analysis code explaining all the process behind the preprocessing and modelling done in the Modelling.R file.

On top of these files we have:

- .gitignore - for the git commit
- .Rhistory - to keep memory of the R code that ran
- Kaggle_HousePrice.Rproj - the R project
- workspace.code-workspace - to use with VScode


## Analysis description

### Step 1: Descriptive analysis and pre-processing

Use the EDA file to do all the research behind the pre-processing.

We pre-process the dataset following the analysis, then create dummy variables from all the factors left. We split the full dataset into the training and testing datasets depending if they contain a value for SalePrice or not.



### Step 2: XGBoost and elastic net

We create a function "model" which takes a workflow, a cv, a set of parameters to tune, a size for CV and a set of metrics to:

1. Tune the hyper parameters
2. Plot the average metrics by parameters
3. Select the best model, update the workflow
4. plot the feature importance
5. Train the final model
6. Predict on the training dataset, calculate the rmse and plot the predictions against real values

#### 2.1 XGB model

The best xgb model is using min_n = 2 and tree_depth = 4. It has a rmse of 0.0415.

The Highest feature in the feature importance check are, in order:

- TotalSquareFeet, which is the total amount of square feet area
- OverallQual, which is the variable on the Overall quality of the house
- Age, which is the age of the house when sold.


#### 2.2 Elastic net

The best elastic net model is using penalty = 0.00260417970747938 and mixture = 0.987178097013384. It has a rmse of 0.1064.

The Highest feature in the feature importance check are, in order:

- Exterior1st
- TotalSquareFeet
- Neighborhood


### Step 3: Predicting on Test file
We predict the prices using the XGB model, the Elastic Net model and an ensemble model averaging the results.

The Score from Kaggle is 0.13330 of RMSE on the log(SalePrice) for the XGB model, 0.13400 for the Elastic net model and 0.12888 for the ensemble model without giving any weight difference between the 2 models.

I ranked on the top third around 3247, which is better than before (3700) but it can be improved!




## Ideas of improvement

There are many things that we could have done for the pre-processing of our datasets:

- We could use step_spatialsign instead of removing the 2 rows of outliers.
- We could use the step_nzv function instead of how it was done. We didnt, here, because it seems that it was removing good columns.
- We could do a PCA step to remove the multicolinearity instead of just removing columns.
- We could log transform the numerical predictors that are skewed by checking their skewness
- We could step_ordinalscore() to replace ordered factors first, before the dummy step
- We could step_interact( ~ x1:x2)  to add interactions
- We could test other models

