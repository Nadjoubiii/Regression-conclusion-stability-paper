# Run the full simulation grid and save results.
# Source from project root: Rscript scripts/run_simulation_grid.R
#
# Prints progress after each setting and saves intermediate CSVs
# so you can check progress while it runs.

source("scripts/simulate.R")

out_dir  <- "results"
out_file <- file.path(out_dir, "grid_results.csv")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

group_counts   <- c(2, 3, 5, 15, 40)
total_n_values <- c(100, 300, 1200, 3000, 6000, 30000, 200000)
patterns       <- c("balanced", "mild", "strong", "random")
reps           <- 30

grid   <- expand.grid(G = group_counts, total_n = total_n_values,
                      pattern = patterns, stringsAsFactors = FALSE)
n_settings <- nrow(grid)
total_runs <- n_settings * reps   # 4200

cat(sprintf("Grid: %d settings, %d reps each = %d total replicates\n\n",
            n_settings, reps, total_runs))
flush.console()

t0   <- Sys.time()
rows <- vector("list", n_settings)

for (i in seq_len(n_settings)) {
  G       <- grid$G[i]
  total_n <- grid$total_n[i]
  pattern <- grid$pattern[i]

  n_per_group <- make_group_sizes(total_n, G, pattern)
  score       <- evaluate_setting(n_per_group, reps = reps)

  rows[[i]] <- data.frame(
    G              = G,
    total_n        = total_n,
    pattern        = pattern,
    n_per_group    = paste(n_per_group, collapse = ","),
    avg_group_size = mean(n_per_group),
    min_group_size = min(n_per_group),
    score,
    stringsAsFactors = FALSE
  )

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  cat(sprintf(
    " [%3d/%d] G=%d  n=%d  %-8s  min_n=%-4d  SSR=%.2f  drift=%.1f  ctx=%.1f  (%.1f min)\n",
    i, n_settings, G, total_n, pattern, min(n_per_group),
    score$mean_ssr, score$mean_drift, score$mean_ctx, elapsed
  ))
  flush.console()

  # Save intermediate checkpoint every 20 settings
  if (i %% 20 == 0) {
    tmp <- do.call(rbind, rows[1:i])
    write.csv(tmp, file.path(out_dir, "grid_results_checkpoint.csv"), row.names = FALSE)
    cat(sprintf("  --> checkpoint saved (%d settings)\n", i))
    flush.console()
  }
}

res <- do.call(rbind, rows)
res <- res[order(res$objective), ]

t1 <- Sys.time()
elapsed <- difftime(t1, t0, units = "mins")
write.csv(res, out_file, row.names = FALSE)

cat(sprintf("\nDone in %.1f minutes\n", elapsed))
cat(sprintf("Saved %d rows to %s\n", nrow(res), out_file))
cat(sprintf("Columns: %s\n\n", paste(names(res), collapse = ", ")))

cat("--- Top 5 by objective ---\n")
print(head(res[order(res$objective), ], 5))

cat("\n--- NA rows:", sum(is.na(res$mean_ssr)), "---\n")

cat("\n--- Mean drift by G ---\n")
print(aggregate(mean_drift ~ G, data = res, FUN = mean, na.rm = TRUE))

cat("\n--- Mean drift by pattern ---\n")
print(aggregate(mean_drift ~ pattern, data = res, FUN = mean, na.rm = TRUE))
