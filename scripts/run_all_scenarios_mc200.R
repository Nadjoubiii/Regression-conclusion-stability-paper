#!/usr/bin/env Rscript
#
# Run the four simulation scenarios on one common grid with 200 Monte Carlo
# replications per scenario-setting cell. Existing 30-replication outputs are
# left unchanged under results/; this runner writes to results/mc200/.
#
# Run from the project root:
#   Rscript scripts/run_all_scenarios_mc200.R
#
# Optional override for exploratory runs:
#   Rscript scripts/run_all_scenarios_mc200.R 50

source("scripts/simulate.R")

args <- commandArgs(trailingOnly = TRUE)
reps <- if (length(args) == 0L) 200L else as.integer(args[1])
if (is.na(reps) || reps < 2L) {
  stop("The replication count must be an integer of at least 2.")
}

group_counts <- c(2, 3, 5, 15, 40)
total_n_values <- c(100, 300, 1200, 3000, 6000, 30000, 200000)
patterns <- c("balanced", "mild", "strong", "random")
checkpoint_every <- 5L
base_seed <- 20261015L

scenario_definitions <- list(
  list(id = "S1", label = "S1_no_heterogeneity", generator = scenario_no_heterogeneity),
  list(id = "S2", label = "S2_covariate_shift", generator = scenario_covariate_shift),
  list(id = "S3", label = "S3_coefficient_heterogeneity", generator = scenario_coefficient_heterogeneity),
  list(id = "S4", label = "S4_combined", generator = scenario_combined_heterogeneity)
)

out_dir <- file.path("results", paste0("mc", reps))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
checkpoint_file <- file.path(out_dir, paste0("all_scenarios_mc", reps, "_checkpoint.csv"))
combined_file <- file.path(out_dir, paste0("grid_results_all_scenarios_mc", reps, ".csv"))

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
run_grid$run_id <- seq_len(nrow(run_grid))

setting_key <- function(data) {
  paste(data$scenario_id, data$G, data$total_n, data$pattern, sep = "|")
}

