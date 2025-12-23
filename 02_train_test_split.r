# ============================================================================
# Step 02: Train/Test Split
# ============================================================================
# This script handles:
#   1. Loading cleaned data
#   2. Performing 80/20 train/test split BEFORE encoding (critical!)
#   3. Saving split data and indices for reproducibility
#
# Input:  Cleaned dataset (data/GDSC_cleaned.csv)
# Output: Train/Test splits (data/train_raw.csv, data/test_raw.csv)
#         Split indices (data/split_indices.rds)
# ============================================================================

# Load configuration
source("config.r")

library(dplyr)

cat("============================================================\n")
cat("Step 02: Train/Test Split\n")
cat("============================================================\n\n")

# =============================================================================
# 1. Load Cleaned Data
# =============================================================================
cat("1. Loading cleaned data...\n")

input_file <- file.path(PATHS$data_dir, "GDSC_cleaned.csv")

if (!file.exists(input_file)) {
    stop("ERROR: Cleaned data not found. Please run 01_data_preprocessing.r first.")
}

df <- read.csv(input_file, stringsAsFactors = FALSE)
cat("   Data dimensions:", nrow(df), "rows x", ncol(df), "cols\n\n")

# =============================================================================
# 2. Perform Train/Test Split
# =============================================================================
cat("2. Splitting data (", TRAIN_RATIO * 100, "/", (1 - TRAIN_RATIO) * 100, ")...\n", sep = "")

# Set seed for reproducibility
set.seed(SEED)

n_total <- nrow(df)
n_train <- floor(n_total * TRAIN_RATIO)

# Random shuffle and split
shuffled_indices <- sample(1:n_total)
train_indices <- shuffled_indices[1:n_train]
test_indices <- shuffled_indices[(n_train + 1):n_total]

df_train <- df[train_indices, ]
df_test <- df[test_indices, ]

cat("   Total samples:", n_total, "\n")
cat("   Training set:", nrow(df_train), "(", round(nrow(df_train) / n_total * 100, 1), "%)\n")
cat("   Test set:", nrow(df_test), "(", round(nrow(df_test) / n_total * 100, 1), "%)\n\n")

# =============================================================================
# 3. Verify Split Quality
# =============================================================================
cat("3. Verifying split quality...\n")

# Check target distribution
train_mean <- mean(df_train[[TARGET_VAR]], na.rm = TRUE)
test_mean <- mean(df_test[[TARGET_VAR]], na.rm = TRUE)
train_sd <- sd(df_train[[TARGET_VAR]], na.rm = TRUE)
test_sd <- sd(df_test[[TARGET_VAR]], na.rm = TRUE)

cat("   Target variable (", TARGET_VAR, "):\n", sep = "")
cat("     Train: mean =", round(train_mean, 3), ", sd =", round(train_sd, 3), "\n")
cat("     Test:  mean =", round(test_mean, 3), ", sd =", round(test_sd, 3), "\n")

# Check if distributions are similar
if (abs(train_mean - test_mean) < 0.1 * train_sd) {
    cat("   ✓ Split looks balanced\n\n")
} else {
    cat("   ⚠ Warning: Train/Test distributions differ slightly\n\n")
}

# =============================================================================
# 4. Save Split Data
# =============================================================================
cat("4. Saving split data...\n")

# Save raw splits (before encoding)
write.csv(df_train, file.path(PATHS$data_dir, "train_raw.csv"), row.names = FALSE)
write.csv(df_test, file.path(PATHS$data_dir, "test_raw.csv"), row.names = FALSE)
cat("   Saved: train_raw.csv, test_raw.csv\n")

# Save indices for reproducibility
split_info <- list(
    seed = SEED,
    train_ratio = TRAIN_RATIO,
    train_indices = train_indices,
    test_indices = test_indices,
    n_train = nrow(df_train),
    n_test = nrow(df_test),
    timestamp = Sys.time()
)
saveRDS(split_info, file.path(PATHS$data_dir, "split_indices.rds"))
cat("   Saved: split_indices.rds (for reproducibility)\n")

# =============================================================================
# Summary
# =============================================================================
cat("\n============================================================\n")
cat("Step 02 Complete!\n")
cat("============================================================\n")
cat("Summary:\n")
cat("  - Random seed:", SEED, "(reproducible)\n")
cat("  - Train/Test ratio:", TRAIN_RATIO, "/", 1 - TRAIN_RATIO, "\n")
cat("  - Training samples:", nrow(df_train), "\n")
cat("  - Test samples:", nrow(df_test), "\n")
cat("\nIMPORTANT: Split performed BEFORE encoding to prevent data leakage.\n")
cat("\nNext step: Run 03_feature_encoding.r\n")
cat("============================================================\n")
