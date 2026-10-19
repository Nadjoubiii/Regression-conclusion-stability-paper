#!/usr/bin/env Rscript
# run_simulation_scenario4.R
#
# Runs the full simulation grid for Scenario 4 (combined heterogeneity:
# shifted x means + shifted betas) using the same grid and replication
# budget as Scenarios 1--3.
#
# Output: results/grid_results_scenario4.csv

source("scripts/simulate.R")

# ── Grid: same settings as Scenarios 1--3 ──

group_counts   <- c(2, 3, 5, 15, 40)
total_n_values <- c(100, 300, 1200, 3000, 6000, 30000, 200000)
patterns       <- c("balanced", "mild", "strong", "random")
REPS           <- 30
CHECKPOINT_EVERY <- 20

grid <- expand.grid(
  G        = group_counts,
  total_n  = total_n_values,
  pattern  = patterns,
  stringsAsFactors = FALSE
)

n_settings <- nrow(grid)
cat(sprintf("Scenario 4 grid: %d settings x %d reps = %d total replicates\n",
                n_settings, REPS, n_settings * REPS))

# ── evaluate_setting for Scenario 4 ──

evaluate_setting_s4 <- function(n_per_group, reps = REPS, p = 2, rho = 0.2) {
  G <- length(n_per_group)
  ssr      <- numeric(reps)
  drift    <- numeric(reps)
  ctx_d    <- numeric(reps)
  tpg_m    <- numeric(reps)
  css_m    <- numeric(reps)
  has_na   <- rep(FALSE, reps)

  for (r in seq_len(reps)) {
    s <- scenario_combined_heterogeneity(
      n_per_group = n_per_group,
      p           = p,
      base_beta   = c(1, 0.8, -0.5),
      rho         = rho,
      sigma_y     = 1
    )
    m <- compute_all_metrics(s)
    ssr[r]   <- mean(m$sign_stability, na.rm = TRUE)
    drift[r] <- mean(m$coef_drift, na.rm = TRUE)
    ctx_d[r] <- mean(m$context_drift, na.rm = TRUE)
    tpg_m[r] <- mean(m$tpg, na.rm = TRUE)
    css_m[r] <- mean(m$css, na.rm = TRUE)
    has_na[r] <- any(is.na(c(ssr[r], drift[r], ctx_d[r], tpg_m[r], css_m[r])))
  }

  # Drop NA replicates
  if (any(has_na)) {
    keep <- !has_na
    ssr    <- ssr[keep]
    drift  <- drift[keep]
    ctx_d  <- ctx_d[keep]
    tpg_m  <- tpg_m[keep]
    css_m  <- css_m[keep]
  }
  n_eff <- length(ssr)

  ci <- function(x) {
    m <- mean(x)
    se <- sd(x) / sqrt(n_eff)
    c(lower = max(0, m - 1.96 * se), upper = m + 1.96 * se)
  }

  data.frame(
    n_reps_used  = n_eff,
    mean_ssr     = mean(ssr),
    sd_ssr       = sd(ssr),
    ci_low_ssr   = ci(ssr)["lower"],
    ci_high_ssr  = ci(ssr)["upper"],
    mean_drift   = mean(drift),
    sd_drift     = sd(drift),
    ci_low_drift = ci(drift)["lower"],
    ci_high_drift= ci(drift)["upper"],
    mean_ctx     = mean(ctx_d),
    sd_ctx       = sd(ctx_d),
    ci_low_ctx   = ci(ctx_d)["lower"],
    ci_high_ctx  = ci(ctx_d)["upper"],
    mean_tpg     = mean(tpg_m),
    sd_tpg       = sd(tpg_m),
    ci_low_tpg   = ci(tpg_m)["lower"],
    ci_high_tpg  = ci(tpg_m)["upper"],
    mean_css     = mean(css_m),
    sd_css       = sd(css_m),
    ci_low_css   = ci(css_m)["lower"],
    ci_high_css  = ci(css_m)["upper"],
    objective    = (1 - mean(ssr)) + mean(drift),
    stringsAsFactors = FALSE
  )
}

