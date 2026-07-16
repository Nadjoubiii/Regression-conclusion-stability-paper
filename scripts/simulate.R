# simulation entry point

# Generate x values.
generate_predictors <- function(n, mu, sigma) {
	p <- length(mu)
	x <- matrix(rnorm(n * p), nrow = n, ncol = p) %*% chol(sigma)
	colnames(x) <- paste0("x", seq_len(p))
	sweep(x, 2, mu, "+")
}

# Simulate one group.
simulate_group <- function(n, group_label, beta, mu, sigma_x, sigma_y) {
	x <- generate_predictors(n, mu, sigma_x)
	y <- beta[1] + as.vector(x %*% beta[-1]) + rnorm(n, sd = sigma_y)
	data.frame(group = factor(group_label), y = y, x, row.names = NULL)
}

# Build group settings.
build_group_settings <- function(G, p, base_beta, beta_shift = NULL, mu_shift = NULL, sigma_y = 1) {
	beta_shift <- beta_shift %||% matrix(0, G, p + 1)
	mu_shift <- mu_shift %||% matrix(0, G, p)
	lapply(seq_len(G), function(g) list(beta = base_beta + beta_shift[g, ], mu = mu_shift[g, ], sigma_y = sigma_y))
}

# Make covariance matrix.
make_covariance <- function(p, rho = 0.2) {
	sigma <- matrix(rho, p, p)
	diag(sigma) <- 1
	sigma
}

# Stack all groups into one data frame.
simulate_scenario <- function(n_per_group, settings, sigma_x) {
	stopifnot(length(n_per_group) == length(settings))
	do.call(rbind, Map(function(n, s, g) simulate_group(n, paste0("g", g), s$beta, s$mu, sigma_x, s$sigma_y), n_per_group, settings, seq_along(settings)))
}

# Scenario 1: same x, same beta.
scenario_no_heterogeneity <- function(n_per_group = c(1000, 1000, 1000), p = 2, base_beta = c(1, .8, -.5), rho = .2, sigma_y = 1) {
	list(name = "no_heterogeneity", data = simulate_scenario(n_per_group, build_group_settings(length(n_per_group), p, base_beta, sigma_y = sigma_y), make_covariance(p, rho)))
}

# Scenario 2: shifted x only.
scenario_covariate_shift <- function(n_per_group = c(1000, 1000, 1000), p = 2, base_beta = c(1, .8, -.5), mu_shift = NULL, rho = .2, sigma_y = 1) {
	G <- length(n_per_group)
	mu_shift <- mu_shift %||% as.matrix(expand.grid(seq(-0.5, 0.5, length.out = G), seq_len(p))[, 1])
	mu_shift <- matrix(mu_shift, nrow = G, ncol = p)
	list(name = "covariate_shift_only", data = simulate_scenario(n_per_group, build_group_settings(length(n_per_group), p, base_beta, mu_shift = mu_shift, sigma_y = sigma_y), make_covariance(p, rho)))
}

# Scenario 3: shifted beta only.
scenario_coefficient_heterogeneity <- function(n_per_group = c(1000, 1000, 1000), p = 2, base_beta = c(1, .8, -.5), beta_shift = NULL, rho = .2, sigma_y = 1) {
	G <- length(n_per_group)
	beta_shift <- beta_shift %||% cbind(
		rep(0, G),
		seq(-0.4, 0.4, length.out = G),
		seq(0.2, -0.2, length.out = G)
	)
	list(name = "coefficient_heterogeneity_only", data = simulate_scenario(n_per_group, build_group_settings(length(n_per_group), p, base_beta, beta_shift = beta_shift, sigma_y = sigma_y), make_covariance(p, rho)))
}

# Scenario 4: shifted x and beta.
scenario_combined_heterogeneity <- function(n_per_group = c(1000, 1000, 1000), p = 2, base_beta = c(1, .8, -.5), beta_shift = NULL, mu_shift = NULL, rho = .2, sigma_y = 1) {
	G <- length(n_per_group)
	beta_shift <- beta_shift %||% cbind(
		rep(0, G),
		seq(-0.4, 0.4, length.out = G),
		seq(0.2, -0.2, length.out = G)
	)
	mu_shift <- mu_shift %||% as.matrix(expand.grid(seq(-0.5, 0.5, length.out = G), seq_len(p))[, 1])
	mu_shift <- matrix(mu_shift, nrow = G, ncol = p)
	list(name = "combined_heterogeneity", data = simulate_scenario(n_per_group, build_group_settings(length(n_per_group), p, base_beta, beta_shift = beta_shift, mu_shift = mu_shift, sigma_y = sigma_y), make_covariance(p, rho)))
}

