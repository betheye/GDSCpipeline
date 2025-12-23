# ============================================================================
# Step 01: Data Preprocessing
# ============================================================================
# This script handles:
#   1. Loading raw GDSC data
#   2. Missing value treatment (filling with "Unknown")
#   3. Removing problematic cell lines
#   4. Saving cleaned data
#
# Input:  Raw GDSC dataset (GDSC_selected_columns.csv)
# Output: Cleaned dataset (data/GDSC_cleaned.csv)
# ============================================================================

# Load configuration
source("config.r")

library(dplyr)
library(tidyr)

cat("============================================================\n")
cat("Step 01: Data Preprocessing\n")
cat("============================================================\n\n")

# =============================================================================
# 1. Load Raw Data
# =============================================================================
cat("1. Loading raw data...\n")

df_raw <- read.csv(PATHS$raw_data, stringsAsFactors = FALSE)
cat("   Raw data dimensions:", nrow(df_raw), "rows x", ncol(df_raw), "cols\n\n")

# =============================================================================
# 2. Identify Variables with Missing Values
# =============================================================================
cat("2. Analyzing missing values...\n")

# GDSC core variables (commonly missing together)
gdsc_core_vars <- c(
    "GDSC.Tissue.descriptor.1", "GDSC.Tissue.descriptor.2",
    "Screen.Medium", "Growth.Properties",
    "CNA", "Gene.Expression", "Methylation"
)
gdsc_core_vars <- intersect(gdsc_core_vars, colnames(df_raw))

# Calculate missing rates
missing_summary <- sapply(df_raw, function(x) {
    sum(is.na(x) | x == "") / length(x) * 100
})
missing_vars <- names(missing_summary[missing_summary > 0])

cat("   Variables with missing values:", length(missing_vars), "\n")
for (var in missing_vars) {
    cat("     -", var, ":", round(missing_summary[var], 2), "%\n")
}
cat("\n")

# =============================================================================
# 3. Identify and Remove "Empty Shell" Cell Lines
# =============================================================================
cat("3. Identifying problematic cell lines...\n")

# Cell lines with ALL GDSC core variables missing
cell_line_missing <- df_raw %>%
    group_by(COSMIC_ID) %>%
    summarise(
        gdsc_missing_rate = mean(
            is.na(.data[[gdsc_core_vars[1]]]) | .data[[gdsc_core_vars[1]]] == ""
        ) * 100,
        .groups = "drop"
    )

cells_to_remove <- cell_line_missing %>%
    filter(gdsc_missing_rate == 100) %>%
    pull(COSMIC_ID)

cat("   'Empty shell' cell lines found:", length(cells_to_remove), "\n")

# Remove these cell lines
df_clean <- df_raw %>%
    filter(!COSMIC_ID %in% cells_to_remove)

cat("   Rows removed:", nrow(df_raw) - nrow(df_clean), "\n\n")

# =============================================================================
# 4. Handle Missing Values with "Unknown" Strategy
# =============================================================================
cat("4. Handling missing values...\n")

# Strategy: Fill categorical missing with "Unknown" to preserve information
# that missingness itself may be informative

# TARGET variable
if ("TARGET" %in% colnames(df_clean)) {
    n_missing <- sum(is.na(df_clean$TARGET) | df_clean$TARGET == "")
    df_clean$TARGET <- ifelse(
        is.na(df_clean$TARGET) | df_clean$TARGET == "",
        "Unknown", df_clean$TARGET
    )
    cat("   TARGET: filled", n_missing, "missing → 'Unknown'\n")
}

# MSI status
msi_col <- "Microsatellite.instability.Status..MSI."
if (msi_col %in% colnames(df_clean)) {
    n_missing <- sum(is.na(df_clean[[msi_col]]) | df_clean[[msi_col]] == "")
    df_clean[[msi_col]] <- ifelse(
        is.na(df_clean[[msi_col]]) | df_clean[[msi_col]] == "",
        "Unknown", df_clean[[msi_col]]
    )
    cat("   MSI:", n_missing, "missing → 'Unknown'\n")
}

# TCGA_DESC (very few missing - remove these rows)
if ("TCGA_DESC" %in% colnames(df_clean)) {
    rows_before <- nrow(df_clean)
    df_clean <- df_clean %>% filter(!is.na(TCGA_DESC) & TCGA_DESC != "")
    n_removed <- rows_before - nrow(df_clean)
    if (n_removed > 0) {
        cat("   TCGA_DESC: removed", n_removed, "rows with missing\n")
    }
}

# GDSC core variables
for (var in gdsc_core_vars) {
    if (var %in% colnames(df_clean)) {
        n_missing <- sum(is.na(df_clean[[var]]) | df_clean[[var]] == "")
        if (n_missing > 0) {
            df_clean[[var]] <- ifelse(
                is.na(df_clean[[var]]) | df_clean[[var]] == "",
                "Not_Available", df_clean[[var]]
            )
            cat("   ", var, ":", n_missing, "missing → 'Not_Available'\n")
        }
    }
}

cat("\n")

# =============================================================================
# 5. Verify Cleaned Data
# =============================================================================
cat("5. Verification...\n")

remaining_missing <- sum(sapply(df_clean, function(x) sum(is.na(x) | x == "")))
cat("   Remaining missing values:", remaining_missing, "\n")
cat("   Final dimensions:", nrow(df_clean), "rows x", ncol(df_clean), "cols\n\n")

# =============================================================================
# 6. Save Cleaned Data
# =============================================================================
cat("6. Saving cleaned data...\n")

output_file <- file.path(PATHS$data_dir, "GDSC_cleaned.csv")
write.csv(df_clean, output_file, row.names = FALSE)
cat("   Saved to:", output_file, "\n")

# =============================================================================
# Summary
# =============================================================================
cat("\n============================================================\n")
cat("Step 01 Complete!\n")
cat("============================================================\n")
cat("Summary:\n")
cat("  - Input rows:", nrow(df_raw), "\n")
cat("  - Output rows:", nrow(df_clean), "\n")
cat(
    "  - Rows removed:", nrow(df_raw) - nrow(df_clean),
    "(", round((nrow(df_raw) - nrow(df_clean)) / nrow(df_raw) * 100, 2), "%)\n"
)
cat("  - Missing handling: 'Unknown' category approach\n")
cat("\nNext step: Run 02_train_test_split.r\n")
cat("============================================================\n")
