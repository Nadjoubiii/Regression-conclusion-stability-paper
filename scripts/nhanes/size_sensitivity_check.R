# Size sensitivity check for age-decade subgroup stability metrics.

compute_ssr <- function(coef_mat) {
  pairs <- combn(seq_len(nrow(coef_mat)), 2, simplify = FALSE)
  setNames(vapply(seq_len(ncol(coef_mat)), function(j) {
    b <- coef_mat[, j]
    mean(vapply(pairs, function(p) as.integer(sign(b[p[1]]) == sign(b[p[2]])), integer(1)))
  }, numeric(1)), colnames(coef_mat))
}

compute_drift <- function(coef_mat, pooled_model) {
  pooled_tab <- summary(pooled_model)$coefficients
  pooled_coef <- pooled_tab[, "Estimate"]
  pooled_se <- pooled_tab[, "Std. Error"]
  names(pooled_coef) <- rownames(pooled_tab)
  names(pooled_se) <- rownames(pooled_tab)

  pooled_coef <- pooled_coef[names(pooled_coef) != "(Intercept)"]
  pooled_se <- pooled_se[names(pooled_se) != "(Intercept)"]

  terms <- intersect(colnames(coef_mat), names(pooled_coef))
  setNames(vapply(terms, function(term) {
    max_dev <- max(abs(coef_mat[, term] - pooled_coef[term]), na.rm = TRUE)
    max_dev / pmax(pooled_se[term], 1e-8)
  }, numeric(1)), terms)
}

main <- function(out_dir = file.path("results", "nhanes_age_decade"), min_group_n = 80) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  d <- readRDS(file.path("data", "raw", "nhanes_raw.rds"))
  vars <- c("AgeDecade", "BMI", "Gender", "Poverty", "DirectChol", "Pulse", "BPSysAve")
  dat <- d[, vars, drop = FALSE]
  dat <- dat[complete.cases(dat), , drop = FALSE]
  dat <- dat[!is.na(dat$AgeDecade) & dat$AgeDecade != "", , drop = FALSE]
  dat$AgeDecade <- droplevels(factor(dat$AgeDecade))
  dat$Gender <- droplevels(factor(dat$Gender))

  counts <- as.data.frame(table(dat$AgeDecade), stringsAsFactors = FALSE)
  names(counts) <- c("AgeDecade", "n")
  counts$AgeDecade <- trimws(as.character(counts$AgeDecade))

  valid_groups <- counts$AgeDecade[counts$n >= min_group_n]
  dat <- dat[trimws(as.character(dat$AgeDecade)) %in% valid_groups, , drop = FALSE]
  dat$AgeDecade <- droplevels(factor(trimws(as.character(dat$AgeDecade))))

  f <- BMI ~ Gender + Poverty + DirectChol + Pulse + BPSysAve

  mods_all <- lapply(split(dat, dat$AgeDecade), function(df) lm(f, data = df))
  coef_all <- do.call(rbind, lapply(mods_all, coef))
  coef_all <- coef_all[, colnames(coef_all) != "(Intercept)", drop = FALSE]
  pooled_all <- lm(f, data = dat)
  ssr_all <- compute_ssr(coef_all)
  drift_all <- compute_drift(coef_all, pooled_all)

  dat_no09 <- dat[as.character(dat$AgeDecade) != "0-9", , drop = FALSE]
  dat_no09$AgeDecade <- droplevels(dat_no09$AgeDecade)
  mods_no09 <- lapply(split(dat_no09, dat_no09$AgeDecade), function(df) lm(f, data = df))
  coef_no09 <- do.call(rbind, lapply(mods_no09, coef))
  coef_no09 <- coef_no09[, colnames(coef_no09) != "(Intercept)", drop = FALSE]
  pooled_no09 <- lm(f, data = dat_no09)
  ssr_no09 <- compute_ssr(coef_no09)
  drift_no09 <- compute_drift(coef_no09, pooled_no09)

  equal_n_groups <- c("10-19", "20-29", "30-39", "40-49", "50-59")
  equal_n_groups <- equal_n_groups[equal_n_groups %in% rownames(coef_all)]
  coef_equal_n <- coef_all[equal_n_groups, , drop = FALSE]
  ssr_equal_n <- compute_ssr(coef_equal_n)

  term_tab <- data.frame(
    term = colnames(coef_all),
    ssr_all = as.numeric(ssr_all[colnames(coef_all)]),
    ssr_no_0_9 = as.numeric(ssr_no09[colnames(coef_all)]),
    ssr_equal_n_groups = as.numeric(ssr_equal_n[colnames(coef_all)]),
    drift_all = as.numeric(drift_all[colnames(coef_all)]),
    drift_no_0_9 = as.numeric(drift_no09[colnames(coef_all)]),
    stringsAsFactors = FALSE
  )

  coef_long <- data.frame(
    AgeDecade = rep(rownames(coef_all), each = ncol(coef_all)),
    term = rep(colnames(coef_all), times = nrow(coef_all)),
    estimate = as.numeric(t(coef_all)),
    stringsAsFactors = FALSE
  )

  write.csv(counts, file.path(out_dir, "group_counts_complete_cases.csv"), row.names = FALSE)
  write.csv(term_tab, file.path(out_dir, "size_sensitivity_metrics.csv"), row.names = FALSE)
  write.csv(coef_long, file.path(out_dir, "coefficients_by_group_for_size_check.csv"), row.names = FALSE)

  cat("Saved:\n")
  cat("-", file.path(out_dir, "group_counts_complete_cases.csv"), "\n")
  cat("-", file.path(out_dir, "size_sensitivity_metrics.csv"), "\n")
  cat("-", file.path(out_dir, "coefficients_by_group_for_size_check.csv"), "\n")

  invisible(list(counts = counts, metrics = term_tab, coefficients = coef_long))
}

if (identical(environment(), globalenv())) {
  main()
}