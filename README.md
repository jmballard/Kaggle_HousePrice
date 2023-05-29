# Kaggle_HousePrice


## Table of contents

- [Motivations](#motivations)
- [Packages used](#packages_used)
- [Files](#files)
- [Analysis summary](#analysis)
- [Results](#results)
- [Comparison](#comparison)
- [Improvement ideas](#improvement)
- [Links](#links)
- [License](#license)
- [Status](#status)

## Motivations and goals of this project <a name="motivations"></a>

### High-level overview

As we all know in the UK, the price of living has been increasing a lot these past years. And rent is ever more expensive. Thus, buying a house could be seen as a good idea on the long term.

But buying a house is expensive, if not the most expensive thing you may have to buy in your live.

I have been looking at buying a house for the past months and I have seen that all the houses have very varying prices. I got then curious to look at what could possibly impact the price of a house.

### Description of input data

In Kaggle, there is a competition relative to the price of houses. The data used for this competition is a modernized and expanded version of the Boston Housing dataset. Though not english, this dataset is complete enough that I'll use it for this analysis. It will give us an idea of which features in a house are having the most impact on its price.

The data is comprised of two csvs: train and test. The latter does not contain SalePrices, and will be used in the Kaggle competition to test the quality of our model

### Strategy for solving the problem

The two main files from Kaggle are separated. We will concatenate them to make sure we have a full view on the data and its feature's distribution.

We will first do some EDA and Data preprocessing, as the data hasn't been cleaned. Due to the target having a right tail, we will log transform it.

- During the data pre-processing, we will:
- Fill the missing values either manually or with a KNN imputer
- Remove outliers
- Create new features
- Use a One-Hot Encoder to encode the categorical features.

Once done, we will use a XGBoost model to predict the Sale Price with a GridSearchCV to tune the parameters of the model.

The model, in particular, that I have chosen is a XGBRegressor as the target is numerical (SalePrice). The objective parameter of the XGB will stay the default (reg:squarederror)

### Expected solution

We expect the model to predict the SalePrice, with some features to be clearly seen as important:

For example, the quality of the house, its size, the area where the house is placed or the age of the house should be seen as

### Metrics used

As the target is numerical, we will use a regressor model with RMSE as our internal model.

The final measure used to see the quality of our model will be the one used in Kaggle to rank their competitors.

## Packages used <a name="packages_used"></a>

- pandas 
- numpy 
- matplotlib 
- seaborn
- pylab
- scipy
- sklearn
- xgboost
- interpret (for the EBM)


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
- submission_tuned.csv
- submission_xgb.csv
- LICENSE
- README.md
- .gitignore

```


## Analysis description <a name="analysis"></a>

### Step 0: Sourcing the files

We sourced the datasets and joined them together.


### Step 1: EDA

In that section, we looked in more details at the data and its columns. In particular, we looked at the distribution of target values, and then log-transformed it.


### Step 2: Data Preprocessing

In this section, we 

- looked at all features having missing values and filled them with either specific values or a KNN imputer.
- corrected some numerical features that needed to be used as categorical ones.
- created new features
- removed outliers
- used an One-Hot-Encoding method to encode the categorical features into dummy variables.


### Step 3: Modelling - XGBoost

Let's start by separating the training dataset from the test dataset. Once we have done that, we separate the train into 2 parts: the one that will be used for training and the one for validation. The validation dataset will contain 20% of the original train.csv file.

As said in the beginning of this article, we are using a XGBoost model to try to predict our SalePrice target. The objective will stay the default using squared loss.

When running a first XGBoost model, we got an RMSE on the validation sample of 1.13914. When submitting the results on Kaggle, we got a score of 0.14274. Let's see if we can improve on that with some tuning.

### Step 4 : Hyper parameter tuning

We will tune the following parameters with a GridSearchCV function:
- eta
- gamma
- max_depth

We create a XGBoost model with a GridSearch to tune the parameters eta, gamma and max_depth.

The best parameters are:
- eta: 0.1
- gamma: 0
- max_depth: 5

## Results <a name="results"></a>

The RMSE of the tuned model is 1.1379.

When submitting the model predictions to Kaggle, I got a score of 0.13647, which was better than what we had before.

The Highest feature in the feature importance check are, in order:

- TotalSquareFeet, which is the total amount of square feet area
- OverallQual, which is the variable on the Overall quality of the house
- Age, which is the age of the house when sold.

## Comparison table <a name="comparison"></a>

We got the following results from our models

| Model  | RMSE in validation | Kaggle score | Kaggle rank |
| ------------- | ------------- | ------------- | ------------- |
| Baseline  | 1.139143  | 0.14274 | 2053 |
| Tuned  | 1.137923  | 0.13647 | 1597 |

The tuned model that we created above seems to improve on our baseline model. With it, our leaderboard ranking in Kaggle jumped from 2053 to 1597.

While not perfect, this is already a good starting point for improvement.


## Ideas of improvement <a name="improvement"></a>

There are many things that we could have done for the pre-processing of our datasets:

- investigate a possible english dataset to see if we have similar features' impact. For example: are new built having the same impact in England with respect to what we have found here?
- Investigate the houses that had low price but very high square feet.
- We could keep the outliers but transform them in some way.
- We could do a PCA step to remove the multicolinearity instead of just removing columns.
- We could log transform the numerical predictors that are skewed by checking their skewness
- We could test other models

## Links <a name="links"></a>

Kaggle competition: https://www.kaggle.com/competitions/house-prices-advanced-regression-techniques/overview

Medium article: https://medium.com/@bronnimannj/what-really-impacts-the-price-of-a-house-adf713e3ad2f

EBM documentation: https://interpret.ml/docs/ebm.html

## License <a name="license"></a>

MIT License

Copyright (c) [2022] [Julie Ballard]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Project status  <a name="status"></a>

This project is finishes