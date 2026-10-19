# Focused plots for poster: only G where changes happen, smaller
library(ggplot2)

d1 <- read.csv("results/grid_results.csv")
d4 <- read.csv("results/grid_results_scenario4.csv")

d1 <- d1[d1$min_group_size >= 3, ]
d4 <- d4[d4$min_group_size >= 3, ]
d1$scenario <- "S1 (no het.)"
d4$scenario <- "S4 (combined)"

sel_cols <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_ctx","scenario")
comp <- rbind(d1[, sel_cols], d4[, sel_cols])
comp$scenario <- factor(comp$scenario, levels = c("S1 (no het.)","S4 (combined)"))

# ── 1. SSR: only S4 matters (S1 is flat at 1.0) ──
png("results/simulation/poster_ssr_focus.png", w = 1000, h = 550, res = 140)
s4_only <- comp[comp$scenario == "S4 (combined)", ]
s4_only$G <- factor(s4_only$G, levels = sort(unique(s4_only$G)))
ggplot(s4_only, aes(x = G, y = mean_ssr, fill = pattern)) +
  geom_boxplot(outlier.size = 0.5, position = position_dodge(0.7)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  scale_fill_manual(values = c("balanced" = "#1B2A4A", "mild" = "#5B8FB9",
                                "strong" = "#E8752A", "random" = "#C0392B")) +
  ylim(0.5, 1.05) +
  labs(title = "SSR: S4 (combined heterogeneity)", y = "SSR", x = "Groups (G)") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_ssr_focus.png")

# ── 2. Drift S1 vs S4 (only G >= 10, small panels) ──
comp_hi <- comp[comp$G %in% c(10, 20, 40), ]
comp_hi$G <- factor(comp_hi$G, levels = c(10, 20, 40))

png("results/simulation/poster_drift_focus.png", w = 1000, h = 550, res = 140)
ggplot(comp_hi, aes(x = G, y = mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.5, position = position_dodge(0.7)) +
  scale_fill_manual(values = c("S1 (no het.)" = "#1B2A4A", "S4 (combined)" = "#E8752A")) +
  scale_y_log10() +
  labs(title = "Drift: S1 vs S4 (G >= 10)", y = "Std. drift (log)", x = "Groups (G)") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_drift_focus.png")

# ── 3. Shrinkage S1 vs S4 (compact) ──
comp$shrinkage <- (comp$mean_drift - comp$mean_ctx) / pmax(comp$mean_drift, 1e-8) * 100

png("results/simulation/poster_shrinkage_focus.png", w = 1000, h = 550, res = 140)
ggplot(comp, aes(x = factor(G, levels = sort(unique(G))), y = shrinkage, fill = scenario)) +
  geom_boxplot(outlier.size = 0.5, position = position_dodge(0.7)) +
  scale_fill_manual(values = c("S1 (no het.)" = "#1B2A4A", "S4 (combined)" = "#E8752A")) +
  ylim(20, 45) +
  labs(title = "Drift shrinkage by context normalization", y = "Shrinkage (%)", x = "Groups (G)") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_shrinkage_focus.png")

message("All focused plots saved.")
