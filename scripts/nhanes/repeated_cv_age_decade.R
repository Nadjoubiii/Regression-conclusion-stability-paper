#!/usr/bin/env Rscript
# Repeated stratified cross-validation of pooled versus age-specific NHANES models.

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required. Install it before running this script.")
}

suppressPackageStartupMessages(library(ggplot2))

args <- commandArgs(trailingOnly = TRUE)
repeats <- if (length(args) >= 1L) as.integer(args[1]) else 20L
folds <- if (length(args) >= 2L) as.integer(args[2]) else 5L
if (is.na(repeats) || is.na(folds) || repeats < 1L || folds < 2L) {
  stop("Use positive repeats and at least two folds.")
}

rmse <- function(observed, predicted) {
  sqrt(mean((observed - predicted)^2))
}

assign_stratified_folds <- function(groups, folds) {
  assignment <- integer(length(groups))
  for (group_name in levels(groups)) {
    indices <- which(groups == group_name)
    assignment[indices] <- sample(rep(seq_len(folds), length.out = length(indices)))
  }
  assignment
}

main <- function(repeats, folds, out_dir = file.path("results", "nhanes_age_decade_cv")) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  raw_rds <- file.path("data", "raw", "nhanes_raw.rds")
  raw_csv <- file.path("data", "raw", "nhanes_raw.csv")
  if (file.exists(raw_rds)) {
    nhanes <- readRDS(raw_rds)
  } else if (file.exists(raw_csv)) {
    nhanes <- read.csv(raw_csv)
  } else {
    stop("NHANES raw data not found. Run scripts/nhanes/import_nhanes.R first.")
  }

  variables <- c("AgeDecade", "BMI", "Gender", "Poverty", "DirectChol", "Pulse", "BPSysAve")
  dat <- nhanes[, variables, drop = FALSE]
  dat <- dat[complete.cases(dat) & !is.na(dat$AgeDecade) & dat$AgeDecade != "", , drop = FALSE]
  dat$AgeDecade <- droplevels(factor(dat$AgeDecade))
  dat$Gender <- droplevels(factor(dat$Gender))

  formula_obj <- BMI ~ Gender + Poverty + DirectChol + Pulse + BPSysAve
  set.seed(20261017L)
  rows <- vector("list", repeats * folds * nlevels(dat$AgeDecade))
  row_index <- 0L
  started_at <- Sys.time()

  for (repeat_index in seq_len(repeats)) {
    fold_id <- assign_stratified_folds(dat$AgeDecade, folds)

    for (fold_index in seq_len(folds)) {
      train <- dat[fold_id != fold_index, , drop = FALSE]
      test <- dat[fold_id == fold_index, , drop = FALSE]
      pooled_model <- lm(formula_obj, data = train)

      for (group_name in levels(dat$AgeDecade)) {
        train_group <- train[train$AgeDecade == group_name, , drop = FALSE]
        test_group <- test[test$AgeDecade == group_name, , drop = FALSE]
        group_model <- lm(formula_obj, data = train_group)

        pooled_rmse <- rmse(test_group$BMI, predict(pooled_model, newdata = test_group))
        group_rmse <- rmse(test_group$BMI, predict(group_model, newdata = test_group))

        row_index <- row_index + 1L
        rows[[row_index]] <- data.frame(
          repeat_id = repeat_index,
          fold = fold_index,
          AgeDecade = group_name,
          n_test = nrow(test_group),
          pooled_rmse = pooled_rmse,
          group_rmse = group_rmse,
          rmse_difference = pooled_rmse - group_rmse,
          stringsAsFactors = FALSE
        )
      }
    }

    elapsed <- difftime(Sys.time(), started_at, units = "mins")
    cat(sprintf("[%2d/%d] completed repeated five-fold validation (%.1f min)\n",
                repeat_index, repeats, elapsed))
    flush.console()
  }

  fold_results <- do.call(rbind, rows)
  write.csv(fold_results, file.path(out_dir, "repeated_cv_fold_results.csv"), row.names = FALSE)

  summary_rows <- lapply(split(fold_results, fold_results$AgeDecade), function(group_results) {
    difference <- group_results$rmse_difference
    standard_error <- sd(difference) / sqrt(length(difference))
    data.frame(
      AgeDecade = group_results$AgeDecade[1],
      evaluations = nrow(group_results),
      mean_pooled_rmse = mean(group_results$pooled_rmse),
      mean_group_rmse = mean(group_results$group_rmse),
      mean_rmse_difference = mean(difference),
      sd_rmse_difference = sd(difference),
      ci_low_rmse_difference = mean(difference) - 1.96 * standard_error,
      ci_high_rmse_difference = mean(difference) + 1.96 * standard_error,
      stringsAsFactors = FALSE
    )
  })
  summary <- do.call(rbind, summary_rows)
  summary$AgeDecade <- factor(summary$AgeDecade, levels = levels(dat$AgeDecade))
  summary <- summary[order(summary$AgeDecade), ]
  write.csv(summary, file.path(out_dir, "repeated_cv_summary_by_age_decade.csv"), row.names = FALSE)

  overall_difference <- fold_results$rmse_difference
  overall_standard_error <- sd(overall_difference) / sqrt(length(overall_difference))
  overall <- data.frame(
    repeats = repeats,
    folds = folds,
    evaluations = length(overall_difference),
    mean_rmse_difference = mean(overall_difference),
    ci_low_rmse_difference = mean(overall_difference) - 1.96 * overall_standard_error,
    ci_high_rmse_difference = mean(overall_difference) + 1.96 * overall_standard_error
  )
  write.csv(overall, file.path(out_dir, "repeated_cv_overall_summary.csv"), row.names = FALSE)

  plot <- ggplot(summary, aes(x = AgeDecade, y = mean_rmse_difference)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
    geom_errorbar(aes(ymin = ci_low_rmse_difference, ymax = ci_high_rmse_difference), width = 0.15) +
    geom_point(size = 2.2, colour = "firebrick4") +
    labs(
      x = "Age decade",
      y = "Pooled RMSE minus group-specific RMSE",
      title = "Repeated Held-Out Prediction Comparison"
    ) +
    theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 35, hjust = 1))
  ggsave(file.path(out_dir, "repeated_cv_rmse_difference_by_age_decade.png"), plot, width = 9, height = 4.8, dpi = 300)

  cat("Saved repeated cross-validation outputs to", out_dir, "\n")
  print(summary, row.names = FALSE)
  print(overall, row.names = FALSE)
}

main(repeats = repeats, folds = folds)