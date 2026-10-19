# Split plots: S1 alone, S4 alone, S1 vs S4
library(ggplot2)

d1 <- read.csv("results/grid_results.csv")
d4 <- read.csv("results/grid_results_scenario4.csv")
d1 <- d1[d1$min_group_size >= 3, ]
d4 <- d4[d4$min_group_size >= 3, ]
d1$G <- factor(d1$G, levels = sort(unique(d1$G)))
d4$G <- factor(d4$G, levels = sort(unique(d4$G)))

# ── S1: drift only (SSR is always 1.0) ──
png("results/simulation/poster_s1_drift.png", w = 900, h = 500, res = 140)
ggplot(d1, aes(x = G, y = mean_drift, fill = pattern)) +
  geom_boxplot(outlier.size = 0.5, position = position_dodge(0.7)) +
  scale_y_log10() +
  scale_fill_manual(values = c("balanced"="#1B2A4A","mild"="#5B8FB9","strong"="#E8752A","random"="#C0392B")) +
  labs(title = "S1: drift with no heterogeneity", subtitle = expression("identical"~beta~"across groups; drift is purely mechanical"),
       y = "Std. drift (log)", x = "G") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_s1_drift.png")

# ── S4: SSR only ──
png("results/simulation/poster_s4_ssr.png", w = 900, h = 500, res = 140)
ggplot(d4, aes(x = G, y = mean_ssr, fill = pattern)) +
  geom_boxplot(outlier.size = 0.5, position = position_dodge(0.7)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  ylim(0.5, 1.05) +
  scale_fill_manual(values = c("balanced"="#1B2A4A","mild"="#5B8FB9","strong"="#E8752A","random"="#C0392B")) +
  labs(title = "S4: sign stability rate (SSR)", subtitle = "shifted X + shifted beta; 44% of settings show sign reversals",
       y = "SSR", x = "G") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_s4_ssr.png")

# ── S4: drift only ──
png("results/simulation/poster_s4_drift.png", w = 900, h = 500, res = 140)
ggplot(d4, aes(x = G, y = mean_drift, fill = pattern)) +
  geom_boxplot(outlier.size = 0.5, position = position_dodge(0.7)) +
  scale_y_log10() +
  scale_fill_manual(values = c("balanced"="#1B2A4A","mild"="#5B8FB9","strong"="#E8752A","random"="#C0392B")) +
  labs(title = "S4: drift with combined heterogeneity", subtitle = "drift ~7x S1; contains both genuine and mechanical components",
       y = "Std. drift (log)", x = "G") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_s4_drift.png")

# ── S1 vs S4: drift comparison (G >= 10, compact) ──
sel <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_ctx")
comp <- rbind(cbind(d1[, sel], scenario = "S1"), cbind(d4[, sel], scenario = "S4"))
comp$scenario <- factor(comp$scenario, levels = c("S1","S4"))
comp_hi <- comp[comp$G %in% c("10","20","40"), ]

png("results/simulation/poster_s1vss4_drift.png", w = 900, h = 500, res = 140)
ggplot(comp_hi, aes(x = G, y = mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.5, position = position_dodge(0.7)) +
  scale_fill_manual(values = c("S1"="#1B2A4A","S4"="#E8752A")) +
  scale_y_log10() +
  labs(title = "S1 vs S4: drift (G >= 10)", y = "Std. drift (log)", x = "G") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())
dev.off()
message("Done: poster_s1vss4_drift.png")

message("All split plots done.")
