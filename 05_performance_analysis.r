# ============================================================================
# Step 05: Performance Analysis and Visualization
# ============================================================================
# This script handles:
#   1. Loading model results
#   2. Creating performance comparison visualizations
#   3. Generating scatter plots of predictions
#   4. Statistical analysis of encoding strategies
#
# Input:  Model results (output/tables/model_results.csv)
# Output: Figures (output/figures/)
# ============================================================================

# Load configuration and utilities
source("config.r")
source("utils/publication_theme.r")

library(dplyr)
library(tidyr)
library(ggplot2)

cat("============================================================\n")
cat("Step 05: Performance Analysis and Visualization\n")
cat("============================================================\n\n")

# Create figures directory
if (!dir.exists(PATHS$figures_dir)) dir.create(PATHS$figures_dir, recursive = TRUE)

# =============================================================================
# 1. Load Results
# =============================================================================
cat("1. Loading model results...\n")

results_file <- file.path(PATHS$tables_dir, "model_results.csv")
if (!file.exists(results_file)) {
    stop("ERROR: Model results not found. Run 04_model_training.r first.")
}

results <- read.csv(results_file, stringsAsFactors = FALSE)
cat("   Loaded:", nrow(results), "model-encoding combinations\n\n")

# =============================================================================
# 2. Overall Performance Heatmap
# =============================================================================
cat("2. Creating performance heatmap...\n")

# Prepare data for heatmap
heatmap_data <- results %>%
    select(Encoding, Model, RMSE) %>%
    mutate(
        Encoding = factor(Encoding, levels = ENCODING_STRATEGIES),
        Model = factor(Model)
    )

p_heatmap <- ggplot(heatmap_data, aes(x = Encoding, y = Model, fill = RMSE)) +
    geom_tile(color = "white", size = 0.5) +
    geom_text(aes(label = round(RMSE, 3)), color = "white", size = 4, fontface = "bold") +
    scale_fill_gradient(low = "#00A087", high = "#E64B35", name = "RMSE") +
    labs(
        title = "Model Performance Comparison (RMSE)",
        subtitle = "Lower values indicate better performance",
        x = "Encoding Strategy",
        y = "Model"
    ) +
    theme_publication() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "right"
    )

save_publication_plot(p_heatmap, file.path(PATHS$figures_dir, "performance_heatmap"))
cat("   Saved: performance_heatmap.png\n")

# =============================================================================
# 3. Model Comparison Bar Chart
# =============================================================================
cat("3. Creating model comparison chart...\n")

# Best encoding for each model
best_by_model <- results %>%
    group_by(Model) %>%
    slice_min(RMSE, n = 1) %>%
    arrange(RMSE)

p_models <- ggplot(best_by_model, aes(x = reorder(Model, RMSE), y = RMSE, fill = Encoding)) +
    geom_bar(stat = "identity", width = 0.7) +
    geom_text(aes(label = round(RMSE, 3)), vjust = -0.3, size = 3.5, fontface = "bold") +
    scale_fill_manual(values = ENCODING_COLORS) +
    labs(
        title = "Best Performance by Model",
        subtitle = "Each bar shows best encoding strategy for that model",
        x = "Model",
        y = "Test RMSE"
    ) +
    theme_publication() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_publication_plot(p_models, file.path(PATHS$figures_dir, "model_comparison"))
cat("   Saved: model_comparison.png\n")

# =============================================================================
# 4. Encoding Strategy Comparison
# =============================================================================
cat("4. Creating encoding strategy comparison...\n")

encoding_summary <- results %>%
    group_by(Encoding) %>%
    summarise(
        Mean_RMSE = mean(RMSE),
        SD_RMSE = sd(RMSE),
        Mean_R2 = mean(R2),
        Best_Model = Model[which.min(RMSE)],
        .groups = "drop"
    ) %>%
    arrange(Mean_RMSE)

p_encoding <- ggplot(encoding_summary, aes(x = reorder(Encoding, Mean_RMSE), y = Mean_RMSE)) +
    geom_bar(stat = "identity", fill = "#4DBBD5", width = 0.7) +
    geom_errorbar(aes(ymin = Mean_RMSE - SD_RMSE, ymax = Mean_RMSE + SD_RMSE),
        width = 0.2, size = 0.8
    ) +
    geom_text(aes(label = round(Mean_RMSE, 3)), vjust = -0.5, size = 4, fontface = "bold") +
    labs(
        title = "Encoding Strategy Comparison",
        subtitle = "Mean ± SD across all models",
        x = "Encoding Strategy",
        y = "Mean RMSE"
    ) +
    theme_publication() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_publication_plot(p_encoding, file.path(PATHS$figures_dir, "encoding_comparison"))
cat("   Saved: encoding_comparison.png\n")

# =============================================================================
# 5. Training Time vs Performance
# =============================================================================
cat("5. Creating time-performance trade-off plot...\n")

p_tradeoff <- ggplot(results, aes(x = Time_sec, y = RMSE, color = Model, shape = Encoding)) +
    geom_point(size = 4, alpha = 0.8) +
    scale_color_manual(values = MODEL_COLORS) +
    scale_x_log10() +
    labs(
        title = "Training Time vs Performance",
        subtitle = "Trade-off between computational cost and accuracy",
        x = "Training Time (seconds, log scale)",
        y = "Test RMSE"
    ) +
    theme_publication() +
    guides(color = guide_legend(nrow = 2), shape = guide_legend(nrow = 2))

save_publication_plot(p_tradeoff, file.path(PATHS$figures_dir, "time_performance_tradeoff"))
cat("   Saved: time_performance_tradeoff.png\n")

# =============================================================================
# 6. Summary Statistics
# =============================================================================
cat("\n6. Summary Statistics:\n\n")

cat("Best Overall Model:\n")
best_overall <- results %>% slice_min(RMSE, n = 1)
cat("   Model:", best_overall$Model, "\n")
cat("   Encoding:", best_overall$Encoding, "\n")
cat("   RMSE:", round(best_overall$RMSE, 4), "\n")
cat("   R²:", round(best_overall$R2, 4), "\n")
cat("   r:", round(best_overall$r, 4), "\n\n")

cat("Encoding Strategy Ranking:\n")
for (i in 1:nrow(encoding_summary)) {
    cat("   ", i, ". ", encoding_summary$Encoding[i],
        " (Mean RMSE: ", round(encoding_summary$Mean_RMSE[i], 4), ")\n",
        sep = ""
    )
}

# Save summary table
write.csv(encoding_summary, file.path(PATHS$tables_dir, "encoding_strategy_summary.csv"), row.names = FALSE)

# =============================================================================
# Summary
# =============================================================================
cat("\n============================================================\n")
cat("Step 05 Complete!\n")
cat("============================================================\n")
cat("Figures saved to:", PATHS$figures_dir, "\n")
cat("Tables saved to:", PATHS$tables_dir, "\n")
cat("\nGenerated figures:\n")
cat("  - performance_heatmap.png\n")
cat("  - model_comparison.png\n")
cat("  - encoding_comparison.png\n")
cat("  - time_performance_tradeoff.png\n")
cat("============================================================\n")
