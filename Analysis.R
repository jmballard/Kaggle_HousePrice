# 0 Libraries =================================================================

# 0.1 Import the libraries ----------------------------------------------------
library(tidyverse)
library(tidymodels)
library(data.table)
library(vip)
library(xgboost)

# avoid scientific notation
options(scipen=999)

# 0.2 Import datasets ---------------------------------------------------------

train <- fread("train.csv",
               stringsAsFactors = TRUE,
               data.table = FALSE)
test <- fread("test.csv",
              stringsAsFactors = TRUE,
              data.table = FALSE)

full <- rbind(train,
              test %>% mutate(SalePrice = as.numeric(NA)))


train <- full %>%
  filter(!is.na(SalePrice))

test <- full %>%
  filter(is.na(SalePrice))


# summary of the dataset
summary(train)

# 1 Check the dataset =========================================================

# 1.1 Distribution of output columm -------------------------------------------
# distribution before log-transform
ggplot(train) +
  geom_histogram(aes(SalePrice), bins = 50)

# distribution post log-transform
ggplot(train) +
  geom_histogram(aes(log(SalePrice)), bins = 50)

# 1.2 missing data ------------------------------------------------------------

nb_na <- apply(X =train,MARGIN = 2, function(x){sum(is.na(x))})
nb_na <- nb_na[nb_na>0] / nrow(train)
nb_na[order(nb_na)]


nb_na2 <- apply(X =test,MARGIN = 2, function(x){sum(is.na(x))})
nb_na2 <- nb_na2[nb_na2>0] / nrow(test)
nb_na2[order(nb_na2)]


# missing valutes in test that are not missing in train:
nb_na3 <- nb_na2[!names(nb_na2) %in% names(nb_na)]
nb_na3 <- nb_na3[names(nb_na3) != "SalePrice"]
nb_na3[order(nb_na3)]

ggplot(train %>%
         select(names(nb_na)) %>%
         select(order(nb_na)) %>%
         is.na() %>%
         reshape2::melt(),
       aes(Var2,Var1, fill = value)) +
  geom_raster() + 
  coord_flip() +
  scale_y_continuous(NULL, expand = c(0,0)) +
  scale_fill_grey(name = "",
                  labels = c("Present","Missing")) +
  xlab("Observations") 

# We look at the Fence column, as it contains 2 details: the quality of privacy and quality of wood. We keep
ggplot(train %>% 
         mutate(
           Fence = as.character(Fence),
           Fence = factor(case_when(!is.na(Fence) ~ Fence,
                                    TRUE ~ "No"),
                          levels = c(unique(Fence), "No")))) +
  geom_boxplot(aes(Fence, SalePrice))

# We remove the colums MiscFeature, add another level for Alley, PoolQc
# Fence and FireplaceQu and use knn_input to fill the other missing dataset.

# 1.3 Distribution of categorical variables -----------------------------------

factor_distrib <- train %>% 
  select_if(is.factor) %>%
  pivot_longer(cols = names(.),
               names_to = "column2",
               values_to = "values") %>%
  group_by(column2, values) %>%
  summarise(count = n()) %>%
  arrange(-count)

ggplot(factor_distrib) +
  geom_bar(aes(values, count),
           stat = "identity") +
  facet_wrap(~column2, scales = "free")


# factors with near zero variance but would be interesting to know more
caret::nearZeroVar(train, saveMetrics = TRUE) %>%
  rownames_to_column() %>%
  filter(nzv) %>%
  arrange(-freqRatio)

nzv_variables <- c("Utilities","LowQualFinSF" ,"RoofMatl",
                   "BsmtFinSF2", "Street"  ,"Condition2"  ,"ScreenPorch")

# Check the boxplot of the variables that have one variable with > 95% of the rows
train %>%
  select( factor_distrib %>% 
            filter(count > nrow(train) * 0.95) %>%
            .$column2,
          SalePrice) %>%
  pivot_longer(cols = c(-SalePrice),
               names_to = "Variable",
               values_to = "Category") %>%
  ggplot(.) + 
  geom_boxplot(aes(Category, SalePrice)) +
  facet_wrap(~Variable, scales = "free")

# we remove all the variables with near-zero variance


# 1.4 Distribution of numerical variables -------------------------------------

# check the histogram of each numerical variable

numeric_distrib <- train %>% 
  select_if(is.numeric) %>%
  pivot_longer(cols = names(.),
               names_to = "column2",
               values_to = "values") 

