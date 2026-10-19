library(ggplot2)
d1 <- read.csv("results/grid_results.csv"); d1 <- d1[d1$min_group_size >= 3, ]
d4 <- read.csv("results/grid_results_scenario4.csv"); d4 <- d4[d4$min_group_size >= 3, ]

sel <- c("G","total_n","pattern","mean_drift","mean_ssr","mean_tpg")
comp <- rbind(cbind(d1[,sel], scenario = "S1"), cbind(d4[,sel], scenario = "S4"))
comp$scenario <- factor(comp$scenario, levels = c("S1","S4"))
comp$G <- factor(comp$G, levels = sort(unique(comp$G)))

thm <- theme_minimal(base_size = 9) + theme(legend.position = "bottom", legend.title = element_blank(), legend.key.size = unit(0.25, "cm"))

png("results/simulation/poster_tpg_s1vss4.png", w = 600, h = 350, res = 120)
ggplot(comp, aes(G, mean_tpg, fill = scenario)) +
  geom_boxplot(outlier.size = 0.3, position = position_dodge(0.7), lwd = 0.25) +
  scale_fill_manual(values = c("S1" = "#6BAED6", "S4" = "#D4843A")) +
  labs(title = "S1 vs S4: TPG", subtitle = "prediction gap; S4 models lose more across groups", y = "TPG", x = "G") +
  thm
dev.off()
message("TPG plot done.")
