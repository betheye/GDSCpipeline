# ============================================================================
# Configuration File for Drug Sensitivity Prediction Pipeline
# ============================================================================
# This file contains all shared settings used across the pipeline scripts.
# Modify paths and parameters here before running.
# ============================================================================

# =============================================================================
# PATH CONFIGURATION
# =============================================================================
# IMPORTANT: Update this to your project root directory
# Option 1: Automatic detection (recommended)
BASE_DIR <- getwd() # Assumes you run scripts from scripts_organized/

# Option 2: Manual path (uncomment and modify if needed)
# BASE_DIR <- "/path/to/your/project"

# Input/Output paths (relative to scripts_organized/)
PATHS <- list(
    # Raw data input
    raw_data = file.path(BASE_DIR, "data/cleaned/GDSC_selected_columns.csv"),

    # Output directories (will be created if not exist)
    output_dir = file.path(BASE_DIR, "scripts_organized/output"),
    data_dir = file.path(BASE_DIR, "scripts_organized/data"),
    figures_dir = file.path(BASE_DIR, "scripts_organized/output/figures"),
    tables_dir = file.path(BASE_DIR, "scripts_organized/output/tables"),
    models_dir = file.path(BASE_DIR, "scripts_organized/output/models")
)

# Create directories if they don't exist
for (dir_path in PATHS) {
    if (!dir.exists(dir_path) && !grepl("\\.csv$", dir_path)) {
        dir.create(dir_path, recursive = TRUE)
    }
}

# =============================================================================
# RANDOM SEED (for reproducibility)
# =============================================================================
SEED <- 42
set.seed(SEED)

# =============================================================================
# DATA CONFIGURATION
# =============================================================================
TARGET_VAR <- "LN_IC50"
TRAIN_RATIO <- 0.8

# Variable grouping by cardinality
LOW_CARDINALITY_COLS <- c(
    "Microsatellite.instability.Status..MSI.",
    "Screen.Medium",
    "Growth.Properties",
    "CNA",
    "Gene.Expression",
    "Methylation"
)

MEDIUM_CARDINALITY_COLS <- c(
    "TCGA_DESC",
    "GDSC.Tissue.descriptor.1",
    "GDSC.Tissue.descriptor.2",
    "TARGET_PATHWAY"
)

HIGH_CARDINALITY_COLS <- c(
    "COSMIC_ID",
    "DRUG_ID",
    "TARGET"
)

# =============================================================================
# ENCODING STRATEGIES
# =============================================================================
ENCODING_STRATEGIES <- c(
    "onehot_only", # All variables: One-Hot
    "onehot_freq", # Low: One-Hot, Others: Frequency
    "onehot_target", # Low: One-Hot, Others: Target Encoding
    "onehot_freq_target" # Low: One-Hot, Med: Frequency, High: Target
)

# =============================================================================
# MODEL CONFIGURATION
# =============================================================================
# Models to train (simplified list for local execution)
MODEL_LIST <- c("lm", "ridge", "lasso", "rf", "xgb")

# Full model list (for comprehensive analysis)
MODEL_LIST_FULL <- c(
    "lm", "ridge", "lasso", # Linear models
    "dt", "rf", "xgb", # Tree-based models
    "knn", "svr", # Instance-based models
    "mlp", "deep_mlp" # Neural networks
)

# Model hyperparameters
MODEL_PARAMS <- list(
    rf = list(num.trees = 500, mtry_ratio = 1 / 3),
    xgb = list(nrounds = 100, max_depth = 6, eta = 0.1),
    ridge = list(alpha = 0, nfolds = 10),
    lasso = list(alpha = 1, nfolds = 10),
    knn = list(k_values = c(3, 5, 7, 10, 15)),
    svr = list(cost_values = c(0.1, 1, 10, 100))
)

# =============================================================================
# VISUALIZATION SETTINGS
# =============================================================================
PLOT_DPI <- 600 # Publication quality
PLOT_WIDTH <- 12
PLOT_HEIGHT <- 8

# Color palette (Nature/Science style)
COLOR_PALETTE <- c(
    "#E64B35", "#4DBBD5", "#00A087", "#3C5488",
    "#F39B7F", "#8491B4", "#91D1C2", "#DC0000",
    "#7E6148", "#B09C85"
)

# =============================================================================
# GENERALIZATION ANALYSIS SETTINGS
# =============================================================================
N_FOLDS <- 5 # For K-Fold CV
N_DRUG_SAMPLES <- 10 # For Leave-One-Drug-Out
N_CELL_SAMPLES <- 10 # For Leave-One-Cell-Out

# =============================================================================
# PARALLEL PROCESSING
# =============================================================================
N_THREADS <- parallel::detectCores() - 1
if (N_THREADS < 1) N_THREADS <- 1

cat("============================================================\n")
cat("Configuration loaded successfully!\n")
cat("============================================================\n")
cat("  Base directory:", BASE_DIR, "\n")
cat("  Random seed:", SEED, "\n")
cat("  Train ratio:", TRAIN_RATIO, "\n")
cat("  Encoding strategies:", length(ENCODING_STRATEGIES), "\n")
cat("  Models (default):", length(MODEL_LIST), "\n")
cat("  Parallel threads:", N_THREADS, "\n")
cat("============================================================\n\n")