ggplot(numeric_distrib) +
  geom_histogram(aes(values), bins = 50) +
  facet_wrap(~column2, scales = "free")

# Look at the ones that could be removed:
numerical_interest <- c("3SsnPorch","PoolArea","BsmtHalfBath",
                        "KitchenAbvGr","MiscVal")

# boxplot against SalePrice
train %>%
  select(all_of(numerical_interest),"SalePrice") %>%
  pivot_longer(cols = -SalePrice,
               names_to = "Variable",
               values_to = "Values") %>%
  mutate(Values = as.factor(Values)) %>%
  ggplot(.) +
  geom_boxplot(aes(Values, SalePrice)) +
  facet_wrap(~Variable, scales = "free")

# Histogram of the values
train %>%
  select(all_of(numerical_interest),"SalePrice") %>%
  pivot_longer(cols = -SalePrice,
               names_to = "Variable",
               values_to = "Values") %>%
  ggplot(.) +
  geom_histogram(aes(Values)) +
  facet_wrap(~Variable, scales = "free")


# 1.5 Replace categorical by numerical columns --------------------------------

# ordered factors
train %>%
  select_if(is.factor) %>%
  select(contains("Qual"), contains("Cond"),contains("QC"),
         BsmtExposure,BsmtFinType1,BsmtFinType2,FireplaceQu) %>%
  select(-Condition1, -Condition2, -SaleCondition) %>%
  map(function(x){levels(x)})

cat_to_num <- c( "ExterQual","BsmtQual","KitchenQual","GarageQual",
                 "ExterCond","BsmtCond","GarageCond" ,"HeatingQC","PoolQC",
                 "BsmtExposure","BsmtFinType1","BsmtFinType2","FireplaceQu")


# example to see what happens after step_integer
prep(recipe(SalePrice ~ ., 
            data = train) %>%
       step_mutate(ExterQual_correct = order_qual(ExterQual)) %>%
       step_integer(ExterQual_correct), 
     training = train,
     retain = TRUE) %>%
  juice() %>% 
  select(ExterQual,ExterQual_correct) %>%
  group_by(ExterQual, ExterQual_correct) %>%
  summarise(count = n()) %>%
  arrange(ExterQual_correct) # Correct!

# 1.6 Replace numerical by categorical columns --------------------------------

num_to_cat1 <- c("BsmtFullBath", "Fireplaces","FullBath",
                 "HalfBath")
num_to_cat2 <- c( "MoSold")
num_to_cat3 <- c( "YrSold")

# summary(train$BsmtFinSF2)
# 
# ggplot(train %>% 
#          mutate(
#            BsmtFinSF2 = factor(case_when(BsmtFinSF2 == 0 ~ "No",
#                                     TRUE ~ "Yes"),
#                           levels = c("No", "Yes")))) +
#   geom_boxplot(aes(BsmtFinSF2, SalePrice))


# 1.7 Factor columns that have many small levels ------------------------------

factors_other <- c("MSZoning","LotShape","LandContour",
                   "LotConfig","LandSlope","Neighborhood" ,
                   "Condition1","BldgType","HouseStyle",
                   "RoofStyle","Exterior1st","Exterior2nd",
                   "MasVnrType", "Foundation","BsmtCond","Heating", "CentralAir",
                   "Electrical","Functional","GarageType","PavedDrive",
                   "SaleType","SaleCondition")

# We replace the small levels by "other"
prep(recipe(SalePrice ~ ., 
            data = train) %>%
       step_other(factors_other,
                  threshold = 0.1,
                  other = "other"), 
     training = train,
     retain = TRUE) %>%
  juice() %>% 
  select(factors_other) %>%
  pivot_longer(cols = names(.),
               names_to = "column2",
               values_to = "values") %>%
  group_by(column2, values) %>%
  summarise(count = n()) %>%
  arrange(-count)%>%
  ggplot(.) +
  geom_bar(aes(values, count),
           stat = "identity") +
  facet_wrap(~column2, scales = "free")


# 1.8 Center and Scale the numerical values -----------------------------------

prep(recipe(SalePrice ~ ., 
            data = train %>%
              select(-Id)) %>%
       step_center(all_numeric(), - all_outcomes()) %>% # to standardize the dataset
       step_scale(all_numeric(), -all_outcomes()), 
     training = train,
     retain = TRUE) %>%
  juice() %>%
  as.data.frame()%>%
  select_if(is.numeric) %>%
  pivot_longer(cols = names(.),
               names_to = "column2",
               values_to = "values")  %>%
  ggplot(.) +
  geom_histogram(aes(values), bins = 50) +
  facet_wrap(~column2, scales = "free")

