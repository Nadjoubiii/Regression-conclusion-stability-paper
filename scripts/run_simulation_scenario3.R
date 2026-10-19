#!/usr/bin/env Rscript
# Run Scenario 3 (coefficient heterogeneity only) on the same grid as Scenario 1.
# Run from the project root: Rscript scripts/run_simulation_scenario3.R

source("scripts/simulate.R")

out_dir <- "results"
out_file <- file.path(out_dir, "grid_results_scenario3.csv")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Same grid parameters and replication count as run_simulation_grid.R (Scenario 1).
group_counts <- c(2, 3, 5, 15, 40)
total_n_values <- c(100, 300, 1200, 3000, 6000, 30000, 200000)
patterns <- c("balanced", "mild", "strong", "random")
reps <- 30
checkpoint_every <- 20

grid <- expand.grid(
  G = group_counts,
  total_n = total_n_values,
  pattern = patterns,
  stringsAsFactors = FALSE
)
n_settings <- nrow(grid)

cat(sprintf(
  "Scenario 3 grid: %d settings, %d reps each = %d total replicates\n\n",
  n_settings, reps, n_settings * reps
))
flush.console()

# Evaluate one setting using only the coefficient-heterogeneity data-generating process.
evaluate_setting_s3 <- function(n_per_group, reps = 30) {
  ssr <- numeric(reps)
  drift <- numeric(reps)
  context_drift <- numeric(reps)
  tpg <- numeric(reps)
  css <- numeric(reps)
  has_na <- rep(FALSE, reps)

  for (replicate_index in seq_len(reps)) {
    scenario <- scenario_coefficient_heterogeneity(n_per_group = n_per_group)
    metrics <- compute_all_metrics(scenario)

    ssr[replicate_index] <- mean(metrics$sign_stability, na.rm = TRUE)
    drift[replicate_index] <- mean(metrics$coef_drift, na.rm = TRUE)
    context_drift[replicate_index] <- mean(metrics$context_drift, na.rm = TRUE)
    tpg[replicate_index] <- mean(metrics$tpg, na.rm = TRUE)
    css[replicate_index] <- mean(metrics$css, na.rm = TRUE)
    has_na[replicate_index] <- any(is.na(c(
      ssr[replicate_index], drift[replicate_index], context_drift[replicate_index],
      tpg[replicate_index], css[replicate_index]
    )))
  }

  if (any(has_na)) {
    keep <- !has_na
    ssr <- ssr[keep]
    drift <- drift[keep]
    context_drift <- context_drift[keep]
    tpg <- tpg[keep]
    css <- css[keep]
  }

  n_effective <- length(ssr)
  confidence_interval <- function(values) {
    mean_value <- mean(values)
    standard_error <- sd(values) / sqrt(n_effective)
    c(lower = max(0, mean_value - 1.96 * standard_error),
      upper = mean_value + 1.96 * standard_error)
  }

  data.frame(
    n_reps_used = n_effective,
    mean_ssr = mean(ssr),
    sd_ssr = sd(ssr),
    ci_low_ssr = confidence_interval(ssr)["lower"],
    ci_high_ssr = confidence_interval(ssr)["upper"],
    mean_drift = mean(drift),
    sd_drift = sd(drift),
    ci_low_drift = confidence_interval(drift)["lower"],
    ci_high_drift = confidence_interval(drift)["upper"],
    mean_ctx = mean(context_drift),
    sd_ctx = sd(context_drift),
    ci_low_ctx = confidence_interval(context_drift)["lower"],
    ci_high_ctx = confidence_interval(context_drift)["upper"],
    mean_tpg = mean(tpg),
    sd_tpg = sd(tpg),
    ci_low_tpg = confidence_interval(tpg)["lower"],
    ci_high_tpg = confidence_interval(tpg)["upper"],
    mean_css = mean(css),
    sd_css = sd(css),
    ci_low_css = confidence_interval(css)["lower"],
    ci_high_css = confidence_interval(css)["upper"],
    objective = (1 - mean(ssr)) + mean(drift),
    stringsAsFactors = FALSE
  )
}

t_start <- Sys.time()
rows <- vector("list", n_settings)

for (setting_index in seq_len(n_settings)) {
  G <- grid$G[setting_index]
  total_n <- grid$total_n[setting_index]
  pattern <- grid$pattern[setting_index]
  n_per_group <- make_group_sizes(total_n, G, pattern)
  score <- evaluate_setting_s3(n_per_group, reps = reps)

  rows[[setting_index]] <- data.frame(
    scenario = "S3_coefficient_heterogeneity",
    G = G,
    total_n = total_n,
    pattern = pattern,
    n_per_group = paste(n_per_group, collapse = ","),
    avg_group_size = mean(n_per_group),
    min_group_size = min(n_per_group),
    score,
    stringsAsFactors = FALSE
  )

  elapsed <- difftime(Sys.time(), t_start, units = "mins")
  cat(sprintf(
    " [%3d/%d] G=%d  n=%d  %-8s  min_n=%-4d  SSR=%.2f  drift=%.1f  ctx=%.1f  (%.1f min)\n",
    setting_index, n_settings, G, total_n, pattern, min(n_per_group),
    score$mean_ssr, score$mean_drift, score$mean_ctx, elapsed
  ))
  flush.console()

  if (setting_index %% checkpoint_every == 0) {
    checkpoint <- do.call(rbind, rows[seq_len(setting_index)])
    write.csv(checkpoint, file.path(out_dir, "grid_results_scenario3_checkpoint.csv"), row.names = FALSE)
    cat(sprintf("  --> checkpoint saved (%d settings)\n", setting_index))
    flush.console()
  }
}

results <- do.call(rbind, rows)
results <- results[order(results$objective), ]
write.csv(results, out_file, row.names = FALSE)

elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("\nDone in %.1f minutes\n", elapsed))
cat(sprintf("Saved %d rows to %s\n", nrow(results), out_file))
cat("--- Top 5 by objective ---\n")
print(head(results, 5))
