# NHANES subgroup regression analysis by age decade.

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required. Install it before running this script.")
}

suppressPackageStartupMessages({
  library(ggplot2)
})

compute_sign_stability <- function(group_models) {
  coefs <- do.call(rbind, lapply(group_models, coef))
  coefs <- coefs[, colnames(coefs) != "(Intercept)", drop = FALSE]
  pairs <- combn(seq_len(nrow(coefs)), 2, simplify = FALSE)

  ssr_vals <- sapply(seq_len(ncol(coefs)), function(j) {
    betas <- coefs[, j]
    mean(vapply(pairs, function(p) {
      as.integer(sign(betas[p[1]]) == sign(betas[p[2]]))
    }, integer(1)))
  })

  setNames(as.numeric(ssr_vals), colnames(coefs))
}

compute_standardized_drift <- function(pooled_model, group_models) {
  pooled_table <- summary(pooled_model)$coefficients
  pooled_coef <- pooled_table[, "Estimate"]
  pooled_se <- pooled_table[, "Std. Error"]
  names(pooled_coef) <- rownames(pooled_table)
  names(pooled_se) <- rownames(pooled_table)

  pooled_coef <- pooled_coef[names(pooled_coef) != "(Intercept)"]
  pooled_se <- pooled_se[names(pooled_se) != "(Intercept)"]

  coefs <- do.call(rbind, lapply(group_models, coef))
  coefs <- coefs[, colnames(coefs) != "(Intercept)", drop = FALSE]

  terms <- intersect(colnames(coefs), names(pooled_coef))
  drift_vals <- sapply(terms, function(term) {
    max_dev <- max(abs(coefs[, term] - pooled_coef[term]), na.rm = TRUE)
    max_dev / pmax(pooled_se[term], 1e-8)
  })

  setNames(as.numeric(drift_vals), terms)
}

compute_mean_spread <- function(data, formula_obj, group_var) {
  design <- model.matrix(formula_obj, data = data)
  design <- design[, colnames(design) != "(Intercept)", drop = FALSE]
  groups <- levels(data[[group_var]])
  pairs <- combn(groups, 2, simplify = FALSE)

  pooled_sd <- apply(design, 2, sd, na.rm = TRUE)

  spread_vals <- sapply(colnames(design), function(term) {
    diffs <- vapply(pairs, function(pair) {
      g1 <- pair[1]
      g2 <- pair[2]
      m1 <- mean(design[data[[group_var]] == g1, term], na.rm = TRUE)
      m2 <- mean(design[data[[group_var]] == g2, term], na.rm = TRUE)
      abs(m1 - m2)
    }, numeric(1))

    mean(diffs, na.rm = TRUE) / pmax(pooled_sd[[term]], 1e-8)
  })

  setNames(as.numeric(spread_vals), colnames(design))
}

