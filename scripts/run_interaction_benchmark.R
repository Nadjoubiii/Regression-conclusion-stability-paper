#!/usr/bin/env Rscript
#
# Reduced-grid benchmark of the standard slope-interaction F-test.
# Tests m2 (common slopes with group intercepts) against m3 (group-specific slopes)
# across the same four scenario mechanisms used in the main simulation study.

source("scripts/simulate.R")

args <- commandArgs(trailingOnly = TRUE)
reps <- if (length(args) == 0L) 200L else as.integer(args[1])
if (is.na(reps) || reps < 2L) {
  stop("The replication count must be an integer of at least 2.")
}

group_counts <- c(3, 15, 40)
total_n_values <- c(300, 3000, 30000)
patterns <- c("balanced", "random")
checkpoint_every <- 5L
alpha <- 0.05
base_seed <- 20261017L

scenario_definitions <- list(
  list(id = "S1", label = "S1_no_heterogeneity", generator = scenario_no_heterogeneity),
  list(id = "S2", label = "S2_covariate_shift", generator = scenario_covariate_shift),
  list(id = "S3", label = "S3_coefficient_heterogeneity", generator = scenario_coefficient_heterogeneity),
  list(id = "S4", label = "S4_combined", generator = scenario_combined_heterogeneity)
)

out_dir <- file.path("results", "interaction_benchmark")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
checkpoint_file <- file.path(out_dir, paste0("interaction_benchmark_mc", reps, "_checkpoint.csv"))
output_file <- file.path(out_dir, paste0("interaction_benchmark_mc", reps, ".csv"))

base_grid <- expand.grid(
  G = group_counts,
  total_n = total_n_values,
  pattern = patterns,
  stringsAsFactors = FALSE
)
base_grid$setting_id <- seq_len(nrow(base_grid))

run_grid <- do.call(rbind, lapply(seq_along(scenario_definitions), function(scenario_index) {
  scenario <- scenario_definitions[[scenario_index]]
  data.frame(
    scenario_id = scenario$id,
    scenario = scenario$label,
    scenario_index = scenario_index,
    base_grid,
    stringsAsFactors = FALSE
  )
}))

setting_key <- function(data) {
  paste(data$scenario_id, data$G, data$total_n, data$pattern, sep = "|")
}

evaluate_interaction_setting <- function(generator, n_per_group, reps, alpha) {
  p_values <- numeric(reps)
  has_na <- rep(FALSE, reps)

  for (replicate_index in seq_len(reps)) {
    scenario <- generator(n_per_group = n_per_group)
    data <- scenario$data
    group_intercept_design <- model.matrix(~ x1 + x2 + group, data = data)
    interaction_design <- model.matrix(~ x1 * group + x2 * group, data = data)
    group_intercept_fit <- lm.fit(group_intercept_design, data$y)
    interaction_fit <- lm.fit(interaction_design, data$y)

    rss_group_intercept <- sum(group_intercept_fit$residuals^2)
    rss_interaction <- sum(interaction_fit$residuals^2)
    numerator_df <- interaction_fit$rank - group_intercept_fit$rank
    denominator_df <- length(data$y) - interaction_fit$rank

    if (numerator_df <= 0L || denominator_df <= 0L || rss_interaction <= 0) {
      p_values[replicate_index] <- NA_real_
    } else {
      f_statistic <- ((rss_group_intercept - rss_interaction) / numerator_df) /
        (rss_interaction / denominator_df)
      p_values[replicate_index] <- pf(f_statistic, numerator_df, denominator_df, lower.tail = FALSE)
    }
    has_na[replicate_index] <- is.na(p_values[replicate_index])
  }

  p_values <- p_values[!has_na]
  n_effective <- length(p_values)
  if (n_effective < 2L) {
    stop("Fewer than two valid F-test replicates remained for a setting.")
  }

  rejection_rate <- mean(p_values < alpha)
  standard_error <- sqrt(rejection_rate * (1 - rejection_rate) / n_effective)

  data.frame(
    n_reps_used = n_effective,
    interaction_rejection_rate = rejection_rate,
    ci_low_rejection_rate = max(0, rejection_rate - 1.96 * standard_error),
    ci_high_rejection_rate = min(1, rejection_rate + 1.96 * standard_error),
    median_interaction_p_value = median(p_values),
    stringsAsFactors = FALSE
  )
}

