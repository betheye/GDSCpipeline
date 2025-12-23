# ============================================================================
# Utility Functions: Feature Encoding
# ============================================================================
# Reusable encoding functions for categorical variables
# ============================================================================

# =============================================================================
# One-Hot Encoding
# =============================================================================
#' Apply One-Hot Encoding to specified columns
#' @param df Data frame
#' @param cols Columns to encode
#' @param is_train TRUE for training set (learns categories)
#' @param mapping Pre-computed mapping for test set
#' @return List with encoded data and mapping
apply_onehot_encoding <- function(df, cols, is_train = TRUE, mapping = NULL) {
    result <- df
    new_mapping <- list()

    cols <- intersect(cols, colnames(df))

    for (col in cols) {
        if (is_train) {
            categories <- sort(unique(df[[col]][!is.na(df[[col]]) & df[[col]] != ""]))
            new_mapping[[col]] <- categories
        } else {
            categories <- mapping[[col]]
        }

        # Create n-1 dummy variables
        if (length(categories) > 1) {
            for (i in 1:(length(categories) - 1)) {
                new_col_name <- paste0(col, "_", make.names(categories[i]))
                result[[new_col_name]] <- as.integer(df[[col]] == categories[i])
            }
        }

        result[[col]] <- NULL
    }

    if (is_train) {
        return(list(data = result, mapping = new_mapping))
    } else {
        return(list(data = result))
    }
}

# =============================================================================
# Frequency Encoding
# =============================================================================
#' Apply Frequency Encoding to specified columns
#' @param df Data frame
#' @param cols Columns to encode
#' @param is_train TRUE for training set
#' @param mapping Pre-computed mapping for test set
#' @return List with encoded data and mapping
apply_frequency_encoding <- function(df, cols, is_train = TRUE, mapping = NULL) {
    result <- df
    new_mapping <- list()

    cols <- intersect(cols, colnames(df))

    for (col in cols) {
        new_col_name <- paste0(col, "_FreqEnc")

        if (is_train) {
            freq_table <- df %>%
                count(.data[[col]]) %>%
                mutate(
                    frequency = n / nrow(df),
                    category_order = rank(.data[[col]], ties.method = "first")
                ) %>%
                mutate(adjusted_frequency = frequency + (category_order * 1e-10))

            new_mapping[[col]] <- freq_table
            result[[new_col_name]] <- freq_table$adjusted_frequency[match(df[[col]], freq_table[[col]])]
        } else {
            freq_table <- mapping[[col]]
            matched_freq <- freq_table$adjusted_frequency[match(df[[col]], freq_table[[col]])]
            matched_freq[is.na(matched_freq)] <- min(freq_table$adjusted_frequency, na.rm = TRUE)
            result[[new_col_name]] <- matched_freq
        }

        result[[col]] <- NULL
    }

    if (is_train) {
        return(list(data = result, mapping = new_mapping))
    } else {
        return(list(data = result))
    }
}

# =============================================================================
# Target Encoding (with K-Fold and Smoothing)
# =============================================================================
#' Apply Target Encoding with Bayesian smoothing
#' @param df Data frame
#' @param cols Columns to encode
#' @param target_col Target variable name
#' @param is_train TRUE for training set
#' @param mapping Pre-computed mapping for test set
#' @param n_folds Number of folds for out-of-fold encoding
#' @param min_samples_leaf Minimum samples for smoothing
#' @param smoothing Smoothing parameter
#' @return List with encoded data and mapping
apply_target_encoding <- function(df, cols, target_col,
                                  is_train = TRUE,
                                  mapping = NULL,
                                  n_folds = 5,
                                  min_samples_leaf = 20,
                                  smoothing = 10) {
    result <- df
    new_mapping <- list()

    cols <- intersect(cols, colnames(df))
    global_mean <- mean(df[[target_col]], na.rm = TRUE)

    for (col in cols) {
        new_col_name <- paste0(col, "_TargetEnc")

        if (is_train) {
            # K-Fold encoding to prevent leakage
            result_vec <- numeric(nrow(df))
            folds <- sample(rep(1:n_folds, length.out = nrow(df)))

            for (k in 1:n_folds) {
                idx_train_fold <- which(folds != k)
                idx_val_fold <- which(folds == k)

                df_train_fold <- df[idx_train_fold, ]

                stats <- df_train_fold %>%
                    group_by(.data[[col]]) %>%
                    summarise(
                        count = n(),
                        mean = mean(.data[[target_col]], na.rm = TRUE),
                        .groups = "drop"
                    )

                fold_global_mean <- mean(df_train_fold[[target_col]], na.rm = TRUE)
                stats$lambda <- 1 / (1 + exp(-(stats$count - min_samples_leaf) / smoothing))
                stats$smoothed_mean <- (stats$lambda * stats$mean) + ((1 - stats$lambda) * fold_global_mean)

                mapped_values <- stats$smoothed_mean[match(df[[col]][idx_val_fold], stats[[col]])]
                mapped_values[is.na(mapped_values)] <- fold_global_mean
                result_vec[idx_val_fold] <- mapped_values
            }

            result[[new_col_name]] <- result_vec

            # Generate global mapping for test set
            global_stats <- df %>%
                group_by(.data[[col]]) %>%
                summarise(
                    count = n(),
                    mean = mean(.data[[target_col]], na.rm = TRUE),
                    .groups = "drop"
                )
            global_stats$lambda <- 1 / (1 + exp(-(global_stats$count - min_samples_leaf) / smoothing))
            global_stats$smoothed_mean <- (global_stats$lambda * global_stats$mean) +
                ((1 - global_stats$lambda) * global_mean)

            new_mapping[[col]] <- list(stats = global_stats, global_mean = global_mean)
        } else {
            map_info <- mapping[[col]]
            global_stats <- map_info$stats
            gm <- map_info$global_mean

            mapped_values <- global_stats$smoothed_mean[match(df[[col]], global_stats[[col]])]
            mapped_values[is.na(mapped_values)] <- gm
            result[[new_col_name]] <- mapped_values
        }

        result[[col]] <- NULL
    }

    if (is_train) {
        return(list(data = result, mapping = new_mapping))
    } else {
        return(list(data = result))
    }
}
