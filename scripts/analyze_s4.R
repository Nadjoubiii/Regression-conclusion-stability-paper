d <- read.csv("results/grid_results_scenario4.csv.checkpoint")

cat(sprintf("Settings: %d\n", nrow(d)))
cat(sprintf("Reps used range: %d - %d\n", min(d$n_reps_used), max(d$n_reps_used)))
cat(sprintf("SSR range: %.3f - %.3f\n", min(d$mean_ssr), max(d$mean_ssr)))
cat(sprintf("Drift range: %.1f - %.1f\n", min(d$mean_drift), max(d$mean_drift)))
cat(sprintf("Context drift range: %.1f - %.1f\n", min(d$mean_ctx), max(d$mean_ctx)))
cat(sprintf("TPG range: %.3f - %.3f\n", min(d$mean_tpg), max(d$mean_tpg)))
cat(sprintf("CSS range: %.3f - %.3f\n", min(d$mean_css), max(d$mean_css)))

cat("\n--- SSR < 1 settings ---\n")
w <- which(d$mean_ssr < 1)
cat(sprintf("Settings with SSR < 1: %d of %d (%.1f%%)\n", length(w), nrow(d), 100*length(w)/nrow(d)))
if(length(w) > 0) {
  cat(sprintf("Min SSR: %.3f at G=%d n=%d %s\n", min(d$mean_ssr), d$G[which.min(d$mean_ssr)], d$total_n[which.min(d$mean_ssr)], d$pattern[which.min(d$mean_ssr)]))
}

cat("\n--- SSR by pattern (median) ---\n")
for(p in unique(d$pattern)) {
  sub <- d[d$pattern == p, ]
  cat(sprintf("%s: median SSR=%.3f, mean SSR=%.3f\n", p, median(sub$mean_ssr), mean(sub$mean_ssr)))
}

cat("\n--- SSR by G (median) ---\n")
for(g in sort(unique(d$G))) {
  sub <- d[d$G == g, ]
  cat(sprintf("G=%d: median SSR=%.3f, mean SSR=%.3f\n", g, median(sub$mean_ssr), mean(sub$mean_ssr)))
}

cat("\n--- Drift by pattern (median, min_n >= 3) ---\n")
d3 <- d[d$min_group_size >= 3, ]
for(p in unique(d3$pattern)) {
  sub <- d3[d3$pattern == p, ]
  cat(sprintf("%s: median drift=%.1f, mean drift=%.1f\n", p, median(sub$mean_drift), mean(sub$mean_drift)))
}

cat("\n--- Context vs Raw drift shrinkage ---\n")
shrink <- (d3$mean_drift - d3$mean_ctx) / pmax(d3$mean_drift, 1e-8) * 100
cat(sprintf("Median shrinkage: %.1f%%\n", median(shrink)))
cat(sprintf("Range: %.1f%% - %.1f%%\n", min(shrink), max(shrink)))

cat("\n--- Degenerate settings (min_n < 3) ---\n")
bad <- d[d$min_group_size < 3, ]
cat(sprintf("Count: %d\n", nrow(bad)))
if(nrow(bad) > 0) print(bad[, c("G","total_n","pattern","min_group_size","mean_ssr","mean_drift")])

cat("\n--- Top 10 worst SSR ---\n")
o <- order(d$mean_ssr)
print(head(d[o, c("G","total_n","pattern","min_group_size","mean_ssr","mean_drift","mean_ctx","mean_tpg")], 10))
