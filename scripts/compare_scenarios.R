scenario_files <- list(
  S1 = "results/mc200/grid_results_s1_mc200.csv",
  S2 = "results/mc200/grid_results_s2_mc200.csv",
  S3 = "results/mc200/grid_results_s3_mc200.csv",
  S4 = "results/mc200/grid_results_s4_mc200.csv"
)

scenario_labels <- c(
  S1 = "Scenario 1: no heterogeneity",
  S2 = "Scenario 2: covariate shift only",
  S3 = "Scenario 3: coefficient heterogeneity only",
  S4 = "Scenario 4: combined heterogeneity"
)

output_file <- "results/mc200/scenario_comparison_observations.md"

load_scenario <- function(path, scenario_id) {
  d <- read.csv(path, stringsAsFactors = FALSE)

  if (!"scenario" %in% names(d)) {
    d$scenario <- scenario_id
  }

  if (!"mean_context_drift" %in% names(d) && "mean_ctx" %in% names(d)) {
    d$mean_context_drift <- d$mean_ctx
  }

  d$scenario_id <- scenario_id
  d$scenario_label <- scenario_labels[[scenario_id]]
  d$degenerate <- d$min_group_size < 3
  d$shrink_pct <- 100 * (1 - d$mean_context_drift / pmax(d$mean_drift, 1e-12))
  d
}

round_df <- function(df, digits = 3) {
  out <- df
  for (name in names(out)) {
    if (is.numeric(out[[name]])) {
      out[[name]] <- round(out[[name]], digits)
    }
  }
  out
}

format_table <- function(df, digits = 3) {
  capture.output(print(round_df(df, digits = digits), row.names = FALSE))
}

summarize_overall <- function(d) {
  data.frame(
    scenario = unique(d$scenario_id),
    settings = nrow(d),
    degenerate_settings = sum(d$degenerate),
    reps_min = min(d$n_reps_used),
    reps_max = max(d$n_reps_used),
    median_ssr = median(d$mean_ssr),
    mean_ssr = mean(d$mean_ssr),
    share_ssr_below_1 = mean(d$mean_ssr < 1),
    median_drift = median(d$mean_drift),
    mean_drift = mean(d$mean_drift),
    median_context = median(d$mean_context_drift),
    median_tpg = median(d$mean_tpg),
    median_css = median(d$mean_css),
    median_shrink_pct = median(d$shrink_pct)
  )
}

summarize_by <- function(d, group_var) {
  split_data <- split(d, d[[group_var]])
  rows <- lapply(names(split_data), function(key) {
    sub <- split_data[[key]]
    data.frame(
      group = key,
      median_ssr = median(sub$mean_ssr),
      median_drift = median(sub$mean_drift),
      median_context = median(sub$mean_context_drift),
      median_tpg = median(sub$mean_tpg),
      median_css = median(sub$mean_css),
      median_shrink_pct = median(sub$shrink_pct)
    )
  })
  do.call(rbind, rows)
}

scenario_data <- Map(load_scenario, scenario_files, names(scenario_files))
all_data <- do.call(rbind, scenario_data)
analysis_data <- all_data[all_data$min_group_size >= 3, ]

analysis_data$setting_key <- paste(analysis_data$G, analysis_data$total_n, analysis_data$pattern, sep = "|")

common_keys <- Reduce(
  intersect,
  lapply(split(analysis_data$setting_key, analysis_data$scenario_id), unique)
)

common_data <- analysis_data[analysis_data$setting_key %in% common_keys, ]

overall <- do.call(rbind, lapply(split(analysis_data, analysis_data$scenario_id), summarize_overall))
overall <- overall[match(names(scenario_files), overall$scenario), ]

common_overall <- do.call(rbind, lapply(split(common_data, common_data$scenario_id), summarize_overall))
common_overall <- common_overall[match(names(scenario_files), common_overall$scenario), ]

pairwise <- within(common_overall, {
  drift_vs_s1 = median_drift / median_drift[scenario == "S1"]
  context_vs_s1 = median_context / median_context[scenario == "S1"]
  tpg_vs_s1 = median_tpg / median_tpg[scenario == "S1"]
  css_vs_s1 = median_css / median_css[scenario == "S1"]
})

