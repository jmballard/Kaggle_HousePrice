# 0 Libraries =================================================================

# 0.1 Import the libraries ----------------------------------------------------
library(tidyverse)
library(tidymodels)
library(rlang)
library(vctrs)
library(data.table)
library(ggpubr)
library(ggrepel)
library(grid)
library(gridExtra)
library(vip)
library(xgboost)



# avoid scientific notation
options(scipen=999)

# 0.2 Import datasets ---------------------------------------------------------

full <- rbind(read_csv("train.csv"),
              read_csv("test.csv") %>% 
                mutate(SalePrice = as.numeric(NA))) %>%
  mutate_if(is.character,function(x){factor(x)}) %>%
  mutate_if(is.integer,function(x){as.numeric(x)})


# 1 Pre Processing ============================================================

# 1.0 Start recipe ------------------------------------------------------------
myrecipe <- recipe(SalePrice ~ ., 
                   data = full )


# 1.1 Output variable log transformed -----------------------------------------

myrecipe <- myrecipe %>%
  step_log(all_outcomes())


# 1.2 missing data ------------------------------------------------------------

add_no <- function(x, Id_skip = 9999){
  x = as.character(x)
  factor(case_when(is.na(x) & !full$Id %in% Id_skip ~ "No",
                   TRUE ~ x),
         levels = unique(c(unique(x), "No")))
}

myrecipe <- myrecipe %>%
  step_mutate( PoolQC = as.character(PoolQC),
               Overal_fac = case_when(OverallQual <= 2 ~ "Po",
                                      OverallQual <= 4 ~ "Fa",
                                      OverallQual <= 6 ~ "TA",
                                      OverallQual <= 8 ~ "Gd",
                                      TRUE ~ "Ex"),
               PoolQC = factor(case_when(is.na(PoolQC) &
                                           PoolArea > 0 ~ Overal_fac,
                                         !is.na(PoolQC) |
                                           PoolArea > 0 ~ PoolQC,
                                         TRUE ~ "No"))) %>%
  step_rm(Overal_fac) %>%
  step_mutate_at(all_of(c("MiscFeature", "Alley", "Fence",
                          "FireplaceQu")),
                 fn = add_no) %>%
  step_mutate(GarageType = as.character(GarageType),
              GarageType = case_when(is.na(GarageArea) ~ as.character(NA),
                                     TRUE ~ GarageType),
              GarageType = factor(GarageType),
              GarageArea = case_when(is.na(GarageArea) ~ 0,
                                     TRUE ~ GarageArea),
              GarageCars = case_when(is.na(GarageCars) ~ 0,
                                     TRUE ~ GarageCars)) %>%
  step_mutate( GarageYrBlt = case_when(is.na(GarageYrBlt) & Id != 2127 ~ YearBuilt,
                                       TRUE ~ GarageYrBlt),
               GarageType = add_no(GarageType,Id_skip = 2127),
               GarageFinish = add_no(GarageFinish,Id_skip = 2127),
               GarageQual = add_no(GarageQual,Id_skip = 2127),
               GarageCond = add_no(GarageCond,Id_skip = 2127),
               BsmtFinSF1 = case_when(is.na(BsmtFinSF1) ~ 0,
                                      TRUE ~ BsmtFinSF1),
               BsmtFinSF2 = case_when(is.na(BsmtFinSF2) ~ 0,
                                      TRUE ~ BsmtFinSF2),
               BsmtUnfSF = case_when(is.na(BsmtUnfSF) ~ 0,
                                     TRUE ~ BsmtUnfSF),
               TotalBsmtSF = case_when(is.na(TotalBsmtSF) ~ 0,
                                       TRUE ~ TotalBsmtSF),
               BsmtFullBath = case_when(is.na(BsmtFullBath) ~ 0,
                                        TRUE ~ BsmtFullBath),
               BsmtHalfBath = case_when(is.na(BsmtHalfBath) ~ 0,
                                        TRUE ~ BsmtHalfBath),
               BsmtCond = as.character(BsmtCond),
               BsmtQual = as.character(BsmtQual),
               BsmtCond = case_when(is.na(BsmtCond) & !is.na(BsmtQual) ~ BsmtQual,
                                    TRUE ~ BsmtCond),
               BsmtQual = add_no(BsmtQual),
               BsmtCond = add_no(BsmtCond),
               BsmtFinType1 = add_no(BsmtFinType1),
               BsmtFinType2 = add_no(BsmtFinType2),
               BsmtExposure = as.character(BsmtExposure),
               BsmtExposure = factor(case_when(is.na(BsmtExposure) & BsmtQual != "No"  ~ "Av",
                                               BsmtQual == "No" ~ "None",
                                               TRUE ~ BsmtExposure)),
               MasVnrType = as.character(MasVnrType),
               MasVnrType = factor(case_when(is.na(MasVnrArea) ~ "None",
                                             TRUE ~ MasVnrType)),
               MasVnrArea = case_when(is.na(MasVnrArea) ~ 0,
                                      TRUE ~ MasVnrArea)   )%>%
  step_knnimpute(all_predictors()) %>%
  step_mutate(PoolArea = case_when(PoolQC == "No" ~ 0,
                                   TRUE ~ PoolArea))