# Generate all scenarios.
generate_all_scenarios <- function() {
	message("Generating scenarios...")
	list(no_heterogeneity = scenario_no_heterogeneity(), covariate_shift_only = scenario_covariate_shift(), coefficient_heterogeneity_only = scenario_coefficient_heterogeneity(), combined_heterogeneity = scenario_combined_heterogeneity())
}

# Fit the four comparison models.
fit_models <- function(data) {
	list(
		m1 = lm(y ~ x1 + x2, data = data),
		m2 = lm(y ~ x1 + x2 + group, data = data),
		m3 = lm(y ~ x1 * group + x2 * group, data = data),
		m4 = setNames(lapply(levels(data$group), function(g) lm(y ~ x1 + x2, data = data[data$group == g, ])), levels(data$group))
	)
}

# Sign stability rate: fraction of pairwise group comparisons where signs agree.
# Paper: SSR_j = (1/M) sum_m 1(sign(beta_j,a) == sign(beta_j,b)) over all pairs (a,b).
compute_sign_stability <- function(m4) {
	coefs <- do.call(rbind, lapply(m4, coef))[, -1, drop = FALSE]
	pairs <- combn(seq_len(nrow(coefs)), 2, simplify = FALSE)
	apply(coefs, 2, function(betas) {
		mean(sapply(pairs, function(p) as.integer(sign(betas[p[1]]) == sign(betas[p[2]]))))
	})
}

# Standardized coefficient drift: max subgroup departure from pooled, scaled by SE.
# Paper: D_j = max_g |beta_j,g - beta_j,pooled|, D*_j = D_j / SE(beta_j,pooled).
compute_coef_drift <- function(m1, m4) {
	pooled_coef <- coef(m1)[-1]
	pooled_se <- summary(m1)$coefficients[-1, "Std. Error"]
	coefs <- do.call(rbind, lapply(m4, coef))[, -1, drop = FALSE]
	vars <- colnames(coefs)
	max_dev <- sapply(vars, function(v) max(abs(coefs[, v] - pooled_coef[v]), na.rm = TRUE))
	max_dev / pmax(pooled_se[vars], 1e-8)
}

# Mean-spread index for each predictor: average pairwise group mean difference
# scaled by pooled SD, used to contextualize coefficient drift.
compute_mean_spread <- function(data) {
	preds <- c("x1", "x2")
	pooled_sd <- apply(data[, preds], 2, sd)
	groups <- levels(data$group)
	pairs <- combn(groups, 2, simplify = FALSE)
	setNames(sapply(preds, function(v) {
		diffs <- sapply(pairs, function(pair) {
			mu_a <- mean(data[data$group == pair[1], v])
			mu_b <- mean(data[data$group == pair[2], v])
			abs(mu_a - mu_b)
		})
		unname(mean(diffs) / pmax(pooled_sd[v], 1e-8))
	}), preds)
}

# Context-normalized drift: standardized coefficient drift divided by
# one plus the predictor mean-spread index.
compute_context_drift <- function(m1, m4, data) {
	drift <- compute_coef_drift(m1, m4)
	mean_spread <- compute_mean_spread(data)
	drift / (1 + mean_spread[names(drift)])
}

# Transported prediction gap: RMSE of pooled model on group g minus RMSE of own model.
# Paper: TPG_{pooled->g} = RMSE(m1 on group g) - RMSE(m4_g on group g).
compute_tpg <- function(m1, m4, data) {
	sapply(names(m4), function(g) {
		d <- data[data$group == g, ]
		rmse <- function(pred) sqrt(mean((d$y - pred)^2))
		rmse(predict(m1, newdata = d)) - rmse(predict(m4[[g]], newdata = d))
	})
}

# Covariate shift summary: average standardized mean difference across predictors.
# Paper: CSS_{a,b} = (1/p) sum_j |mean_j,a - mean_j,b| / sd_j,pooled.
compute_css <- function(data) {
	preds <- c("x1", "x2")
	pooled_sd <- apply(data[, preds], 2, sd)
	groups <- levels(data$group)
	pairs <- combn(groups, 2, simplify = FALSE)
	setNames(sapply(pairs, function(pair) {
		mu_a <- colMeans(data[data$group == pair[1], preds])
		mu_b <- colMeans(data[data$group == pair[2], preds])
		mean(abs(mu_a - mu_b) / pmax(pooled_sd, 1e-8))
	}), sapply(pairs, function(pair) paste(pair, collapse = "->")))
}