by_g <- do.call(rbind, lapply(split(common_data, common_data$scenario_id), function(d) {
  out <- summarize_by(d, "G")
  out$scenario <- unique(d$scenario_id)
  out
}))
by_g <- by_g[, c("scenario", "group", "median_ssr", "median_drift", "median_context", "median_tpg", "median_css", "median_shrink_pct")]
names(by_g)[2] <- "G"
by_g$G <- as.integer(by_g$G)
by_g <- by_g[order(match(by_g$scenario, names(scenario_files)), by_g$G), ]

by_pattern <- do.call(rbind, lapply(split(common_data, common_data$scenario_id), function(d) {
  out <- summarize_by(d, "pattern")
  out$scenario <- unique(d$scenario_id)
  out
}))
by_pattern <- by_pattern[, c("scenario", "group", "median_ssr", "median_drift", "median_context", "median_tpg", "median_css", "median_shrink_pct")]
names(by_pattern)[2] <- "pattern"
pattern_order <- c("balanced", "mild", "strong", "random")
by_pattern <- by_pattern[order(match(by_pattern$scenario, names(scenario_files)), match(by_pattern$pattern, pattern_order)), ]

extremes <- analysis_data[order(-analysis_data$objective, -analysis_data$mean_drift), c(
  "scenario_id", "G", "total_n", "pattern", "min_group_size", "mean_ssr",
  "mean_drift", "mean_context_drift", "mean_tpg", "mean_css", "objective"
)]
worst_objective <- head(extremes, 12)

worst_ssr <- analysis_data[order(analysis_data$mean_ssr, -analysis_data$mean_drift), c(
  "scenario_id", "G", "total_n", "pattern", "min_group_size", "mean_ssr",
  "mean_drift", "mean_context_drift", "mean_tpg", "mean_css", "objective"
)]
worst_ssr <- head(worst_ssr, 12)

best_pattern_drift <- do.call(rbind, lapply(split(by_pattern, by_pattern$scenario), function(d) {
  d[which.max(d$median_drift), c("scenario", "pattern", "median_drift", "median_ssr", "median_tpg", "median_css")]
}))

best_pattern_ssr_drop <- do.call(rbind, lapply(split(by_pattern, by_pattern$scenario), function(d) {
  d[which.min(d$median_ssr), c("scenario", "pattern", "median_ssr", "median_drift", "median_tpg", "median_css")]
}))

g_effect <- do.call(rbind, lapply(split(by_g, by_g$scenario), function(d) {
  d <- d[order(d$G), ]
  data.frame(
    scenario = unique(d$scenario),
    drift_G2 = d$median_drift[d$G == min(d$G)],
    drift_G40 = d$median_drift[d$G == max(d$G)],
    drift_ratio_G40_vs_G2 = d$median_drift[d$G == max(d$G)] / d$median_drift[d$G == min(d$G)],
    ssr_G2 = d$median_ssr[d$G == min(d$G)],
    ssr_G40 = d$median_ssr[d$G == max(d$G)],
    tpg_G2 = d$median_tpg[d$G == min(d$G)],
    tpg_G40 = d$median_tpg[d$G == max(d$G)]
  )
}))

max_median <- function(column_name) {
  idx <- which.max(overall[[column_name]])
  overall$scenario[idx]
}

min_median <- function(column_name) {
  idx <- which.min(overall[[column_name]])
  overall$scenario[idx]
}

scenario_line <- function(scenario_id, summary_df) {
  row <- summary_df[summary_df$scenario == scenario_id, ]
  paste0(
    "- ", scenario_labels[[scenario_id]], ": median SSR = ", sprintf("%.3f", row$median_ssr),
    ", median drift = ", sprintf("%.3f", row$median_drift),
    ", median context drift = ", sprintf("%.3f", row$median_context),
    ", median TPG = ", sprintf("%.4f", row$median_tpg),
    ", median CSS = ", sprintf("%.3f", row$median_css),
    ", median shrinkage = ", sprintf("%.1f%%", row$median_shrink_pct),
    ", SSR < 1 in ", sprintf("%.1f%%", 100 * row$share_ssr_below_1), " of retained settings."
  )
}