# 1.3 Change of variable types ------------------------------------------------

# 1.3.1 Categorical into numerical

order_qual <- function(x){
  factor(x,
         levels = c("No","Po","Fa","TA","Gd","Ex"))
}

cat_to_num <- c("ExterQual","KitchenQual",
                "GarageQual","ExterCond","BsmtQual","BsmtCond",
                "GarageCond" ,"HeatingQC","PoolQC","FireplaceQu")

myrecipe <- myrecipe %>%
  step_mutate( LotShape = factor(LotShape,
                                 levels = c("Reg","IR1","IR2","IR3")),
               BsmtExposure = factor(BsmtExposure,
                                     levels = c("Gd","Av","Mn","No","None")),
               BsmtFinType1 = factor(BsmtFinType1,
                                     levels = c("No","Unf","LwQ","Rec",
                                                "BLQ","ALQ","GLQ")),
               BsmtFinType2 = factor(BsmtFinType2,
                                     levels = c("No","Unf","LwQ","Rec",
                                                "BLQ","ALQ","GLQ")),
               GarageFinish = factor(GarageFinish,
                                     levels = c("No","Unf","RFn","Fin")),
               PavedDrive = factor(PavedDrive,
                                   levels = c("N","P","Y"))) %>%
  step_mutate_at(all_of(cat_to_num),
                 fn = order_qual) %>%
  step_integer(all_of(cat_to_num))  %>% 
  step_mutate(Functional = as.character(Functional),
              Functional = case_when(Functional %in% c("Min1","Min2", "Mod") ~ "Min",
                                     Functional == "Typ" ~ "Typ",
                                     TRUE ~ "Maj"),
              Functional = factor(Functional,
                                  levels = c("Typ","Min","Maj")))



# 1.3.2 numerical into Categorical

myrecipe <- myrecipe %>%
  step_mutate(MSSubClass = factor(MSSubClass,
                                  levels = unique(MSSubClass))) %>%
  step_num2factor(MoSold,
                  levels = as.character(1:12)) %>%
  step_num2factor(YrSold,
                  transform = function(x) x - 2005, # starts at 1.
                  levels = as.character(2006:2010))



# 1.4 Feature engineering -----------------------------------------------------

cat_other <- c("MSZoning","LotShape","LandContour","LotConfig",
               "LandSlope","Condition1","Condition2","BldgType",
               "HouseStyle","RoofStyle","RoofMatl","MasVnrType",
               "Foundation","BsmtExposure","BsmtFinType1","BsmtFinType2",
               "Heating","Electrical","Functional","GarageFinish",
               "PavedDrive","MoSold","SaleType","SaleCondition")

