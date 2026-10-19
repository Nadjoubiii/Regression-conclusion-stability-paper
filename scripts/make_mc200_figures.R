#!/usr/bin/env Rscript
# Generate manuscript figures from the completed 200-replication simulation study.

suppressPackageStartupMessages(library(ggplot2))

input_dir <- "results/mc200"
output_dir <- file.path(input_dir, "figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

scenario_files <- c(
  S1 = file.path(input_dir, "grid_results_s1_mc200.csv"),
  S2 = file.path(input_dir, "grid_results_s2_mc200.csv"),
  S3 = file.path(input_dir, "grid_results_s3_mc200.csv"),
  S4 = file.path(input_dir, "grid_results_s4_mc200.csv")
)

scenario_labels <- c(
  S1 = "No heterogeneity",
  S2 = "Covariate shift only",
  S3 = "Coefficient heterogeneity only",
  S4 = "Combined heterogeneity"
)

data <- do.call(rbind, lapply(names(scenario_files), function(scenario_id) {
  d <- read.csv(scenario_files[[scenario_id]], stringsAsFactors = FALSE)
  d$scenario_id <- scenario_id
  d$scenario <- scenario_labels[[scenario_id]]
  d$shrink_pct <- 100 * (1 - d$mean_ctx / pmax(d$mean_drift, 1e-12))
  d
}))

retained <- data[data$min_group_size >= 3, ]
pattern_levels <- c("balanced", "mild", "strong", "random")
scenario_levels <- unname(scenario_labels[c("S1", "S2", "S3", "S4")])

theme_paper <- theme_minimal(base_size = 10) +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold")
  )

save_plot <- function(plot, filename, width, height) {
  ggsave(file.path(output_dir, filename), plot, width = width, height = height, dpi = 300)
}

save_two_panel <- function(left, right, filename, width, height) {
  grDevices::png(file.path(output_dir, filename), width = width, height = height, units = "in", res = 300)
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(1, 2)))
  print(left, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(right, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
  grid::popViewport()
  invisible(grDevices::dev.off())
}

pattern_palette <- c(
  balanced = "#1B9E77",
  mild = "#D95F02",
  strong = "#7570B3",
  random = "#E7298A"
)
scenario_palette <- c(S1 = "#1B9E77", S2 = "#7570B3", S3 = "#D95F02", S4 = "#E7298A")

s1 <- retained[retained$scenario_id == "S1", ]
s1$G <- factor(s1$G, levels = sort(unique(s1$G)))
s1$pattern <- factor(s1$pattern, levels = pattern_levels)

drift_aggregate <- aggregate(
  mean_drift ~ G + pattern,
  data = s1,
  FUN = function(x) c(med = median(x), q1 = as.numeric(quantile(x, 0.25)), q3 = as.numeric(quantile(x, 0.75)))
)
drift_summary <- data.frame(
  G = drift_aggregate$G,
  pattern = drift_aggregate$pattern,
  med = drift_aggregate$mean_drift[, "med"],
  q1 = drift_aggregate$mean_drift[, "q1"],
  q3 = drift_aggregate$mean_drift[, "q3"]
)
drift_summary$G <- factor(drift_summary$G, levels = levels(s1$G))
drift_summary$pattern <- factor(drift_summary$pattern, levels = pattern_levels)

drift_panel <- ggplot(drift_summary, aes(x = G, y = med, colour = pattern, group = pattern)) +
  geom_errorbar(aes(ymin = q1, ymax = q3), width = 0.10, linewidth = 0.45) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2) +
  scale_colour_manual(values = pattern_palette) +
  scale_y_log10(breaks = c(1, 3, 10, 30, 100)) +
  coord_cartesian(ylim = c(0.75, 150)) +
  labs(x = "Number of groups", y = "Median standardized drift (log scale)") +
  theme_paper

ssr_summary <- aggregate(
  list(share = as.numeric(s1$mean_ssr < 1)),
  list(G = s1$G, pattern = s1$pattern),
  mean
)
ssr_summary$G <- factor(ssr_summary$G, levels = levels(s1$G))
ssr_summary$pattern <- factor(ssr_summary$pattern, levels = pattern_levels)

ssr_panel <- ggplot(ssr_summary, aes(x = G, y = share, colour = pattern, group = pattern)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2) +
  scale_colour_manual(values = pattern_palette) +
  scale_y_continuous(limits = c(0, 1.02), breaks = seq(0, 1, by = 0.25)) +
  labs(x = "Number of groups", y = "Share of settings with SSR below 1") +
  theme_paper +
  theme(legend.position = "none")

save_two_panel(drift_panel, ssr_panel, "fig1_drift_ssr_mc200.png", 8.2, 3.9)

context_panel <- ggplot(s1, aes(x = mean_drift, y = mean_ctx, colour = pattern)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey45") +
  geom_point(size = 1.4, alpha = 0.45) +
  scale_colour_manual(values = pattern_palette) +
  scale_x_log10(breaks = c(1, 3, 10, 30, 100)) +
  scale_y_log10(breaks = c(1, 3, 10, 30, 100)) +
  coord_cartesian(xlim = c(0.75, 150), ylim = c(0.75, 150)) +
  labs(x = "Standardized drift", y = "Context-normalized drift") +
  theme_paper

retained$scenario_id <- factor(retained$scenario_id, levels = c("S1", "S2", "S3", "S4"))
css_labels <- aggregate(mean_css ~ scenario_id, data = retained, FUN = median)
css_label_map <- setNames(
  sprintf("%s\n(CSS %.2f)", css_labels$scenario_id, css_labels$mean_css),
  css_labels$scenario_id
)

shrink_panel <- ggplot(retained, aes(x = scenario_id, y = shrink_pct, colour = scenario_id)) +
  geom_boxplot(width = 0.55, fill = NA, colour = "grey35", outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 0.8, alpha = 0.45) +
  scale_colour_manual(values = scenario_palette) +
  scale_x_discrete(labels = css_label_map) +
  scale_y_continuous(limits = c(0, 52), breaks = seq(0, 50, by = 10)) +
  labs(x = "Scenario and median covariate shift", y = "Drift reduction after normalization (%)") +
  theme_paper +
  theme(legend.position = "none")

save_two_panel(context_panel, shrink_panel, "fig2_context_shrinkage_mc200.png", 8.2, 4.0)

heatmap <- ggplot(s1, aes(x = factor(total_n), y = factor(G), fill = log10(mean_drift))) +
  geom_tile(colour = "white", linewidth = 0.25) +
  facet_wrap(~ pattern, nrow = 1) +
  scale_fill_viridis_c(name = expression(log[10]("drift"))) +
  labs(x = "Total sample size", y = "Number of groups") +
  theme_paper +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_plot(heatmap, "drift_heatmap_mc200.png", 9.0, 3.5)

comparison <- ggplot(retained, aes(x = scenario, y = mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.5, show.legend = FALSE) +
  scale_y_log10() +
  scale_fill_brewer(palette = "Dark2", breaks = scenario_levels) +
  labs(x = NULL, y = "Mean standardized drift (log scale)") +
  theme_paper +
  theme(axis.text.x = element_text(angle = 18, hjust = 1))
save_plot(comparison, "scenario_drift_comparison_mc200.png", 6.0, 3.8)

cat("Saved 200-replication figures to", output_dir, "\n")