# ============================================================================
# Utility Functions: Evaluation Metrics
# ============================================================================

#' Calculate regression performance metrics
#' @param actual Vector of actual values
#' @param predicted Vector of predicted values
#' @return Named list with RMSE, MAE, R2, and Pearson correlation
calc_metrics <- function(actual, predicted) {
    # Remove NA values
    valid_idx <- !is.na(actual) & !is.na(predicted)
    actual <- actual[valid_idx]
    predicted <- predicted[valid_idx]

    # RMSE
    rmse <- sqrt(mean((actual - predicted)^2))

    # MAE
    mae <- mean(abs(actual - predicted))

    # R-squared
    ss_res <- sum((actual - predicted)^2)
    ss_tot <- sum((actual - mean(actual))^2)
    r2 <- 1 - (ss_res / ss_tot)

    # Pearson correlation
    r <- cor(actual, predicted, method = "pearson")

    return(list(
        RMSE = rmse,
        MAE = mae,
        R2 = r2,
        r = r
    ))
}

#' Print formatted metrics
print_metrics <- function(metrics, prefix = "") {
    cat(
        prefix, "RMSE:", round(metrics$RMSE, 4),
        "| MAE:", round(metrics$MAE, 4),
        "| R²:", round(metrics$R2, 4),
        "| r:", round(metrics$r, 4), "\n"
    )
}