required_columns <- c("scenario_id", "scenario", "G", "total_n", "pattern")
completed <- data.frame()
if (file.exists(checkpoint_file)) {
  completed <- read.csv(checkpoint_file, stringsAsFactors = FALSE)
  if (!all(required_columns %in% names(completed))) {
    stop("Checkpoint is missing required columns: ", checkpoint_file)
  }
  completed_keys <- setting_key(completed)
  grid_keys <- setting_key(run_grid)
  if (anyDuplicated(completed_keys) || any(!completed_keys %in% grid_keys)) {
    stop("Checkpoint contains duplicate or incompatible rows.")
  }
  cat(sprintf("Resuming from checkpoint: %d completed rows found.\n", nrow(completed)))
} else {
  completed_keys <- character()
  grid_keys <- setting_key(run_grid)
  cat("No checkpoint found. Starting the interaction benchmark.\n")
}

remaining_indices <- which(!grid_keys %in% completed_keys)
cat(sprintf(
  "Interaction benchmark: %d scenario-setting rows x %d reps = %d total replicates\n",
  nrow(run_grid), reps, nrow(run_grid) * reps
))
cat(sprintf("Remaining work: %d rows = %d replicates\n\n",
            length(remaining_indices), length(remaining_indices) * reps))
flush.console()

new_rows <- vector("list", length(remaining_indices))
started_at <- Sys.time()

for (remaining_index in seq_along(remaining_indices)) {
  grid_index <- remaining_indices[remaining_index]
  row <- run_grid[grid_index, ]
  scenario_definition <- scenario_definitions[[row$scenario_index]]

  set.seed(base_seed + row$setting_id)
  n_per_group <- make_group_sizes(row$total_n, row$G, row$pattern)

  set.seed(base_seed + 1000L * row$scenario_index + row$setting_id)
  benchmark <- evaluate_interaction_setting(
    scenario_definition$generator,
    n_per_group,
    reps,
    alpha
  )

  new_rows[[remaining_index]] <- data.frame(
    scenario_id = row$scenario_id,
    scenario = row$scenario,
    G = row$G,
    total_n = row$total_n,
    pattern = row$pattern,
    n_per_group = paste(n_per_group, collapse = ","),
    avg_group_size = mean(n_per_group),
    min_group_size = min(n_per_group),
    benchmark,
    stringsAsFactors = FALSE
  )

  completed_count <- nrow(completed) + remaining_index
  elapsed <- difftime(Sys.time(), started_at, units = "mins")
  cat(sprintf(
    "[%2d/%d] %s G=%-2d n=%-5d %-8s min_n=%-4d reject=%.3f (%.1f min)\n",
    completed_count, nrow(run_grid), row$scenario_id, row$G, row$total_n,
    row$pattern, min(n_per_group), benchmark$interaction_rejection_rate, elapsed
  ))
  flush.console()

  if (completed_count %% checkpoint_every == 0L || remaining_index == length(remaining_indices)) {
    checkpoint <- rbind(completed, do.call(rbind, new_rows[seq_len(remaining_index)]))
    write.csv(checkpoint, checkpoint_file, row.names = FALSE)
    cat(sprintf("  --> checkpoint saved (%d/%d rows)\n", completed_count, nrow(run_grid)))
    flush.console()
  }
}

new_results <- if (length(new_rows) > 0L) do.call(rbind, new_rows) else data.frame()
results <- rbind(completed, new_results)
if (nrow(results) != nrow(run_grid) || anyDuplicated(setting_key(results))) {
  stop("The benchmark did not produce one unique row per scenario-setting cell.")
}

results <- results[order(results$scenario_id, results$G, results$total_n, results$pattern), ]
write.csv(results, output_file, row.names = FALSE)
write.csv(results, checkpoint_file, row.names = FALSE)

summary <- aggregate(
  interaction_rejection_rate ~ scenario_id,
  data = results,
  FUN = function(values) c(mean = mean(values), median = median(values))
)
summary <- data.frame(
  scenario_id = summary$scenario_id,
  mean_rejection_rate = summary$interaction_rejection_rate[, "mean"],
  median_rejection_rate = summary$interaction_rejection_rate[, "median"],
  row.names = NULL
)
write.csv(summary, file.path(out_dir, paste0("interaction_benchmark_summary_mc", reps, ".csv")), row.names = FALSE)

elapsed <- difftime(Sys.time(), started_at, units = "mins")
cat(sprintf("\nDone in %.1f minutes. Saved %d rows to %s\n", elapsed, nrow(results), output_file))
print(summary, row.names = FALSE)