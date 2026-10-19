# Better S1 vs S4 plots for poster v2
library(ggplot2)

d1 <- read.csv("results/grid_results.csv")
d4 <- read.csv("results/grid_results_scenario4.csv")

# Filter degenerate and add scenario label
d1 <- d1[d1$min_group_size >= 3, ]
d4 <- d4[d4$min_group_size >= 3, ]
d1$scenario <- "S1 (no heterogeneity)"
d4$scenario <- "S4 (combined)"

# Ensure G is sorted
d1$G <- factor(d1$G, levels = sort(unique(d1$G)))
d4$G <- factor(d4$G, levels = sort(unique(d4$G)))

sel_cols <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_ctx","scenario")
comp <- rbind(d1[, sel_cols], d4[, sel_cols])
comp$scenario <- factor(comp$scenario, levels = c("S1 (no heterogeneity)","S4 (combined)"))

dir.create("results/simulation", showWarnings = FALSE)

# ── 1. SSR: S1 vs S4 (sorted G) ──
png("results/simulation/poster_ssr_s1vss4.png", w = 1200, h = 750, res = 140)
ggplot(comp, aes(x = G, y = mean_ssr, fill = scenario)) +
  geom_boxplot(outlier.size = 0.6, position = position_dodge(0.7)) +
  geom_hline(yintercept = 1, linetype = "dotted", color = "gray40") +
  scale_fill_manual(values = c("S1 (no heterogeneity)" = "#1B2A4A", "S4 (combined)" = "#E8752A")) +
  ylim(0.4, 1.05) +
  labs(title = "Sign Stability Rate: S1 vs S4",
       subtitle = expression("S1: identical"~beta~"across groups"~~~~"S4: shifted"~beta~"+ shifted X distributions"),
       y = "mean SSR", x = "number of groups (G)") +
  theme_minimal(base_size = 14) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_ssr_s1vss4.png")

# ── 2. Drift: S1 vs S4 (sorted G, log scale) ──
png("results/simulation/poster_drift_s1vss4.png", w = 1200, h = 750, res = 140)
ggplot(comp, aes(x = G, y = mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.6, position = position_dodge(0.7)) +
  scale_fill_manual(values = c("S1 (no heterogeneity)" = "#1B2A4A", "S4 (combined)" = "#E8752A")) +
  scale_y_log10() +
  labs(title = "Standardized Drift: S1 vs S4",
       subtitle = "log scale; S4 drift ~7x larger — context normalization strips the mechanical part",
       y = "mean standardized drift (log scale)", x = "number of groups (G)") +
  theme_minimal(base_size = 14) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_drift_s1vss4.png")

# ── 3. Context shrinkage %: S1 vs S4 ──
comp$shrinkage <- (comp$mean_drift - comp$mean_ctx) / pmax(comp$mean_drift, 1e-8) * 100
png("results/simulation/poster_shrinkage_s1vss4.png", w = 1200, h = 750, res = 140)
ggplot(comp, aes(x = G, y = shrinkage, fill = scenario)) +
  geom_boxplot(outlier.size = 0.6, position = position_dodge(0.7)) +
  scale_fill_manual(values = c("S1 (no heterogeneity)" = "#1B2A4A", "S4 (combined)" = "#E8752A")) +
  labs(title = "Context-Normalization Shrinkage: S1 vs S4",
       subtitle = "Both scenarios shrink ~30-35%; residual drift in S4 reflects genuine heterogeneity",
       y = "drift shrinkage (%)", x = "number of groups (G)") +
  theme_minimal(base_size = 14) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_shrinkage_s1vss4.png")

message("All poster v2 plots saved.")
