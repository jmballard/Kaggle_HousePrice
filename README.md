# Kaggle_HousePrice


## Table of contents

- [Motivations](#motivations)
- [Packages used](#packages_used)
- [Files](#files)

## Motivations and goals of this project <a name="motivations"></a>

As we all know in the UK, the price of living has been increasing a lot these past years. And rent is ever more expensive. Thus, buying a house could be seen as a good idea on the long term.

But buying a house is expensive, if not the most expensive thing you may have to buy in your live.

I have been looking at buying a house for the past months and I have seen that all the houses have very varying prices. I got then curious to look at what could possibly impact the price of a house.

In Kaggle, there is a competition relative to the price of houses. The data used for this competition is a modernized and expanded version of the Boston Housing dataset. Though not english, this dataset is complete enough that I'll use it for this analysis. It will give us an idea of which features in a house are having the most impact on its price.

1. Is having a basement having an impact on the price of a house?
2. Are the new build cheaper than older houses?
3. What are the most important features for our model?

We will use RMSE as feature to check the model's quality.

## Packages used <a name="packages_used"></a>

- pandas 
- numpy 
- matplotlib 
- seaborn
- pylab
- scipy
- sklearn
- xgboost


## Files <a name="files"></a>

This folder contains the following files important for the analysis:


Here is the content of this repo:

```text

- data
|- data_description.txt  # description of features
|- sample_submission.csv  # sample of Kaggle submission
|- train.csv  # train dataset
|- test.csv  # test dataset

- R analysis
|- EDA.Rmd # EDA done in R
|- Modelling.R # R modelling

- analysis_notebook.ipynb
- LICENSE
- README.md
- .gitignore

```


## Analysis description

### Step 0: Sourcing the files

We sourced the datasets and joined them together.


### Step 1: Exploring the output/target column

In that section, we looked at the distribution of target values, and then log-transformed it.


### Step 2: Missing values

In this section, we looked at all features having missing values and filled them with either specific values or a KNN imputer.

### Step 3: Change variable type

We needed to correct some numerical features that needed to be used as categorical ones.

### Step 4: Feature engineering

In this section, we created new features:

- total number of bathrooms
- house age
- remodeled flag
- is new flag
- total square feet

### Step 5: Outliers

We have found during our analysis that some profiles needed to be removed.

### Step 6: One-Hot Encoding

Due to us using a XGBoost model, we needed to transform all of our categorical features into dummy variables.


### Step 7: Modelling - XGBoost

The best xgb model is using :
- 'eta': 0.1, 
- 'gamma': 0.01, 
- 'max_depth': 5

min_n = 2 and tree_depth = 4. It has a RMSE of 0.0415.

The Highest feature in the feature importance check are, in order:

- TotalSquareFeet, which is the total amount of square feet area
- OverallQual, which is the variable on the Overall quality of the house
- Age, which is the age of the house when sold.


### Step 8: Answers to the questions

**Q1: Is having a basement having an impact on the price of a house?**

When looking at the list of important features above, we see that a Basement feature appears only at the bottom of the list, meaning that it doesn't seem to be seen as an important feature.

**Q2: Are the new build cheaper than older houses?**

When looking at the boxplots above, we see that the prices are higher on average for new houses

**Q3: What are the most important features for our model?**

When looking at the list of important features we see that the most important feature by far is the overall quality of a house, which makes sense. The better the house, the higher the price.

The next one is the total size of the house, which makes sense too as the bigger the house, the higher the price.


## Ideas of improvement

There are many things that we could have done for the pre-processing of our datasets:

- investigate a possible english dataset to see if we have similar features' impact. For example: are new built having the same impact in England with respect to what we have found here?
- Investigate the houses that had low price but very high square feet.
- We could keep the outliers but transform them in some way.
- We could do a PCA step to remove the multicolinearity instead of just removing columns.
- We could log transform the numerical predictors that are skewed by checking their skewness
- We could test other models

## Links

Kaggle competition: https://www.kaggle.com/competitions/house-prices-advanced-regression-techniques/overview

Medium article: https://medium.com/@bronnimannj/what-really-impacts-the-price-of-a-house-adf713e3ad2f