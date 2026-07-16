# Grid plotting script (separate from simulation logic)
# Produces ggplot visualizations for mean_ssr and mean_drift.

suppressPackageStartupMessages({
  library(ggplot2)
})

source("scripts/simulate.R")

plot_metric <- function(grid_results, metric, title, out_file) {
  stopifnot(metric %in% names(grid_results))

  df <- grid_results
  df$G <- factor(df$G)
  df$pattern <- factor(df$pattern, levels = c("balanced", "mild", "strong"))

  p <- ggplot(df, aes(x = avg_group_size, y = G, color = .data[[metric]])) +
    geom_point(size = 4, alpha = 0.9) +
    facet_wrap(~ pattern, nrow = 1) +
    scale_color_viridis_c(option = "C") +
    labs(
      title = title,
      subtitle = "x: average group size, y: number of groups, color: metric value",
      x = "Average group size",
      y = "Number of groups",
      color = metric
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold"),
      plot.title = element_text(face = "bold")
    )

  ggsave(out_file, plot = p, width = 11, height = 4.5, dpi = 160)
  p
}

main <- function(reps = 50, out_dir = "results") {
  dir.create(out_dir, showWarnings = FALSE)

  grid_results <- run_settings_grid(reps = reps)

  write.csv(grid_results, file.path(out_dir, "grid_results.csv"), row.names = FALSE)

  plot_metric(
    grid_results = grid_results,
    metric = "mean_ssr",
    title = "Grid Search: Mean Sign Stability",
    out_file = file.path(out_dir, "grid_mean_ssr_ggplot.png")
  )

  plot_metric(
    grid_results = grid_results,
    metric = "mean_drift",
    title = "Grid Search: Mean Coefficient Drift",
    out_file = file.path(out_dir, "grid_mean_drift_ggplot.png")
  )

  cat("Saved:\n")
  cat("-", file.path(out_dir, "grid_mean_ssr_ggplot.png"), "\n")
  cat("-", file.path(out_dir, "grid_mean_drift_ggplot.png"), "\n")
  cat("-", file.path(out_dir, "grid_results.csv"), "\n")

  invisible(grid_results)
}

if (identical(environment(), globalenv())) {
  main(reps = 50, out_dir = "results")
}