pairwise_line <- function(scenario_id) {
  row <- pairwise[pairwise$scenario == scenario_id, ]
  paste0(
    "- ", scenario_labels[[scenario_id]], " relative to Scenario 1: drift ", sprintf("%.2fx", row$drift_vs_s1),
    ", context drift ", sprintf("%.2fx", row$context_vs_s1),
    ", TPG ", sprintf("%.2fx", row$tpg_vs_s1),
    ", CSS ", sprintf("%.2fx", row$css_vs_s1), "."
  )
}

lines <- c(
  "# Scenario Comparison Observations",
  "",
  paste0("Generated on ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "."),
  "",
  "This note compares the four simulation scenarios using the saved grid outputs in `results/`. The main comparison uses only settings with `min_group_size >= 3`, because very sparse subgroup corners create unstable outliers that distort mean-based summaries.",
  "",
  "## Coverage and comparability",
  "",
  "```text",
  format_table(overall[, c("scenario", "settings", "degenerate_settings", "reps_min", "reps_max")], digits = 0),
  "```",
  "",
  "Observations:",
  paste0("- All four scenarios retain ", nrow(analysis_data[analysis_data$scenario_id == "S1", ]), "/", nrow(all_data[all_data$scenario_id == "S1", ]),
         " (S1), ", nrow(analysis_data[analysis_data$scenario_id == "S2", ]), "/", nrow(all_data[all_data$scenario_id == "S2", ]),
         " (S2), ", nrow(analysis_data[analysis_data$scenario_id == "S3", ]), "/", nrow(all_data[all_data$scenario_id == "S3", ]),
         " (S3), and ", nrow(analysis_data[analysis_data$scenario_id == "S4", ]), "/", nrow(all_data[all_data$scenario_id == "S4", ]),
         " (S4) settings after the `min_group_size >= 3` filter."),
  paste0("- All scenarios use the same 140-setting design: `G` values ", paste(sort(unique(all_data$G)), collapse = ", "),
         "; `total_n` values ", paste(sort(unique(all_data$total_n)), collapse = ", "), "; and all four imbalance patterns."),
  paste0("- Every completed setting uses 200 replications, so Monte Carlo means and interval widths are directly comparable across scenarios."),
  paste0("- Degenerate sparse-corner settings are concentrated where `G` is large and `total_n` is small; keeping them out is important for fair cross-scenario comparisons."),
  "",
  "## Unified-grid comparison",
    "",
    "```text",
  format_table(overall[, c("scenario", "median_ssr", "mean_ssr", "share_ssr_below_1", "median_drift", "mean_drift", "median_context", "median_tpg", "median_css", "median_shrink_pct")]),
    "```",
    "",
  "Unified-grid observations:",
  "- This is the headline comparison because every scenario is evaluated on the same retained settings with the same replication budget.",
  "- Scenario 4 has the lowest mean SSR and the highest median raw drift and pooled-versus-subgroup prediction gap. Scenario 3 has the largest share of retained settings with SSR below one.",
  "- Scenario 3 has the highest median context-normalized drift. This is consistent with coefficient heterogeneity remaining after little adjustment for covariate separation, whereas normalization removes a larger mechanical component in Scenario 4.",
    "- Scenario 2 still has the highest CSS and the largest shrinkage from raw to context-normalized drift, which is the expected signature of primarily mechanical instability.",
    "- Scenario 3 remains the cleanest coefficient-heterogeneity benchmark: drift and TPG are much larger than Scenario 1, while CSS stays near the no-heterogeneity baseline.",
  scenario_line("S1", overall),
  scenario_line("S2", overall),
  scenario_line("S3", overall),
  scenario_line("S4", overall),
    "",
    "## Relative to Scenario 1",
  "",
  "```text",
  format_table(pairwise[, c("scenario", "drift_vs_s1", "context_vs_s1", "tpg_vs_s1", "css_vs_s1")]),
  "```",
  "",
  "Comparative observations:",
  pairwise_line("S2"),
  pairwise_line("S3"),
  pairwise_line("S4"),
  paste0("- Scenario 2 isolates mechanical instability: CSS jumps the most, but SSR remains at or extremely near 1 and TPG stays relatively small compared with Scenarios 3 and 4."),
  paste0("- Scenario 3 isolates genuine relationship instability: it raises drift, context drift, and TPG sharply with much lower CSS than Scenario 2."),
  paste0("- Scenario 4 combines both mechanisms: it has the largest raw drift and pooled-versus-subgroup prediction gap, while its context-normalized drift remains well above the Scenario 1 baseline."),
  "",
    "## By number of groups",
  "",
  "```text",
  format_table(by_g),
  "```",
  "",
  "Observations by `G`:",
          paste0("- Median drift grows with `G` in every scenario. The `G=40` to `G=2` drift ratio is ",
         paste(sprintf("%s %.2fx", g_effect$scenario, g_effect$drift_ratio_G40_vs_G2), collapse = "; "), "."),
        paste0("- The proportional rise is largest in Scenarios 1 and 2 because their low-group baselines are small. In absolute terms, Scenarios 3 and 4 still have the largest drift at `G=40`, consistent with coefficient heterogeneity adding to finite-sample instability."),
  paste0("- Scenario 1 shows that even without true heterogeneity, splitting the sample into many groups creates nontrivial finite-sample drift. That is the baseline mechanical penalty of subgrouping."),
  paste0("- Scenario 2 amplifies that baseline mostly through CSS and moderate drift inflation, not through sign reversals."),
  paste0("- Scenarios 3 and 4 deteriorate more sharply as `G` rises, which is consistent with more subgroup-specific coefficients being estimated from smaller effective samples."),
    paste0("- The TPG increase from `G=2` to `G=40` is mild in Scenario 1, noticeable in Scenario 2, and materially larger in Scenarios 3 and 4."),
  "",
    "## By imbalance pattern",
  "",
  "```text",
  format_table(by_pattern),
  "```",
  "",
  "Observations by pattern:",
  paste0("- The worst pattern by median drift is ", paste(sprintf("%s -> %s", best_pattern_drift$scenario, best_pattern_drift$pattern), collapse = "; "), "."),
  paste0("- The lowest-SSR pattern within each scenario is ", paste(sprintf("%s -> %s", best_pattern_ssr_drop$scenario, best_pattern_ssr_drop$pattern), collapse = "; "), "."),
  paste0("- Balanced and mild settings are usually the most stable. Strong and random imbalance tend to increase drift because they leave some groups with less information and more leverage-sensitive estimates."),
  paste0("- Random imbalance is especially informative because it often produces worse instability than mild imbalance without imposing a deterministic size ordering. That makes it a useful bridge between clean theoretical patterns and messier real subgroup structures."),
  paste0("- In Scenario 2, pattern effects are seen mostly through CSS and shrinkage. In Scenarios 3 and 4, pattern effects also spill into SSR and TPG because distribution imbalance interacts with coefficient differences."),
  "",
  "## Most unstable retained settings",
  "",
  "Top settings by objective/drift:",
  "```text",
  format_table(worst_objective),
  "```",
  "",
  "Top settings by lowest SSR:",
  "```text",
  format_table(worst_ssr),
  "```",
  "",
  "Extreme-setting observations:",
  paste0("- The worst retained settings concentrate in Scenario 4 and, to a lesser extent, Scenario 3. They typically combine many groups, small minimum subgroup sizes, and either strong or random imbalance."),
  paste0("- Low-SSR settings occur in every scenario when group sizes are small. The scenario labels alone do not determine sign instability at this design boundary."),
  paste0("- When Scenario 4 becomes extreme, raw drift and TPG rise together. That is the practical failure mode of pooled regression in this study: not just coefficient movement, but degraded cross-group prediction transfer."),
  "",
  "## Bottom line",
  "",
  "- Scenario 1 is the finite-sample baseline: instability exists even with no true heterogeneity, especially when many small groups are estimated separately.",
  "- Scenario 2 is mostly mechanical: it produces very large covariate shift and noticeable raw-drift inflation, but little sign instability.",
  "- Scenario 3 is mostly genuine: it substantially increases coefficient drift and prediction transfer gaps, with lower CSS than Scenario 2.",
  "- Scenario 4 is the joint stress test: it has the largest raw drift and pooled-versus-subgroup prediction gap. Scenario 3 retains the largest context-normalized drift because it has less covariate-shift inflation to remove.",
  "- For paper-level comparisons, medians on the nondegenerate unified grid are the most defensible summary. Means remain useful for showing how badly the sparse-corner cases can explode, but they should not be the headline comparison across scenarios."
)

writeLines(lines, con = output_file)
cat("Wrote scenario comparison report to", output_file, "\n")