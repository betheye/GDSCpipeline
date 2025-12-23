# ============================================================================
# Publication-Quality Visualization Theme
# ============================================================================
# Source this file to use consistent styling across all figures
# ============================================================================

library(ggplot2)

# =============================================================================
# Color Palettes
# =============================================================================
# Nature/Science inspired color palette
PUBLICATION_COLORS <- c(
    "#E64B35", "#4DBBD5", "#00A087", "#3C5488",
    "#F39B7F", "#8491B4", "#91D1C2", "#DC0000",
    "#7E6148", "#B09C85"
)

# Model-specific colors
MODEL_COLORS <- c(
    "lm" = "#1B9E77", "ridge" = "#D95F02", "lasso" = "#7570B3",
    "dt" = "#E7298A", "rf" = "#66A61E", "xgb" = "#E6AB02",
    "knn" = "#A6761D", "svr" = "#666666", "mlp" = "#1F78B4",
    "deep_mlp" = "#B2DF8A"
)

# Encoding strategy colors
ENCODING_COLORS <- c(
    "onehot_only" = "#E64B35",
    "onehot_freq" = "#4DBBD5",
    "onehot_target" = "#00A087",
    "onehot_freq_target" = "#3C5488"
)

# =============================================================================
# Main Publication Theme
# =============================================================================
theme_publication <- function(base_size = 14) {
    theme_minimal(base_size = base_size) +
        theme(
            # Title and subtitle
            plot.title = element_text(
                face = "bold",
                size = rel(1.2),
                hjust = 0,
                margin = margin(b = 10)
            ),
            plot.subtitle = element_text(
                size = rel(0.9),
                color = "grey40",
                margin = margin(b = 15)
            ),

            # Axes
            axis.title = element_text(
                face = "bold",
                size = rel(1.0)
            ),
            axis.text = element_text(
                size = rel(0.9),
                color = "grey30"
            ),
            axis.line = element_line(color = "grey30", size = 0.5),

            # Legend
            legend.title = element_text(face = "bold", size = rel(0.9)),
            legend.text = element_text(size = rel(0.85)),
            legend.position = "bottom",
            legend.background = element_blank(),

            # Panel
            panel.grid.major = element_line(color = "grey90", size = 0.3),
            panel.grid.minor = element_blank(),
            panel.background = element_blank(),

            # Facets
            strip.text = element_text(
                face = "bold",
                size = rel(1.0),
                margin = margin(b = 5, t = 5)
            ),
            strip.background = element_rect(fill = "grey95", color = NA),

            # Margins
            plot.margin = margin(15, 15, 15, 15)
        )
}

# =============================================================================
# Helper Functions
# =============================================================================
#' Save plot in publication quality
#' @param plot ggplot object
#' @param filename Output filename (without extension)
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param dpi Resolution (default 600 for publication)
save_publication_plot <- function(plot, filename, width = 12, height = 8, dpi = 600) {
    ggsave(
        paste0(filename, ".png"),
        plot = plot,
        width = width,
        height = height,
        dpi = dpi
    )
    cat("Saved:", paste0(filename, ".png"), "\n")
}

cat("Publication theme loaded successfully!\n")