main <- function(min_group_n = 80, out_dir = file.path("results", "nhanes_age_decade")) {
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

  vars <- c("AgeDecade", "BMI", "Gender", "Poverty", "DirectChol", "Pulse", "BPSysAve")
  missing_vars <- setdiff(vars, names(nhanes))
  if (length(missing_vars) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing_vars, collapse = ", ")))
  }

  dat <- nhanes[, vars, drop = FALSE]
  dat <- dat[complete.cases(dat), , drop = FALSE]
  dat <- dat[!is.na(dat$AgeDecade) & dat$AgeDecade != "", , drop = FALSE]

  dat$AgeDecade <- droplevels(factor(dat$AgeDecade))
  dat$Gender <- droplevels(factor(dat$Gender))

  counts <- as.data.frame(table(dat$AgeDecade), stringsAsFactors = FALSE)
  names(counts) <- c("AgeDecade", "n")
  write.csv(counts, file.path(out_dir, "age_decade_group_counts.csv"), row.names = FALSE)

  valid_groups <- counts$AgeDecade[counts$n >= min_group_n]
  if (length(valid_groups) < 2) {
    stop("Not enough age-decade groups meet min_group_n. Lower min_group_n and rerun.")
  }

  dat <- dat[dat$AgeDecade %in% valid_groups, , drop = FALSE]
  dat$AgeDecade <- droplevels(dat$AgeDecade)

  formula_obj <- BMI ~ Gender + Poverty + DirectChol + Pulse + BPSysAve
  pooled_model <- lm(formula_obj, data = dat)

  split_data <- split(dat, dat$AgeDecade)
  group_models <- lapply(split_data, function(df) lm(formula_obj, data = df))

  pooled_coef_df <- data.frame(
    model = "pooled",
    AgeDecade = "pooled",
    term = names(coef(pooled_model)),
    estimate = as.numeric(coef(pooled_model)),
    std_error = as.numeric(summary(pooled_model)$coefficients[, "Std. Error"]),
    stringsAsFactors = FALSE
  )

  coef_rows <- lapply(names(group_models), function(g) {
    model <- group_models[[g]]
    coef_tab <- summary(model)$coefficients
    data.frame(
      model = "group",
      AgeDecade = g,
      term = rownames(coef_tab),
      estimate = as.numeric(coef_tab[, "Estimate"]),
      std_error = as.numeric(coef_tab[, "Std. Error"]),
      stringsAsFactors = FALSE
    )
  })
  coef_df <- rbind(pooled_coef_df, do.call(rbind, coef_rows))
  coef_df$ci_low <- coef_df$estimate - 1.96 * coef_df$std_error
  coef_df$ci_high <- coef_df$estimate + 1.96 * coef_df$std_error
  write.csv(coef_df, file.path(out_dir, "coefficients_by_age_decade.csv"), row.names = FALSE)

  ssr <- compute_sign_stability(group_models)
  drift <- compute_standardized_drift(pooled_model, group_models)
  mean_spread <- compute_mean_spread(dat, formula_obj, group_var = "AgeDecade")
  predictor_metrics <- data.frame(
    term = names(ssr),
    ssr = as.numeric(ssr),
    drift = as.numeric(drift[names(ssr)]),
    mean_spread = as.numeric(mean_spread[names(ssr)]),
    stringsAsFactors = FALSE
  )
  predictor_metrics$context_drift <- predictor_metrics$drift / (1 + predictor_metrics$mean_spread)
  predictor_metrics$objective_component <- (1 - predictor_metrics$ssr) + predictor_metrics$drift
  write.csv(predictor_metrics, file.path(out_dir, "predictor_stability_metrics.csv"), row.names = FALSE)

  overall <- data.frame(
    num_groups = length(group_models),
    n_used = nrow(dat),
    mean_ssr = mean(predictor_metrics$ssr, na.rm = TRUE),
    mean_drift = mean(predictor_metrics$drift, na.rm = TRUE),
    mean_context_drift = mean(predictor_metrics$context_drift, na.rm = TRUE),
    objective = (1 - mean(predictor_metrics$ssr, na.rm = TRUE)) + mean(predictor_metrics$drift, na.rm = TRUE)
  )
  write.csv(overall, file.path(out_dir, "overall_stability_summary.csv"), row.names = FALSE)

  p_counts <- ggplot(counts, aes(x = reorder(AgeDecade, n), y = n)) +
    geom_col(fill = "steelblue3") +
    coord_flip() +
    labs(title = "NHANES: Sample Size by Age Decade", x = "Age Decade", y = "Count") +
    theme_minimal(base_size = 13)
  ggsave(file.path(out_dir, "age_decade_counts.png"), p_counts, width = 8, height = 5, dpi = 160)

  coef_plot_df <- coef_df[coef_df$model == "group" & coef_df$term != "(Intercept)", , drop = FALSE]
  p_coef <- ggplot(coef_plot_df, aes(x = AgeDecade, y = estimate, group = term, color = term)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2) +
    labs(title = "Coefficients by Age Decade", x = "Age Decade", y = "Estimate", color = "Term") +
    theme_minimal(base_size = 13) +
    theme(axis.text.x = element_text(angle = 35, hjust = 1))
  ggsave(file.path(out_dir, "coefficients_by_age_decade.png"), p_coef, width = 10, height = 5.5, dpi = 160)

  bpsys_plot_df <- coef_df[
    coef_df$model == "group" & coef_df$term == "BPSysAve",
    c("AgeDecade", "estimate", "ci_low", "ci_high"),
    drop = FALSE
  ]
  bpsys_plot_df$AgeDecade <- factor(bpsys_plot_df$AgeDecade, levels = levels(dat$AgeDecade))

  pooled_bpsys <- coef_df[coef_df$model == "pooled" & coef_df$term == "BPSysAve", , drop = FALSE]

  p_bpsys_ci <- ggplot(bpsys_plot_df, aes(x = AgeDecade, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dotted", color = "gray45") +
    annotate(
      "rect",
      xmin = -Inf,
      xmax = Inf,
      ymin = pooled_bpsys$ci_low[1],
      ymax = pooled_bpsys$ci_high[1],
      fill = "gray80",
      alpha = 0.5
    ) +
    geom_hline(yintercept = pooled_bpsys$estimate[1], linetype = "dashed", color = "black") +
    geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.15, color = "firebrick4") +
    geom_point(size = 2.4, color = "firebrick4") +
    geom_line(group = 1, color = "firebrick4", linewidth = 0.8) +
    labs(
      title = "BPSysAve Coefficient by Age Decade",
      subtitle = "Points and bars: subgroup estimates with 95% CI; dashed line and gray band: pooled estimate with 95% CI",
      x = "Age Decade",
      y = "Coefficient Estimate"
    ) +
    theme_minimal(base_size = 13) +
    theme(axis.text.x = element_text(angle = 35, hjust = 1))
  ggsave(file.path(out_dir, "bpsys_coef_by_age_decade_ci.png"), p_bpsys_ci, width = 10, height = 5.8, dpi = 160)

  # Predicted BMI across DirectChol: pooled line and one line per age-decade model.
  x_var <- "DirectChol"
  x_grid <- seq(
    quantile(dat[[x_var]], 0.05, na.rm = TRUE),
    quantile(dat[[x_var]], 0.95, na.rm = TRUE),
    length.out = 120
  )

  ref_gender <- levels(dat$Gender)[1]
  ref_poverty <- median(dat$Poverty, na.rm = TRUE)
  ref_pulse <- median(dat$Pulse, na.rm = TRUE)
  ref_bpsys <- median(dat$BPSysAve, na.rm = TRUE)

  base_newdata <- data.frame(
    Gender = factor(rep(ref_gender, length(x_grid)), levels = levels(dat$Gender)),
    Poverty = rep(ref_poverty, length(x_grid)),
    DirectChol = x_grid,
    Pulse = rep(ref_pulse, length(x_grid)),
    BPSysAve = rep(ref_bpsys, length(x_grid))
  )

  pooled_curve <- data.frame(
    model = "pooled",
    AgeDecade = "pooled",
    DirectChol = x_grid,
    pred_BMI = as.numeric(predict(pooled_model, newdata = base_newdata)),
    stringsAsFactors = FALSE
  )

  group_curves <- do.call(rbind, lapply(names(group_models), function(g) {
    data.frame(
      model = "group",
      AgeDecade = g,
      DirectChol = x_grid,
      pred_BMI = as.numeric(predict(group_models[[g]], newdata = base_newdata)),
      stringsAsFactors = FALSE
    )
  }))

  fitted_curves <- rbind(pooled_curve, group_curves)
  write.csv(fitted_curves, file.path(out_dir, "fitted_curves_directchol.csv"), row.names = FALSE)

  p_fitted <- ggplot() +
    geom_line(
      data = group_curves,
      aes(x = DirectChol, y = pred_BMI, color = AgeDecade, group = AgeDecade),
      linewidth = 1,
      alpha = 0.9
    ) +
    geom_line(
      data = pooled_curve,
      aes(x = DirectChol, y = pred_BMI),
      color = "black",
      linetype = "dashed",
      linewidth = 1.2
    ) +
    labs(
      title = "Pooled vs Age-Decade Fitted Curves",
      subtitle = "Predicted BMI vs Direct Cholesterol (other covariates fixed at reference values)",
      x = "Direct Cholesterol",
      y = "Predicted BMI",
      color = "Age Decade"
    ) +
    theme_minimal(base_size = 13)
  ggsave(file.path(out_dir, "fitted_pooled_vs_groups_directchol.png"), p_fitted, width = 10, height = 6, dpi = 160)

  drift_plot_df <- predictor_metrics[is.finite(predictor_metrics$drift), , drop = FALSE]
  p_drift <- ggplot(drift_plot_df, aes(x = reorder(term, drift), y = drift)) +
    geom_col(fill = "firebrick3") +
    coord_flip() +
    labs(title = "Standardized Drift by Predictor", x = "Predictor", y = "Drift") +
    theme_minimal(base_size = 13)
  ggsave(file.path(out_dir, "predictor_drift.png"), p_drift, width = 8, height = 5, dpi = 160)

  ssr_plot_df <- predictor_metrics[is.finite(predictor_metrics$ssr), , drop = FALSE]
  p_ssr <- ggplot(ssr_plot_df, aes(x = reorder(term, ssr), y = ssr)) +
    geom_col(fill = "darkgreen") +
    coord_flip() +
    scale_y_continuous(limits = c(0, 1)) +
    labs(title = "Sign Stability Rate by Predictor", x = "Predictor", y = "SSR") +
    theme_minimal(base_size = 13)
  ggsave(file.path(out_dir, "predictor_ssr.png"), p_ssr, width = 8, height = 5, dpi = 160)

  cat("Saved outputs to", out_dir, "\n")
  cat("-", file.path(out_dir, "age_decade_group_counts.csv"), "\n")
  cat("-", file.path(out_dir, "coefficients_by_age_decade.csv"), "\n")
  cat("-", file.path(out_dir, "predictor_stability_metrics.csv"), "\n")
  cat("-", file.path(out_dir, "overall_stability_summary.csv"), "\n")
  cat("-", file.path(out_dir, "age_decade_counts.png"), "\n")
  cat("-", file.path(out_dir, "coefficients_by_age_decade.png"), "\n")
  cat("-", file.path(out_dir, "bpsys_coef_by_age_decade_ci.png"), "\n")
  cat("-", file.path(out_dir, "fitted_curves_directchol.csv"), "\n")
  cat("-", file.path(out_dir, "fitted_pooled_vs_groups_directchol.png"), "\n")
  cat("-", file.path(out_dir, "predictor_drift.png"), "\n")
  cat("-", file.path(out_dir, "predictor_ssr.png"), "\n")

  invisible(list(data = dat, pooled_model = pooled_model, group_models = group_models, metrics = predictor_metrics))
}

if (identical(environment(), globalenv())) {
  main(min_group_n = 80, out_dir = file.path("results", "nhanes_age_decade"))
}