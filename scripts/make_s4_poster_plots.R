# Generate S4 plots for poster
library(ggplot2)

d4 <- read.csv("results/grid_results_scenario4.csv")
d4 <- d4[d4$min_group_size >= 3, ]
d4$G <- factor(d4$G)
d4$pattern <- factor(d4$pattern, levels = c("balanced","mild","strong","random"))

dir.create("results/simulation", showWarnings = FALSE)

# ── 1. SSR boxplot for S4 ──
png("results/simulation/s4_ssr_by_G.png", w = 1000, h = 700, res = 130)
ggplot(d4, aes(x = G, y = mean_ssr, fill = pattern)) +
  geom_boxplot(outlier.size = 1, position = position_dodge(0.8)) +
  ylim(0.5, 1.05) +
  labs(title = "SSR in Scenario 4 (Combined Heterogeneity)",
       subtitle = "settings with min_n >= 3",
       y = "mean SSR", x = "number of groups") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom")
dev.off()
message("Done: s4_ssr_by_G.png")

# ── 2. Drift boxplot for S4 ──
png("results/simulation/s4_drift_by_G.png", w = 1000, h = 700, res = 130)
ggplot(d4, aes(x = G, y = mean_drift, fill = pattern)) +
  geom_boxplot(outlier.size = 1, position = position_dodge(0.8)) +
  scale_y_log10() +
  labs(title = "Standardized Drift in Scenario 4",
       subtitle = "log scale; min_n >= 3",
       y = "mean standardized drift (log scale)", x = "number of groups") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom")
dev.off()
message("Done: s4_drift_by_G.png")

# ── 3. S4 context vs raw drift ──
png("results/simulation/s4_context_vs_raw.png", w = 1000, h = 800, res = 130)
ggplot(d4, aes(x = mean_drift, y = mean_ctx, color = G, shape = pattern)) +
  geom_abline(slope = 1, linetype = "dashed", color = "gray50") +
  geom_point(size = 2.5, alpha = 0.8) +
  scale_x_log10() + scale_y_log10() +
  labs(title = "Context-Normalized vs Raw Drift (Scenario 4)",
       subtitle = "points below 1:1 line = context shrinks drift; log-log",
       x = "mean standardized drift", y = "mean context-normalized drift") +
  theme_minimal(base_size = 13)
dev.off()
message("Done: s4_context_vs_raw.png")

# ── 4. S1 vs S4 drift comparison (side by side) ──
d1 <- read.csv("results/grid_results.csv")
d1 <- d1[d1$min_group_size >= 3, ]
d1$scenario <- "S1"
d4$scenario <- "S4"

sel_cols <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_ctx","scenario")
comp <- rbind(d1[, sel_cols], d4[, sel_cols])
comp$scenario <- factor(comp$scenario, levels = c("S1","S4"))
comp$G <- factor(comp$G)

png("results/simulation/s1_vs_s4_drift.png", w = 1100, h = 700, res = 130)
ggplot(comp, aes(x = G, y = mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.8, position = position_dodge(0.7)) +
  scale_y_log10() +
  labs(title = "Drift: Scenario 1 (No Heterogeneity) vs Scenario 4 (Combined)",
       subtitle = "log scale; min_n >= 3",
       y = "mean standardized drift (log scale)", x = "number of groups") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom")
dev.off()
message("Done: s1_vs_s4_drift.png")

# ── 5. S1 vs S4 SSR comparison ──
png("results/simulation/s1_vs_s4_ssr.png", w = 1100, h = 700, res = 130)
ggplot(comp, aes(x = G, y = mean_ssr, fill = scenario)) +
  geom_boxplot(outlier.size = 0.8, position = position_dodge(0.7)) +
  ylim(0.4, 1.05) +
  labs(title = "SSR: Scenario 1 vs Scenario 4",
       subtitle = "min_n >= 3; S4 shows real sign reversals",
       y = "mean SSR", x = "number of groups") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom")
dev.off()
message("Done: s1_vs_s4_ssr.png")

message("All S4 poster plots saved to results/simulation/")