# 2 Pre-processing ============================================================

order_qual <- function(x){
  factor(x,
         levels = c("No","Po","Fa","TA","Gd","Ex"))
}

# creation of recipe
myrecipe <- recipe(SalePrice ~ ., 
                   data = train %>%
                     select(-c(Id, # not needed in model
                               MiscFeature, # from missing data
                               all_of(nzv_variables), # from near-zero variance check
                               all_of(numerical_interest), # from numerical check
                     ))) %>%
  step_log(all_outcomes()) %>% # we log-transform it
  step_mutate(Alley = factor(case_when(!is.na(Alley) ~ "With",
                                       TRUE ~ "Without"),
                             levels = c("With","Without")),
              Fence = as.character(Fence),
              Fence = factor(case_when(!is.na(Fence) ~ Fence,
                                       TRUE ~ "No"),
                             levels = c(levels(full$Fence), "No")),
              PoolQC = as.character(PoolQC),
              PoolQC = factor(case_when(!is.na(PoolQC) ~ PoolQC,
                                        TRUE ~ "No"),
                              levels = c(levels(full$PoolQC), "No")),
              FireplaceQu = as.character(FireplaceQu),
              FireplaceQu = factor(case_when(!is.na(FireplaceQu) ~ FireplaceQu,
                                             TRUE ~ "No"),
                                   levels = c(levels(full$FireplaceQu), "No")),# first filling
              ExterQual = order_qual(ExterQual), # changing factors into numericals
              BsmtQual = order_qual(BsmtQual),
              KitchenQual = order_qual(KitchenQual),
              GarageQual = order_qual(GarageQual),
              ExterCond = order_qual(ExterCond),
              GarageCond = order_qual(GarageCond),
              HeatingQC = order_qual(HeatingQC),
              PoolQC = order_qual(PoolQC),
              FireplaceQu = order_qual(FireplaceQu),
              BsmtExposure = factor(BsmtExposure,
                                    levels = c("No","Mn","Av","Gd")),
              BsmtFinType1 = factor(BsmtFinType1,
                                    levels = c("No","Unf","LwQ","Rec",
                                               "BLQ","ALQ","GLQ")),
              BsmtFinType2 = factor(BsmtFinType2,
                                    levels = c("No","Unf","LwQ","Rec",
                                               "BLQ","ALQ","GLQ"))  ) %>%
  step_knnimpute(all_predictors())  %>% # we use knn to fill the missing dataset
  step_other(all_of(factors_other),
             threshold = 0.1,
             other = "other")  %>% # we add the "other" category for all small categories
  # step_num2factor(all_of(num_to_cat1),
  #                 transform = function(x) x+1, # Factor values can't be zero.
  #                 levels = as.character(0:4)) %>%
  step_num2factor(all_of(num_to_cat2),
                  levels = as.character(1:12)) %>%
  step_num2factor(all_of(num_to_cat3),
                  transform = function(x) x - 2005, # starts at 1.
                  levels = as.character(2006:2010)) %>%
  step_center(all_numeric(), - all_outcomes()) %>% # to standardize the dataset
  step_scale(all_numeric(), -all_outcomes()) %>%
  step_integer(all_of(cat_to_num))  %>% 
  # step_zv(all_predictors()) %>%
  step_dummy(all_nominal(),
             one_hot = TRUE) # replace all other categoricals by numericals with a one-hot encoder



# preparation of recipe
myprep <-  prep(myrecipe, 
                training = train,
                retain = TRUE)



# # cleaning the training dataset
# train_clean <- myprep %>%
#   juice()



# 3 Training Models ===========================================================


#Display currently available engines for xgboost
show_engines("boost_tree")

# initialisation of a xgboost
myxgb <- boost_tree( trees = 100, 
                     tree_depth = tune(),
                     min_n = tune()#, 
                     #loss_reduction = tune(), 
                     #learn_rate = tune()
                     )     %>%           
  set_engine("xgboost") %>% 
  set_mode("regression")


# initialisation of workflow
myworkflow <- workflow() %>%
  # add_recipe(myrecipe) %>%
  add_model(myxgb)%>% 
  add_formula(SalePrice ~ .)

