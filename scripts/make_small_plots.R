# Ultra-compact plots for poster: side-by-side S1/S4
library(ggplot2)

d1 <- read.csv("results/grid_results.csv")
d4 <- read.csv("results/grid_results_scenario4.csv")
d1 <- d1[d1$min_group_size >= 3, ]
d4 <- d4[d4$min_group_size >= 3, ]
d1$G <- factor(d1$G, levels = sort(unique(d1$G)))
d4$G <- factor(d4$G, levels = sort(unique(d4$G)))

# ── S1 drift (compact) ──
png("results/simulation/poster_s1_drift_small.png", w = 800, h = 420, res = 130)
ggplot(d1, aes(x = G, y = mean_drift, fill = pattern)) +
  geom_boxplot(outlier.size = 0.4, position = position_dodge(0.7), lwd = 0.3) +
  scale_y_log10() +
  scale_fill_manual(values = c("balanced"="#1B2A4A","mild"="#5B8FB9","strong"="#E8752A","random"="#C0392B")) +
  labs(title = "S1: no heterogeneity", subtitle = "SSR = 1.0 (no sign reversals)", y = "Drift (log)", x = "G") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.3, "cm"))
dev.off()
message("Done: poster_s1_drift_small.png")

# ── S4 SSR (compact) ──
png("results/simulation/poster_s4_ssr_small.png", w = 800, h = 420, res = 130)
ggplot(d4, aes(x = G, y = mean_ssr, fill = pattern)) +
  geom_boxplot(outlier.size = 0.4, position = position_dodge(0.7), lwd = 0.3) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50", lwd = 0.3) +
  ylim(0.5, 1.05) +
  scale_fill_manual(values = c("balanced"="#1B2A4A","mild"="#5B8FB9","strong"="#E8752A","random"="#C0392B")) +
  labs(title = "S4: SSR", subtitle = "44% of settings < 1", y = "SSR", x = "G") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.3, "cm"))
dev.off()
message("Done: poster_s4_ssr_small.png")

# ── S4 drift (compact) ──
png("results/simulation/poster_s4_drift_small.png", w = 800, h = 420, res = 130)
ggplot(d4, aes(x = G, y = mean_drift, fill = pattern)) +
  geom_boxplot(outlier.size = 0.4, position = position_dodge(0.7), lwd = 0.3) +
  scale_y_log10() +
  scale_fill_manual(values = c("balanced"="#1B2A4A","mild"="#5B8FB9","strong"="#E8752A","random"="#C0392B")) +
  labs(title = "S4: drift", subtitle = "~7x S1; genuine + mechanical", y = "Drift (log)", x = "G") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.3, "cm"))
dev.off()
message("Done: poster_s4_drift_small.png")

# ── S1 vs S4: drift at G=20,40 only ──
sel <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_ctx")
comp <- rbind(cbind(d1[, sel], scenario = "S1"), cbind(d4[, sel], scenario = "S4"))
comp$scenario <- factor(comp$scenario, levels = c("S1","S4"))
comp_core <- comp[comp$G %in% c("20","40"), ]

png("results/simulation/poster_s1vss4_drift_small.png", w = 800, h = 420, res = 130)
ggplot(comp_core, aes(x = G, y = mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.4, position = position_dodge(0.7), lwd = 0.3) +
  scale_fill_manual(values = c("S1"="#1B2A4A","S4"="#E8752A")) +
  scale_y_log10() +
  labs(title = "S1 vs S4: drift (G = 20, 40)", y = "Drift (log)", x = "G") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.3, "cm"))
dev.off()
message("Done: poster_s1vss4_drift_small.png")

message("All small plots done.")