myrecipe <- myrecipe %>%
  step_mutate(TotalBathrooms = BsmtFullBath + FullBath + 0.5 * ( BsmtHalfBath +HalfBath) ) %>%
  step_mutate(Age = as.numeric(as.character(YrSold)) - YearBuilt,
              Remodeled = factor(case_when(YearRemodAdd == YearBuilt ~ "Y",
                                           TRUE ~ "N")),
              New = factor(case_when(Age < 2 ~ "Y",
                                     TRUE ~ "N"))) %>%
  step_mutate(PorchArea = WoodDeckSF + OpenPorchSF + EnclosedPorch + `3SsnPorch` + ScreenPorch,
              TotalSquareFeet = GrLivArea + GarageArea + BsmtFinSF1 + BsmtFinSF2 + LowQualFinSF + `1stFlrSF` + `2ndFlrSF`) %>%
  step_mutate(BinNeigh = case_when(Neighborhood %in% c("MeadowV","IDOTRR","BrDale") ~ "Low",
                                   Neighborhood %in% c("StoneBr","NoRidge","NridgHt") ~ "High",
                                   TRUE ~ "Med" ),
              BinMSSub = case_when(MSSubClass %in% c("180","30","45") ~ "Low",
                                   MSSubClass %in% c("120","60") ~ "High",
                                   TRUE ~ "Med" ),
              BinExt1 = case_when(Exterior1st %in% c("AsbShng","AsphShn",
                                                     "CBlock","BrkComm") ~ "Low",
                                  Exterior1st %in% c("VinylSd","CemntBd",
                                                     "Stone","ImStucc") ~ "High",
                                  TRUE ~ "Med" ),
              BinExt2 = case_when(Exterior2nd %in% c("CBlock","AsbShng") ~ "Low",
                                  Exterior2nd %in% c("VinylSd","CemntBd",
                                                     "ImStucc","Other") ~ "High",
                                  TRUE ~ "Med" ) )  %>%
  step_mutate(BinNeigh = factor(BinNeigh,
                                levels = c("High","Med","Low")),
              BinMSSub = factor(BinMSSub,
                                levels = c("High","Med","Low")),
              BinExt1 = factor(BinExt1,
                               levels = c("High","Med","Low")),
              BinExt2 = factor(BinExt2,
                               levels = c("High","Med","Low"))) %>%
  step_center(all_numeric(), - all_outcomes(),-Id) %>%
  step_scale(all_numeric(), -all_outcomes() , -Id) %>%
  step_other(all_of(cat_other),
             threshold = 0.1,
             other = "other")



# 1.5 Feature Importance ------------------------------------------------------


# 1.6 Removing dataset --------------------------------------------------------

# 1.6.1 remove binned variables created in step `.4

myrecipe <- myrecipe %>%
  step_rm(BsmtFullBath , FullBath , BsmtHalfBath ,HalfBath,
          YearRemodAdd, YearBuilt,
          WoodDeckSF , OpenPorchSF , EnclosedPorch ,`3SsnPorch`, ScreenPorch, 
          GrLivArea , GarageArea , BsmtFinSF1 , BsmtFinSF2 , LowQualFinSF, 
          `1stFlrSF`, `2ndFlrSF`)


# 1.6.2 remove highly correlated variables

drop_variables <- c('PoolArea',
                    'GarageYrBlt', 'GarageCond', 
                    'Fireplaces',
                    'ExterQual','KitchenQual','BedroomAbvGr',
                    'TotalBsmtSF','BsmtCond' )

myrecipe <- myrecipe %>%
  step_rm(all_of(drop_variables))

# 1.6.3 remove rows with outliers

myrecipe <- myrecipe  %>%
  step_filter(!Id %in% c(524,1299))

# myrecipe <- myrecipe %>%
#   step_spatialsign(all_numeric())


# 1.6.4 remove rows with near-zero variance

# note: not using step_nzv because it is removing OverallQual, which is one of our most important variables!

myrecipe <- myrecipe %>%
  step_rm(Street, Utilities, Condition2)


# 1.7 Dummy variables ---------------------------------------------------------

myrecipe <- myrecipe %>%
  step_dummy(all_nominal(),
             one_hot = TRUE) %>%
  step_rm(Id)



# preparation of recipe
myprep <-  prep(myrecipe, 
                training = full,
                retain = TRUE)

# newtrain <- myprep %>% juice()


full_clean <- myprep %>% 
  juice() %>% 
  mutate(.row = row_number())

full_splited <- make_splits(list(analysis   = full_clean$.row[!is.na(full_clean$SalePrice)], 
                                 assessment = full_clean$.row[is.na(full_clean$SalePrice)] ),
                            full_clean %>% select(-.row))


train_clean <- training(full_splited)

test_clean <- testing(full_splited)



# 2 Training Models ===========================================================

# 2.1 Main function for modeling ----------------------------------------------
# initialization of CV
vb_folds <- train_clean %>%
  vfold_cv(v = 10)