# Compute all metrics for one scenario.
compute_all_metrics <- function(scenario) {
	m <- fit_models(scenario$data)
	list(
		sign_stability = compute_sign_stability(m$m4),
		coef_drift = compute_coef_drift(m$m1, m$m4),
		context_drift = compute_context_drift(m$m1, m$m4, scenario$data),
		tpg = compute_tpg(m$m1, m$m4, scenario$data),
		css = compute_css(scenario$data)
	)
}

# Build group sizes for a grid setting.
make_group_sizes <- function(total_n, G, pattern = c("balanced", "mild", "strong", "random"), min_per_group = 5) {
	pattern <- match.arg(pattern)
	# If G * min_per_group > total_n, lower the floor to what is achievable
	if (G * min_per_group > total_n) {
		min_per_group <- max(2, floor(total_n / G))
	}
	if (pattern == "balanced") {
		w <- rep(1, G)
	} else if (pattern == "mild") {
		w <- seq(1.2, 0.8, length.out = G)
	} else if (pattern == "strong") {
		w <- seq(G, 1, length.out = G)
	} else if (pattern == "random") {
		w <- rgamma(G, shape = 1, rate = 1)
	}
	# Allocate proportionally with floor, ensuring minimum min_per_group per group
	n_raw <- pmax(min_per_group, floor(total_n * w / sum(w)))
	# Scale down if we overshot (limit iterations to avoid infinite loops)
	iter <- 0
	while (sum(n_raw) > total_n) {
		iter <- iter + 1
		if (iter > total_n) stop("make_group_sizes: could not allocate groups within total_n budget")
		largest <- which.max(n_raw)
		n_raw[largest] <- n_raw[largest] - 1
	}
	# Distribute remaining observations to largest groups
	left <- total_n - sum(n_raw)
	if (left > 0) {
		idx_sorted <- order(w, decreasing = TRUE)
		for (k in seq_len(min(left, G))) {
			n_raw[idx_sorted[k]] <- n_raw[idx_sorted[k]] + 1
		}
	}
	# Handle any tiny remainder
	left <- total_n - sum(n_raw)
	if (left > 0) {
		n_raw[idx_sorted[1]] <- n_raw[idx_sorted[1]] + left
	}
	n_raw
}

# Score one setting by averaging all five metrics over repeated replicates.
# Returns means, SDs, and 95% CIs for each aggregate metric.
evaluate_setting <- function(n_per_group, reps = 30) {
	ssr      <- numeric(reps)
	drift    <- numeric(reps)
	ctx_d    <- numeric(reps)
	tpg_m    <- numeric(reps)
	css_m    <- numeric(reps)
	has_na   <- rep(FALSE, reps)
	for (r in seq_len(reps)) {
		s <- scenario_no_heterogeneity(n_per_group = n_per_group)
		m <- compute_all_metrics(s)
		ssr[r]   <- mean(m$sign_stability, na.rm = TRUE)
		drift[r] <- mean(m$coef_drift, na.rm = TRUE)
		ctx_d[r] <- mean(m$context_drift, na.rm = TRUE)
		tpg_m[r] <- mean(m$tpg, na.rm = TRUE)
		css_m[r] <- mean(m$css, na.rm = TRUE)
		has_na[r] <- any(is.na(c(ssr[r], drift[r], ctx_d[r], tpg_m[r], css_m[r])))
	}
	# Drop replicates where any metric is NA (e.g. degenerate fits)
	if (any(has_na)) {
		keep <- !has_na
		ssr   <- ssr[keep]
		drift <- drift[keep]
		ctx_d <- ctx_d[keep]
		tpg_m <- tpg_m[keep]
		css_m <- css_m[keep]
	}
	n_eff <- length(ssr)
	ci <- function(x) {
		m <- mean(x)
		se <- sd(x) / sqrt(n_eff)
		c(lower = max(0, m - 1.96 * se), upper = m + 1.96 * se)
	}
	data.frame(
		n_reps_used  = n_eff,
		mean_ssr     = mean(ssr),
		sd_ssr       = sd(ssr),
		ci_low_ssr   = ci(ssr)["lower"],
		ci_high_ssr  = ci(ssr)["upper"],
		mean_drift   = mean(drift),
		sd_drift     = sd(drift),
		ci_low_drift = ci(drift)["lower"],
		ci_high_drift= ci(drift)["upper"],
		mean_ctx     = mean(ctx_d),
		sd_ctx       = sd(ctx_d),
		ci_low_ctx   = ci(ctx_d)["lower"],
		ci_high_ctx  = ci(ctx_d)["upper"],
		mean_tpg     = mean(tpg_m),
		sd_tpg       = sd(tpg_m),
		ci_low_tpg   = ci(tpg_m)["lower"],
		ci_high_tpg  = ci(tpg_m)["upper"],
		mean_css     = mean(css_m),
		sd_css       = sd(css_m),
		ci_low_css   = ci(css_m)["lower"],
		ci_high_css  = ci(css_m)["upper"],
		objective    = (1 - mean(ssr)) + mean(drift),
		stringsAsFactors = FALSE
	)
}

