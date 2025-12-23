# ============================================================================
# Step 04: Model Training
# ============================================================================
# This script handles:
#   1. Loading encoded train/test data
#   2. Training multiple models across encoding strategies
#   3. Evaluating and saving results
#
# Input:  Encoded datasets (data/train_*.csv, data/test_*.csv)
# Output: Model files (output/models/)
#         Performance results (output/tables/model_results.csv)
# ============================================================================

# Load configuration and utilities
source("config.r")
source("utils/metrics.r")

library(dplyr)

# Check and load modeling packages
required_packages <- c("glmnet", "ranger", "xgboost", "rpart")
for (pkg in required_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
        install.packages(pkg, repos = "https://cloud.r-project.org")
        library(pkg, character.only = TRUE)
    }
}

cat("============================================================\n")
cat("Step 04: Model Training\n")
cat("============================================================\n\n")

# =============================================================================
# 1. Setup
# =============================================================================
cat("1. Setting up...\n")
cat("   Models to train:", paste(MODEL_LIST, collapse = ", "), "\n")
cat("   Encoding strategies:", length(ENCODING_STRATEGIES), "\n")
cat("   Total combinations:", length(MODEL_LIST) * length(ENCODING_STRATEGIES), "\n\n")

# Create models directory
models_dir <- PATHS$models_dir
if (!dir.exists(models_dir)) dir.create(models_dir, recursive = TRUE)

# Results storage
all_results <- data.frame()

# =============================================================================
# 2. Train Models
# =============================================================================
cat("2. Training models...\n\n")

for (strategy in ENCODING_STRATEGIES) {
    cat("=== Encoding:", strategy, "===\n")

    # Load encoded data
    train_file <- file.path(PATHS$data_dir, paste0("train_", strategy, ".csv"))
    test_file <- file.path(PATHS$data_dir, paste0("test_", strategy, ".csv"))

    if (!file.exists(train_file)) {
        cat("   WARNING: Encoded data not found. Run 03_feature_encoding.r first.\n\n")
        next
    }

    train_df <- read.csv(train_file, stringsAsFactors = FALSE)
    test_df <- read.csv(test_file, stringsAsFactors = FALSE)

    # Prepare features and target
    X_train <- train_df %>%
        select(-all_of(TARGET_VAR)) %>%
        mutate(across(everything(), as.numeric))
    y_train <- train_df[[TARGET_VAR]]
    X_test <- test_df %>%
        select(-all_of(TARGET_VAR)) %>%
        mutate(across(everything(), as.numeric))
    y_test <- test_df[[TARGET_VAR]]

    # Handle any remaining NAs
    X_train[is.na(X_train)] <- 0
    X_test[is.na(X_test)] <- 0

    cat("   Features:", ncol(X_train), "\n")

    for (model_name in MODEL_LIST) {
        cat("   Training:", model_name, "... ")

        start_time <- Sys.time()
        test_pred <- NULL

        tryCatch(
            {
                if (model_name == "lm") {
                    # Linear Regression
                    model <- lm(y ~ ., data = cbind(y = y_train, X_train))
                    test_pred <- predict(model, newdata = X_test)
                } else if (model_name == "ridge") {
                    # Ridge Regression
                    X_mat <- as.matrix(X_train)
                    cv_model <- cv.glmnet(X_mat, y_train, alpha = 0, nfolds = 10)
                    model <- glmnet(X_mat, y_train, alpha = 0, lambda = cv_model$lambda.min)
                    test_pred <- as.vector(predict(model, as.matrix(X_test)))
                } else if (model_name == "lasso") {
                    # Lasso Regression
                    X_mat <- as.matrix(X_train)
                    cv_model <- cv.glmnet(X_mat, y_train, alpha = 1, nfolds = 10)
                    model <- glmnet(X_mat, y_train, alpha = 1, lambda = cv_model$lambda.min)
                    test_pred <- as.vector(predict(model, as.matrix(X_test)))
                } else if (model_name == "dt") {
                    # Decision Tree
                    model <- rpart(y ~ .,
                        data = cbind(y = y_train, X_train),
                        control = rpart.control(maxdepth = 10)
                    )
                    test_pred <- predict(model, newdata = X_test)
                } else if (model_name == "rf") {
                    # Random Forest
                    model <- ranger(
                        x = X_train, y = y_train,
                        num.trees = MODEL_PARAMS$rf$num.trees,
                        mtry = max(1, floor(ncol(X_train) * MODEL_PARAMS$rf$mtry_ratio)),
                        num.threads = N_THREADS,
                        seed = SEED
                    )
                    test_pred <- predict(model, X_test)$predictions
                } else if (model_name == "xgb") {
                    # XGBoost
                    dtrain <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)
                    dtest <- xgb.DMatrix(data = as.matrix(X_test), label = y_test)

                    params <- list(
                        objective = "reg:squarederror",
                        max_depth = MODEL_PARAMS$xgb$max_depth,
                        eta = MODEL_PARAMS$xgb$eta,
                        nthread = N_THREADS
                    )

                    model <- xgb.train(
                        params = params, data = dtrain,
                        nrounds = MODEL_PARAMS$xgb$nrounds,
                        watchlist = list(test = dtest),
                        early_stopping_rounds = 10,
                        verbose = 0
                    )
                    test_pred <- predict(model, dtest)
                }

                # Calculate metrics
                if (!is.null(test_pred)) {
                    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
                    metrics <- calc_metrics(y_test, test_pred)

                    cat(
                        "RMSE:", round(metrics$RMSE, 4),
                        "| R²:", round(metrics$R2, 4),
                        "| Time:", round(elapsed, 1), "s\n"
                    )

                    # Save results
                    all_results <- rbind(all_results, data.frame(
                        Encoding = strategy,
                        Model = model_name,
                        RMSE = metrics$RMSE,
                        MAE = metrics$MAE,
                        R2 = metrics$R2,
                        r = metrics$r,
                        Time_sec = elapsed,
                        N_Features = ncol(X_train)
                    ))

                    # Save model
                    model_file <- file.path(models_dir, paste0(model_name, "_", strategy, ".rds"))
                    saveRDS(model, model_file)
                }
            },
            error = function(e) {
                cat("ERROR:", conditionMessage(e), "\n")
            }
        )
    }
    cat("\n")
}

# =============================================================================
# 3. Save Results
# =============================================================================
cat("3. Saving results...\n")

results_file <- file.path(PATHS$tables_dir, "model_results.csv")
write.csv(all_results, results_file, row.names = FALSE)
cat("   Saved:", results_file, "\n\n")

# =============================================================================
# 4. Summary
# =============================================================================
cat("============================================================\n")
cat("Step 04 Complete!\n")
cat("============================================================\n\n")

# Best models by RMSE
cat("Top 5 Models by RMSE:\n")
top_models <- all_results %>%
    arrange(RMSE) %>%
    head(5)
print(top_models %>% select(Encoding, Model, RMSE, R2))

cat("\nModels saved to:", models_dir, "\n")
cat("Results saved to:", results_file, "\n")
cat("\nNext step: Run 05_performance_analysis.r for visualization\n")
cat("============================================================\n")