evaluate_setting <- function(generator, n_per_group, reps) {
  ssr <- numeric(reps)
  drift <- numeric(reps)
  context_drift <- numeric(reps)
  tpg <- numeric(reps)
  css <- numeric(reps)
  has_na <- rep(FALSE, reps)

  for (replicate_index in seq_len(reps)) {
    scenario <- generator(n_per_group = n_per_group)
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

  keep <- !has_na
  if (sum(keep) < 2L) {
    stop("Fewer than two valid replicates remained for a simulation setting.")
  }

  ssr <- ssr[keep]
  drift <- drift[keep]
  context_drift <- context_drift[keep]
  tpg <- tpg[keep]
  css <- css[keep]
  n_effective <- length(ssr)

  confidence_interval <- function(values) {
    mean_value <- mean(values)
    standard_error <- sd(values) / sqrt(n_effective)
    c(
      lower = max(0, mean_value - 1.96 * standard_error),
      upper = mean_value + 1.96 * standard_error
    )
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

required_checkpoint_columns <- c("scenario_id", "scenario", "G", "total_n", "pattern")
completed <- data.frame()
if (file.exists(checkpoint_file)) {
  completed <- read.csv(checkpoint_file, stringsAsFactors = FALSE)
  if (!all(required_checkpoint_columns %in% names(completed))) {
    stop("Checkpoint is missing required columns: ", checkpoint_file)
  }

  completed_keys <- setting_key(completed)
  grid_keys <- setting_key(run_grid)
  if (anyDuplicated(completed_keys) || any(!completed_keys %in% grid_keys)) {
    stop("Checkpoint contains duplicate or incompatible scenario-setting rows.")
  }
  cat(sprintf("Resuming from checkpoint: %d completed scenario-setting rows found.\n", nrow(completed)))
} else {
  completed_keys <- character()
  grid_keys <- setting_key(run_grid)
  cat("No checkpoint found. Starting the full Monte Carlo study.\n")
}

remaining_indices <- which(!grid_keys %in% completed_keys)
total_replicates <- nrow(run_grid) * reps
cat(sprintf(
  "Four-scenario grid: %d scenario-setting rows x %d reps = %d total replicates\n",
  nrow(run_grid), reps, total_replicates
))
cat(sprintf("Remaining work: %d scenario-setting rows = %d replicates\n\n",
            length(remaining_indices), length(remaining_indices) * reps))
flush.console()

new_rows <- vector("list", length(remaining_indices))
started_at <- Sys.time()

for (remaining_index in seq_along(remaining_indices)) {
  grid_index <- remaining_indices[remaining_index]
  row <- run_grid[grid_index, ]
  scenario_definition <- scenario_definitions[[row$scenario_index]]

  # Use one reproducible group-size allocation per design cell across all scenarios.
  set.seed(base_seed + row$setting_id)
  n_per_group <- make_group_sizes(row$total_n, row$G, row$pattern)

  # Scenario-specific random streams preserve reproducibility on resume.
  set.seed(base_seed + 1000L * row$scenario_index + row$setting_id)
  score <- evaluate_setting(scenario_definition$generator, n_per_group, reps)

  new_rows[[remaining_index]] <- data.frame(
    scenario_id = row$scenario_id,
    scenario = row$scenario,
    G = row$G,
    total_n = row$total_n,
    pattern = row$pattern,
    n_per_group = paste(n_per_group, collapse = ","),
    avg_group_size = mean(n_per_group),
    min_group_size = min(n_per_group),
    score,
    stringsAsFactors = FALSE
  )

  completed_count <- nrow(completed) + remaining_index
  elapsed <- difftime(Sys.time(), started_at, units = "mins")
  cat(sprintf(
    "[%3d/%d] %s  G=%-2d n=%-6d %-8s min_n=%-4d SSR=%.3f drift=%.2f ctx=%.2f (%.1f min)\n",
    completed_count, nrow(run_grid), row$scenario_id, row$G, row$total_n,
    row$pattern, min(n_per_group), score$mean_ssr, score$mean_drift,
    score$mean_ctx, elapsed
  ))
  flush.console()

  if (completed_count %% checkpoint_every == 0L || remaining_index == length(remaining_indices)) {
    checkpoint <- rbind(completed, do.call(rbind, new_rows[seq_len(remaining_index)]))
    write.csv(checkpoint, checkpoint_file, row.names = FALSE)
    cat(sprintf("  --> checkpoint saved (%d/%d scenario-setting rows)\n", completed_count, nrow(run_grid)))
    flush.console()
  }
}

new_results <- if (length(new_rows) > 0L) do.call(rbind, new_rows) else data.frame()
results <- rbind(completed, new_results)

if (nrow(results) != nrow(run_grid) || anyDuplicated(setting_key(results))) {
  stop("The run did not produce one unique result for each scenario-setting row.")
}

results <- results[order(results$scenario_id, results$objective), ]
write.csv(results, combined_file, row.names = FALSE)
write.csv(results, checkpoint_file, row.names = FALSE)

for (scenario_id in vapply(scenario_definitions, `[[`, character(1), "id")) {
  scenario_results <- results[results$scenario_id == scenario_id, ]
  scenario_file <- file.path(out_dir, paste0("grid_results_", tolower(scenario_id), "_mc", reps, ".csv"))
  write.csv(scenario_results, scenario_file, row.names = FALSE)
}

elapsed <- difftime(Sys.time(), started_at, units = "mins")
cat(sprintf("\nDone in %.1f minutes.\n", elapsed))
cat(sprintf("Saved %d rows to %s\n", nrow(results), combined_file))
cat("Mean drift by scenario:\n")
print(aggregate(mean_drift ~ scenario_id, data = results, FUN = mean, na.rm = TRUE))