# Run full grid over group count, sample size, and size balance, then rank settings.
run_settings_grid <- function(
	group_counts   = c(2, 3, 5, 15, 40),
	total_n_values = c(100, 300, 1200, 3000, 6000, 30000, 200000),
	patterns       = c("balanced", "mild", "strong", "random"),
	reps           = 30
) {
	grid <- expand.grid(G = group_counts, total_n = total_n_values, pattern = patterns, stringsAsFactors = FALSE)
	rows <- vector("list", nrow(grid))
	for (i in seq_len(nrow(grid))) {
		G        <- grid$G[i]
		total_n  <- grid$total_n[i]
		pattern  <- grid$pattern[i]
		n_per_group <- make_group_sizes(total_n, G, pattern)
		score <- evaluate_setting(n_per_group, reps = reps)
		rows[[i]] <- data.frame(
			G              = G,
			total_n        = total_n,
			pattern        = pattern,
			n_per_group    = paste(n_per_group, collapse = ","),
			avg_group_size = mean(n_per_group),
			min_group_size = min(n_per_group),
			score,
			stringsAsFactors = FALSE
		)
	}
	res <- do.call(rbind, rows)
	res[order(res$objective), ]
}

# Print a short metric block.
print_metrics <- function(metrics, name) {
	message(sprintf("\n--- %s ---", name))
	print(metrics$sign_stability)
	print(round(metrics$coef_drift, 4))
	print(round(metrics$context_drift, 4))
	print(round(metrics$tpg, 4))
	print(round(metrics$css, 4))
}

# Null helper.
`%||%` <- function(a, b) if (is.null(a)) b else a

if (interactive() || sys.nframe() == 0L) {
	scenarios <- generate_all_scenarios()
	for (nm in names(scenarios)) print_metrics(compute_all_metrics(scenarios[[nm]]), nm)

	message("\nRunning settings grid search (best-case objective: minimize sign instability + drift)...")
	grid_results <- run_settings_grid(reps = 20)
	message("Top 10 settings:")
	print(head(grid_results, 10))
	message("Best setting:")
	print(grid_results[1, ])
}

# Summary for new readers:
# This script is a simulation study for checking when one pooled regression
# may hide subgroup differences.
#
# What is generated:
# - Synthetic datasets with 3 groups (g1, g2, g3).
# - Each row has y, x1, x2, and a group label.
# - x values come from a multivariate normal design.
# - y is linear in x with noise.
#
# Why there are 4 scenarios:
# - no_heterogeneity: groups share the same x distribution and coefficients.
# - covariate_shift_only: groups differ in x distribution, but coefficients match.
# - coefficient_heterogeneity_only: groups share x distribution, but coefficients differ.
# - combined_heterogeneity: groups differ in both x distribution and coefficients.
#
# Why there are 4 fitted models:
# - m1: pooled model that ignores group.
# - m2: pooled model with group intercept shifts.
# - m3: pooled model with group-specific slopes (interactions).
# - m4: fully separate model for each group.
#
# Metrics produced:
# - sign_stability: whether each predictor keeps the same sign across groups.
# - coef_drift: how far subgroup slopes spread around the pooled slope.
# - context_drift: coefficient drift adjusted by predictor mean spread across groups.
# - tpg (transported prediction gap): pooled-vs-group prediction difference by group.
# - css (covariate shift summary): pairwise standardized mean difference between groups.
#
# Grid stage:
# - varies number of groups, total sample size, and balance pattern.
# - ranks settings by objective = (1 - mean sign_stability) + mean coef_drift.
# - the top-ranked setting is the paper's best-case reference point.
#
# Expected use:
# - Run the script, generate all scenarios, fit models, and print metric blocks.
# - Compare metrics across scenarios to see when pooling is reliable vs risky.