# Overwrite poster plots with smaller versions
library(ggplot2)

d1 <- read.csv("results/grid_results.csv"); d1 <- d1[d1$min_group_size >= 3, ]
d4 <- read.csv("results/grid_results_scenario4.csv"); d4 <- d4[d4$min_group_size >= 3, ]
d1$G <- factor(d1$G, levels = sort(unique(d1$G)))
d4$G <- factor(d4$G, levels = sort(unique(d4$G)))
thm <- theme_minimal(base_size = 9) + theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.25, "cm"))

pal <- c("balanced"="#6BAED6","mild"="#7EC8A0","strong"="#D4843A","random"="#B33A3A")

# S1 drift
png("results/simulation/poster_s1_drift.png", w = 700, h = 380, res = 120)
ggplot(d1, aes(G, mean_drift, fill = pattern)) + geom_boxplot(outlier.size = 0.3, position = position_dodge(0.7), lwd = 0.25) + scale_y_log10() + scale_fill_manual(values = pal) + labs(title = "S1: no heterogeneity", subtitle = "SSR = 1.0; drift purely mechanical", y = "Drift (log)", x = "G") + thm
dev.off()

# S4 SSR
png("results/simulation/poster_s4_ssr.png", w = 700, h = 380, res = 120)
ggplot(d4, aes(G, mean_ssr, fill = pattern)) + geom_boxplot(outlier.size = 0.3, position = position_dodge(0.7), lwd = 0.25) + geom_hline(yintercept = 1, lty = "dashed", col = "gray50", lwd = 0.25) + ylim(0.5, 1.05) + scale_fill_manual(values = pal) + labs(title = "S4: sign stability", subtitle = "44% of settings SSR < 1", y = "SSR", x = "G") + thm
dev.off()

# S4 drift
png("results/simulation/poster_s4_drift.png", w = 700, h = 380, res = 120)
ggplot(d4, aes(G, mean_drift, fill = pattern)) + geom_boxplot(outlier.size = 0.3, position = position_dodge(0.7), lwd = 0.25) + scale_y_log10() + scale_fill_manual(values = pal) + labs(title = "S4: drift (combined het.)", subtitle = "~7x S1; genuine + mechanical", y = "Drift (log)", x = "G") + thm
dev.off()

# S1 vs S4 drift at G=20,40
sel <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_ctx")
comp <- rbind(cbind(d1[, sel], scenario = "S1"), cbind(d4[, sel], scenario = "S4"))
comp$scenario <- factor(comp$scenario, levels = c("S1","S4"))
comp_core <- comp[comp$G %in% c("20","40"), ]
comp_core <- comp_core[comp_core$mean_drift > 0 & !is.na(comp_core$mean_drift), ]
png("results/simulation/poster_s1vss4_drift.png", w = 700, h = 380, res = 120)
ggplot(comp_core, aes(G, mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.3, position = position_dodge(0.7), lwd = 0.25) +
  scale_fill_manual(values = c("S1"="#6BAED6","S4"="#D4843A")) +
  scale_y_log10() +
  facet_grid(. ~ G, scales = "free_x", space = "free_x") +
  labs(title = "S1 vs S4: drift", y = "Drift (log)", x = "") +
  thm + theme(strip.background = element_rect(fill = "gray95"), strip.text = element_text(face = "bold", size = 11))
dev.off()

message("All poster plots resized to 700x380.")
