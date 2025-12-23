# ============================================================================
# Step 03: Feature Encoding
# ============================================================================
# This script handles:
#   1. Loading train/test splits
#   2. Applying 4 different encoding strategies
#   3. Saving encoded datasets for each strategy
#
# CRITICAL: Encoding is applied AFTER train/test split to prevent data leakage.
#           Target encoding statistics are computed on training data only.
#
# Input:  Raw splits (data/train_raw.csv, data/test_raw.csv)
# Output: Encoded datasets for each strategy
# ============================================================================

# Load configuration and utilities
source("config.r")
source("utils/encoding_functions.r")

library(dplyr)

cat("============================================================\n")
cat("Step 03: Feature Encoding\n")
cat("============================================================\n\n")

# =============================================================================
# 1. Load Raw Splits
# =============================================================================
cat("1. Loading raw train/test splits...\n")

train_file <- file.path(PATHS$data_dir, "train_raw.csv")
test_file <- file.path(PATHS$data_dir, "test_raw.csv")

if (!file.exists(train_file) || !file.exists(test_file)) {
    stop("ERROR: Raw splits not found. Please run 02_train_test_split.r first.")
}

df_train <- read.csv(train_file, stringsAsFactors = FALSE)
df_test <- read.csv(test_file, stringsAsFactors = FALSE)

cat("   Train:", nrow(df_train), "rows\n")
cat("   Test:", nrow(df_test), "rows\n\n")

# =============================================================================
# 2. Prepare Variable Groups
# =============================================================================
cat("2. Preparing variable groups...\n")

# Filter to existing columns
low_cols <- intersect(LOW_CARDINALITY_COLS, colnames(df_train))
med_cols <- intersect(MEDIUM_CARDINALITY_COLS, colnames(df_train))
high_cols <- intersect(HIGH_CARDINALITY_COLS, colnames(df_train))

cat("   Low cardinality (One-Hot):", length(low_cols), "variables\n")
cat("   Medium cardinality:", length(med_cols), "variables\n")
cat("   High cardinality:", length(high_cols), "variables\n\n")

# =============================================================================
# 3. Apply Encoding Strategies
# =============================================================================
cat("3. Applying encoding strategies...\n\n")

encoding_summary <- data.frame(
    Strategy = character(),
    Train_Rows = integer(),
    Train_Cols = integer(),
    Test_Rows = integer(),
    Test_Cols = integer(),
    stringsAsFactors = FALSE
)