# ── Run grid ──

outfile <- "results/grid_results_scenario4.csv"
checkpoint_file <- paste0(outfile, ".checkpoint")
if (!dir.exists("results")) dir.create("results")

setting_key <- function(d) {
  paste(d$G, d$total_n, d$pattern, sep = "|")
}

completed <- data.frame()
if (file.exists(checkpoint_file)) {
  completed <- read.csv(checkpoint_file, stringsAsFactors = FALSE)
  required_columns <- c("G", "total_n", "pattern")

  if (!all(required_columns %in% names(completed))) {
    stop("Checkpoint is missing one or more grid columns: ", checkpoint_file)
  }

  completed_keys <- setting_key(completed)
  grid_keys <- setting_key(grid)
  if (anyDuplicated(completed_keys) || any(!completed_keys %in% grid_keys)) {
    stop("Checkpoint contains duplicate or incompatible settings: ", checkpoint_file)
  }

  cat(sprintf("Resuming from checkpoint: %d completed settings found.\n", nrow(completed)))
} else {
  completed_keys <- character()
  grid_keys <- setting_key(grid)
  cat("No checkpoint found. Starting all settings.\n")
}

remaining_indices <- which(!grid_keys %in% completed_keys)
rows <- vector("list", length(remaining_indices))

if (length(remaining_indices) == 0L) {
  cat("All grid settings are already present in the checkpoint.\n")
}

t_start <- Sys.time()
for (run_index in seq_along(remaining_indices)) {
  i <- remaining_indices[run_index]
  G        <- grid$G[i]
  total_n  <- grid$total_n[i]
  pattern  <- grid$pattern[i]

  n_per_group <- make_group_sizes(total_n, G, pattern)
  score <- evaluate_setting_s4(n_per_group, reps = REPS)

  rows[[run_index]] <- data.frame(
    scenario       = "S4_combined",
    G              = G,
    total_n        = total_n,
    pattern        = pattern,
    n_per_group    = paste(n_per_group, collapse = ","),
    avg_group_size = mean(n_per_group),
    min_group_size = min(n_per_group),
    score,
    stringsAsFactors = FALSE
  )

  # Progress
  elapsed <- difftime(Sys.time(), t_start, units = "mins")
  completed_count <- nrow(completed) + run_index
  cat(sprintf("[%3d/%3d] G=%-2d n=%-6d %-8s  SSR=%.3f drift=%.2f ctx=%.2f  | %5.1f min elapsed\n",
              completed_count, n_settings, G, total_n, pattern,
              score$mean_ssr, score$mean_drift, score$mean_ctx, elapsed))

  # Checkpoint
  if (completed_count %% CHECKPOINT_EVERY == 0) {
    tmp <- rbind(completed, do.call(rbind, rows[seq_len(run_index)]))
    write.csv(tmp, checkpoint_file, row.names = FALSE)
    cat(sprintf("  -> checkpoint saved (%d/%d settings)\n", completed_count, n_settings))
  }
}

new_rows <- if (length(rows) > 0L) do.call(rbind, rows) else data.frame()
res <- rbind(completed, new_rows)

if (nrow(res) != n_settings || anyDuplicated(setting_key(res))) {
  stop("Resume did not produce one unique result for each grid setting.")
}

res <- res[order(res$objective), ]

write.csv(res, outfile, row.names = FALSE)
write.csv(res, checkpoint_file, row.names = FALSE)

t_total <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("\nDone.  %d settings, %.1f minutes.  Output: %s\n",
                n_settings, t_total, outfile))
cat(sprintf("Top 5 by objective:\n"))
print(head(res[, c("G","total_n","pattern","mean_ssr","mean_drift","mean_ctx","objective")], 5))