# main modelling function
model <- function(seed = 1234,
                  workflw = myworkflow,
                  myresample = vb_folds,
                  myparams,
                  mysize = 10,
                  perf_metrics = metric_set(rmse)){
  
  # Do a grid search for hyper parametrisation
  set.seed(seed)
  tune_res <- tune_grid( workflw,
                         resamples = myresample,
                         grid = dials::grid_max_entropy( myparams, 
                                                         size = mysize  ),
                         metrics = perf_metrics,
                         control = control_grid(save_pred = TRUE))
  
  # avg metrics by parameter
  p1 <- tune_res %>%
    collect_metrics() %>%
    filter(.metric %in%  "rmse") %>% # roc_auc
    select(-c(".estimator","n","std_err",".config")) %>%
    pivot_longer(cols = tidyselect::vars_select(names(.),-mean,-.metric),
                 values_to = "value",
                 names_to = "parameter"  ) %>%
    ggplot(aes(value, 
               mean, 
               color = parameter)) +
    geom_point(alpha = 0.8,
               show.legend = FALSE) +
    facet_grid(.metric ~ parameter, 
               scales = "free") +
    theme_light() +
    ggtitle("AVG metrics by parameter") +
    theme(plot.title = element_text(hjust = 0.5))
  
  # select best model
  best_model <- select_best(tune_res, 
                          "rmse")
  
  # update the workflow
  final_wf <- finalize_workflow( workflw,
                                 best_model)
  
  # Feature importance
  p2 <- final_wf %>%
    fit(data = train_clean  ) %>% 
    pull_workflow_fit() %>%
    vip::vip(geom = "point") +
    ggtitle("Feature Importance") +
    theme_light() +
    theme(plot.title = element_text(hjust = 0.5))
  
  # train the model
  final_wf <- final_wf %>%
    fit(data = train_clean  )
  
  
  data_plot <- final_wf %>%
    predict(new_data = train_clean) %>% 
    cbind(train_clean)
  
  RMSE <- rmse(data_plot,
               truth = SalePrice, 
               estimate = .pred)
  
  # plot the predictions against the real values
  p3 <- data_plot %>%
    ggplot(aes(x = SalePrice,
               y = .pred)) +
    geom_point(col = "darkblue",
               alpha = 0.3) + 
    geom_abline( lty = 2, 
                 alpha = 0.5,
                 color = "gray50",
                 size = 1.2  ) +
    theme_light()+
    xlab("Real Price") +
    ylab("Prediction") +
    ggtitle(paste0("Prediction against real values, RMSE: ",round(RMSE$.estimate,4)))+
    theme(plot.title = element_text(hjust = 0.5))
  
  # returns plots and final workflow
  list(ggarrange(p1,p2,p3),
       final_wf)
}




# 2.1 XGBoost model -----------------------------------------------------------

# initialisation of a xgboost
myxgb <- boost_tree( trees = 100, 
                     tree_depth = tune(),
                     min_n = tune() )  %>%           
  set_engine("xgboost") %>% 
  set_mode("regression")


# initialisation of workflow
xgb_wf <- workflow() %>%
  add_model(myxgb)%>% 
  add_formula(SalePrice ~ .)

list_xgb <- model(seed = 1234,
                  workflw = xgb_wf,
                  myresample = vb_folds,
                  myparams = dials::parameters( tree_depth(),
                                                min_n()),
                  mysize = 100,
                  perf_metrics = metric_set(rmse))




# 2.3 Elastic net -------------------------------------------------------------

# initialization elastic net model
myelasticnet <- linear_reg(penalty = tune(), 
                           mixture = tune()) %>% # = 1 for Lasso, 0 for Ridge
  set_engine("glmnet")

# initialization of workflow
elasticnet_wf <- workflow() %>% 
  add_model(myelasticnet)%>% 
  add_formula(SalePrice ~ .)


list_en <- model(seed = 1234,
                  workflw = elasticnet_wf,
                  myresample = vb_folds,
                  myparams = dials::parameters( penalty(),
                                                mixture()),
                  mysize = 100,
                  perf_metrics = metric_set(rmse))



# 3 Testing ===================================================================

# need to transform back the predictions due to log transform the outputs


# 3.1 Predicting XGB and Elastic net
test_xgb <- list_xgb[[2]] %>%
  predict(new_data = test_clean) %>%
  mutate(.pred = exp(.pred) )

test_en <- list_en[[2]] %>%
  predict(new_data = test_clean) %>%
  mutate(.pred = exp(.pred) )


# 3.2 Ensemble model ----------------------------------------------------------

# Since ElasticNet and XGBoost algorithms are very different,
# averaging predictions will likely improve the scores. 
# The RMSE for the XGB (0.0415) is much better than the one for the Elastic net (0.1064).

test_em <- (test_xgb+test_en)/2

# 3.3 Write the 3 predictions -------------------------------------------------
fwrite(data.frame(Id = full$Id[is.na(full$SalePrice)],
                  SalePrice = test_xgb$.pred),
       "Predictions_XGB.csv")

fwrite(data.frame(Id = full$Id[is.na(full$SalePrice)],
                  SalePrice = test_en$.pred),
       "Predictions_EN.csv")

fwrite(data.frame(Id = full$Id[is.na(full$SalePrice)],
                  SalePrice = test_em$.pred),
       "Predictions_EM.csv")