for (strategy in ENCODING_STRATEGIES) {
    cat("   --- Strategy:", strategy, "---\n")

    # Copy data
    train_copy <- df_train
    test_copy <- df_test
    all_mappings <- list()

    # Apply encoding based on strategy
    if (strategy == "onehot_only") {
        # All categorical: One-Hot
        all_categorical <- c(low_cols, med_cols, high_cols)

        oh_result <- apply_onehot_encoding(train_copy, all_categorical, is_train = TRUE)
        train_copy <- oh_result$data
        all_mappings$onehot <- oh_result$mapping

        test_copy <- apply_onehot_encoding(test_copy, all_categorical,
            is_train = FALSE, mapping = all_mappings$onehot
        )$data
    } else if (strategy == "onehot_freq") {
        # Low: One-Hot, Others: Frequency
        oh_result <- apply_onehot_encoding(train_copy, low_cols, is_train = TRUE)
        train_copy <- oh_result$data
        all_mappings$onehot <- oh_result$mapping
        test_copy <- apply_onehot_encoding(test_copy, low_cols,
            is_train = FALSE, mapping = all_mappings$onehot
        )$data

        freq_cols <- c(med_cols, high_cols)
        freq_result <- apply_frequency_encoding(train_copy, freq_cols, is_train = TRUE)
        train_copy <- freq_result$data
        all_mappings$freq <- freq_result$mapping
        test_copy <- apply_frequency_encoding(test_copy, freq_cols,
            is_train = FALSE, mapping = all_mappings$freq
        )$data
    } else if (strategy == "onehot_target") {
        # Low: One-Hot, Others: Target Encoding
        oh_result <- apply_onehot_encoding(train_copy, low_cols, is_train = TRUE)
        train_copy <- oh_result$data
        all_mappings$onehot <- oh_result$mapping
        test_copy <- apply_onehot_encoding(test_copy, low_cols,
            is_train = FALSE, mapping = all_mappings$onehot
        )$data

        target_cols <- c(med_cols, high_cols)
        te_result <- apply_target_encoding(train_copy, target_cols, TARGET_VAR, is_train = TRUE)
        train_copy <- te_result$data
        all_mappings$target <- te_result$mapping
        test_copy <- apply_target_encoding(test_copy, target_cols, TARGET_VAR,
            is_train = FALSE, mapping = all_mappings$target
        )$data
    } else if (strategy == "onehot_freq_target") {
        # Low: One-Hot, Medium: Frequency, High: Target
        oh_result <- apply_onehot_encoding(train_copy, low_cols, is_train = TRUE)
        train_copy <- oh_result$data
        all_mappings$onehot <- oh_result$mapping
        test_copy <- apply_onehot_encoding(test_copy, low_cols,
            is_train = FALSE, mapping = all_mappings$onehot
        )$data

        freq_result <- apply_frequency_encoding(train_copy, med_cols, is_train = TRUE)
        train_copy <- freq_result$data
        all_mappings$freq <- freq_result$mapping
        test_copy <- apply_frequency_encoding(test_copy, med_cols,
            is_train = FALSE, mapping = all_mappings$freq
        )$data

        te_result <- apply_target_encoding(train_copy, high_cols, TARGET_VAR, is_train = TRUE)
        train_copy <- te_result$data
        all_mappings$target <- te_result$mapping
        test_copy <- apply_target_encoding(test_copy, high_cols, TARGET_VAR,
            is_train = FALSE, mapping = all_mappings$target
        )$data
    }

    # Save encoded data
    write.csv(train_copy, file.path(PATHS$data_dir, paste0("train_", strategy, ".csv")), row.names = FALSE)
    write.csv(test_copy, file.path(PATHS$data_dir, paste0("test_", strategy, ".csv")), row.names = FALSE)
    saveRDS(all_mappings, file.path(PATHS$data_dir, paste0("mapping_", strategy, ".rds")))

    cat("       Train:", ncol(train_copy), "features | Test:", ncol(test_copy), "features\n")
    cat("       Saved: train_", strategy, ".csv, test_", strategy, ".csv\n\n", sep = "")

    # Record summary
    encoding_summary <- rbind(encoding_summary, data.frame(
        Strategy = strategy,
        Train_Rows = nrow(train_copy),
        Train_Cols = ncol(train_copy),
        Test_Rows = nrow(test_copy),
        Test_Cols = ncol(test_copy)
    ))
}

# =============================================================================
# 4. Save Summary
# =============================================================================
cat("4. Saving encoding summary...\n")

write.csv(encoding_summary, file.path(PATHS$tables_dir, "encoding_summary.csv"), row.names = FALSE)
cat("   Saved: encoding_summary.csv\n\n")

print(encoding_summary)

# =============================================================================
# Summary
# =============================================================================
cat("\n============================================================\n")
cat("Step 03 Complete!\n")
cat("============================================================\n")
cat("Encoding strategies applied:\n")
for (i in 1:nrow(encoding_summary)) {
    cat("  ", i, ". ", encoding_summary$Strategy[i],
        " → ", encoding_summary$Train_Cols[i], " features\n",
        sep = ""
    )
}
cat("\nKey points:\n")
cat("  - Encoding applied AFTER train/test split (no data leakage)\n")
cat("  - Target encoding statistics computed on training data only\n")
cat("  - Mappings saved for reproducibility\n")
cat("\nNext step: Run 04_model_training.r\n")
cat("============================================================\n")
