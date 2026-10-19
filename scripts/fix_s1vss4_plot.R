library(ggplot2)
d1 <- read.csv("results/grid_results.csv"); d1 <- d1[d1$min_group_size >= 3, ]
d4 <- read.csv("results/grid_results_scenario4.csv"); d4 <- d4[d4$min_group_size >= 3, ]
d1$G <- factor(d1$G, levels = sort(unique(d1$G)))
d4$G <- factor(d4$G, levels = sort(unique(d4$G)))
thm <- theme_minimal(base_size = 9) + theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.25, "cm"))

sel <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_ctx")
comp <- rbind(cbind(d1[,sel], scenario = "S1"), cbind(d4[,sel], scenario = "S4"))
comp$scenario <- factor(comp$scenario, levels = c("S1","S4"))
comp_core <- comp[comp$G %in% c("20","40"), ]

png("results/simulation/poster_s1vss4_drift.png", w = 700, h = 380, res = 120)
ggplot(comp_core, aes(scenario, mean_drift, fill = scenario)) +
  geom_boxplot(outlier.size = 0.3, lwd = 0.25) +
  scale_fill_manual(values = c("S1" = "#5B8FB9", "S4" = "#E8752A")) +
  scale_y_log10() +
  facet_grid(. ~ G) +
  labs(title = "S1 vs S4: drift", y = "Drift (log)", x = "") +
  thm + theme(strip.background = element_rect(fill = "gray95"),
              strip.text = element_text(face = "bold", size = 11))
dev.off()
message("S1vS4 faceted plot done.")