# initialisation of CV
vb_folds <- myprep %>%
  juice() %>%
  vfold_cv(v = 10)

# initialisation of grid search
xgb_grid <- dials::grid_max_entropy( dials::parameters( tree_depth(),
                                                        min_n()#,
                                                        #loss_reduction(),
                                                        #learn_rate()  
                                                        ), 
                                     size = 60  )


# xgb_grid <- grid_latin_hypercube(
#   tree_depth(),
#   min_n(),
#   loss_reduction(),
#   sample_size = sample_prop(),
#   finalize(mtry(), vb_train),
#   learn_rate(),
#   size = 30
# )

# Notice that we had to treat mtry() differently because it depends on the actual number of predictors in the data.

# look at the head of the grid search
xgb_grid %>% 
  as.data.frame() %>%
  head()


# Do a grid search for hyper parametrisation
set.seed(234)
xgb_res <- tune_grid( myworkflow,
                      resamples = vb_folds,
                      grid = xgb_grid,
                      metrics = metric_set(rmse), #roc_auc
                      control = control_grid(save_pred = TRUE))

# plot the results by variable tuned
xgb_res %>%
  collect_metrics() %>%
  filter(.metric == "rmse") %>% # roc_auc
  select(mean, min_n:tree_depth) %>%
  pivot_longer(min_n:tree_depth,
               values_to = "value",
               names_to = "parameter"  ) %>%
  ggplot(aes(value, mean, color = parameter)) +
  geom_point(alpha = 0.8, show.legend = FALSE) +
  facet_wrap(~parameter, scales = "free_x") +
  theme_light()

# show the top 5 results average
show_best(xgb_res, "rmse")

best_xgb <- select_best(xgb_res, "rmse")

final_xgb <- finalize_workflow( myworkflow,
                                best_xgb)

# Feature importance
final_xgb %>%
  fit(data = train  ) %>% # %>% broom::tidy() # to get tidy tibble of coefficients
  pull_workflow_fit() %>%
  vip::vip(geom = "point")


# Let’s use last_fit() to fit our model one last time on the training data 
# and evaluate our model one last time on the testing set.
final_res <- last_fit(final_xgb, 
                      initial_split(train))

collect_metrics(final_res)

final_res %>%
  collect_predictions() %>%
  ggplot(aes(x = SalePrice,y = .pred)) +
  geom_point(col = "darkblue", alpha = 0.3) + 
  geom_abline( lty = 2, 
               alpha = 0.5,
               color = "gray50",
               size = 1.2  ) +
  theme_light()


# train the model
final_xgb <- final_xgb %>%
  fit(data = train  )


# # if ROC:
# final_res %>%
#   collect_predictions() %>%
#   roc_curve(win, .pred_win) %>%
#   ggplot(aes(x = 1 - specificity, y = sensitivity)) +
#   geom_line(size = 1.5, color = "midnightblue") +
#   geom_abline(
#     lty = 2, alpha = 0.5,
#     color = "gray50",
#     size = 1.2
#   )

# 4 Testing ===================================================================

# check that test and train have all the same levels
for(i in 1:ncol(train)){
  if(class(test[[i]]) != class(train[[i]])){
    stop(i," Not same class")
  }
  if(class(test[[i]]) == class(train[[i]]) &&
     class(test[[i]]) == "factor" &&
     (length(levels(test[[i]])) != length(levels(train[[i]])) ||
      levels(test[[i]]) != levels(train[[i]]))){
    stop(i," Not same levels")
  }
  
}

for(i in names(nb_na3)){
  if(class(test[,i])=="factor"){
    most_common <-  test %>% 
      group_by_at(i) %>% 
      summarise(n = n()) %>% 
      arrange(-n) %>%
      ungroup() %>% 
      as.data.frame()
    
    print(paste0(i, " - factor ",most_common[1,1],"-",most_common[1,2]))
    test[i][is.na(test[i])] <- most_common[1,1]
  }else{
    print(paste0(i, " - numeric ", round(mean(test[,i], na.rm = TRUE)) ))
    test[i][is.na(test[i])] <- round(mean(test[,i], na.rm = TRUE)) 
  }
}

test_clean <- myprep %>%
  bake(test)


test_prediction <- final_xgb %>%
  # use the training model fit to predict the test data
  predict(new_data = test)

fwrite(data.frame(Id = test$Id,
                  SalePrice = test_prediction$.pred),
       "Predictions1.csv")


