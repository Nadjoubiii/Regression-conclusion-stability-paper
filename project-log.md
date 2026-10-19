# Project Log

One entry per working session. Add a bullet for each meaningful thing done, decided, or changed.
**Rule:** At the end of every session, record what changed, why, and what the next step is.

---

## 2026-07-12 (Session 1 of recorded log)

**Focus:** Simulation engine, metric design, LaTeX build, real-data setup.

- Finalized five core stability metrics: SSR, standardized drift, context-normalized drift, TPG, CSS.
- Implemented full simulation grid in `scripts/simulate.R` with four heterogeneity scenarios and 105 parameter settings.
- Added `mean_context_drift` to grid output and verified 105-row CSV.
- Fixed bugs in `make_group_sizes()`, `generate_predictors()`, `compute_coef_drift()`, and `compute_mean_spread()`.
- Confirmed `objective = (1 - mean_ssr) + mean_drift` matches CSV to floating-point precision.
- Generated objective ranking plots: `results/figures/objective_top20.png`, `results/figures/objective_by_G_pattern.png`.
- Updated `paper/sections/methods.tex` to include context-normalized drift formula and five-metric table.
- Fixed LaTeX build: `latexmk` unavailable (Perl missing); switched to direct `pdflatex`. Build succeeded.
- Ran `mpm --update-db` and `mpm --update` to suppress MiKTeX warnings.
- Updated `.github/copilot-instructions.md` to enforce LaTeX delimiters in chat.
- Created `scripts/nhanes/import_nhanes.R` and `scripts/diabetes/import_diabetes.R`.
- Both import scripts run successfully; NHANES (10000 rows, 76 cols) and diabetes (442 rows, 3 cols) saved to `data/raw/`.

**Next:** Begin NHANES EDA and real-data analysis pipeline.

---

## 2026-07-13

**Focus:** NHANES exploratory analysis, age-decade subgroup regression, paper draft update.

- Created `scripts/nhanes/eda_nhanes.R`; ran and saved EDA outputs (missingness tables, histograms) to `results/nhanes_eda/`.
- Chose NHANES subgrouping variable: **AgeDecade** (8 groups after complete-case filter, $n=7116$).
- Rationale for AgeDecade: large between-group contrast, clinically interpretable, compatible with existing heterogeneity literature.
- Created `scripts/nhanes/analyze_age_decade.R` with pooled and subgroup OLS fits, SSR, standardized drift, context-normalized drift, and prediction accuracy by decade.
- Fixed two bugs: SSR vector naming and pooled SE extraction (caused NA drift); both resolved.
- Key empirical findings:
  - mean SSR = 0.814, mean drift = 16.203, mean context drift = 11.339.
  - **BPSysAve** is the least stable predictor: SSR = 0.571, drift = 32.070, context drift = 17.641.
  - BPSysAve coefficient changes **sign** in decades 60-69 and 70+.
  - Group-specific models outperform pooled in every decade (better RMSE and $R^2$).
  - Largest pooled failure: ages 0-9 (pooled $R^2 = -3.49$ vs subgroup $R^2 = 0.24$).
- Added BPSysAve coefficient-by-age-decade CI plot: `results/nhanes_age_decade/bpsys_coef_by_age_decade_ci.png`.
- Ran size sensitivity check (`scripts/nhanes/size_sensitivity_check.R`):
  - Excluding 0-9 reduces drift for DirectChol dramatically (16.3 → 4.7) but BPSysAve instability persists (drift 32.1 → 28.7).
  - Conclusion: BPSysAve instability is **regime-dependent** (older decades), not a pure small-sample artifact.
- Updated `paper/sections/real_data.tex` with full NHANES analysis write-up and embedded BPSys CI figure.
- Updated `paper/sections/discussion.tex` with interpretation and limitations.
- Paper compiled successfully: `paper/main.pdf` (5 pages).

**Deviation from plan noted:** Analysis has moved deeper into NHANES EDA and subgroup diagnostics than originally scoped. The original plan targeted real-data case studies as illustration; the current direction is becoming a more detailed empirical finding. Need to decide whether to scope back or reframe the real-data section as a richer case study.

**Next:** Either continue NHANES (cross-validation, bootstrap CIs) or start diabetes case study. Recheck alignment with core research questions in `plan.tex`.

---

## 2026-07-14

**Focus:** Literature review, introduction draft, references.bib, section labels.

- Reviewed all literature files (`references&papers.tex`, `papers.txt`) and identified all PDFs in the project root.
- Confirmed paper identities: `Paper1.pdf` = Tsoi & Sun (2026); `1-s2.0-...` = Liu et al. (2020) JoE; `OBSERVATIONS ON BAGGING` = Buja & Stuetzle (2006); `Engle_Watson_ReStat_1985.pdf` = Watson & Engle (1985); `Garbade-TwoMethodsExamining-1977.pdf` = Garbade (1977); `Assumption lean regression.pdf` = Berk et al. (2019); JMLR 21(230) = Bertsimas & Paskov (2020).
- Confirmed full citation for Stable Regression paper: **Bertsimas & Paskov (2020), JMLR 21(230)**.
- Decided metric-origin discussion belongs in Methods (after each formula), not in Introduction.
- Drafted full Introduction (`paper/sections/introduction.tex`): 7 paragraphs covering motivation, Berk et al. theoretical grounding, temporal stability literature, HTE literature and Tsoi & Sun positioning, contrasts with Bertsimas/Liu, contribution statement, and outline.
- Created `paper/references.bib` with entries for all 7 references (berk2019, tsoi2026, bertsimas2020, liu2020, watsenengle1985, garbade1977, buja2006, hte_ref).
- Note: `hte_ref` currently set to Wager & Athey (2018) -- needs researcher confirmation of preferred HTE citation.
- Added `\label{sec:...}` to all six paper sections so Introduction cross-references compile correctly.
- Updated `\bibliography` in `main.tex` to point only at `paper/references`.

**Decisions made:**
- Metric provenance stays in Methods, not Introduction.
- Introduction frames the paper around diagnostics vs. enforcement/testing, contrasting our contribution with Bertsimas & Paskov (design-time stability) and Tsoi & Sun (hypothesis testing).

**Next:** Add metric-origin sentences to Methods after each formula definition. Then draft Simulation section.

- Investigated the recurring MiKTeX warning about not checking for updates.
- Confirmed the paper build already used `pdflatex`, so the engine was not the issue.
- Found the warning was coming from `C:\Users\user\AppData\Roaming\MiKTeX\miktex\config\issues.json`.
- Cleared the stale issue-cache entry, then re-ran `pdflatex` successfully with no warning.
- Confirmed the paper still compiles cleanly after the cleanup.

**Next:** Continue manuscript refinement and keep logging major decisions and deviations daily.

---

## 2026-07-15

**Focus:** Simulation grid enhancement -- all 5 metrics, SDs, CIs, random imbalance.

- Reviewed existing grid results (`results/grid_results.csv`): 105 rows, scenario 1 only, only SSR/drift/ctx-drift, no SDs.
- Identified two problems: (1) grid evaluates no-heterogeneity scenario only across all 105 settings, (2) "strong" imbalance is deterministic linear and can produce $n=1$ groups causing NA results.
- Modified `scripts/simulate.R`:
  - **`make_group_sizes`**: Added `"random"` pattern using Gamma(1,1) weights per group, with `min_per_group = 5` floor to prevent degenerate groups. Also added overshoot guard and remainder distribution logic.
  - **`evaluate_setting`**: Expanded from 3 metrics (SSR, drift, ctx-drift) to all 5 (SSR, drift, ctx-drift, TPG, CSS). Added `sd_*` and `ci_low_*`/`ci_high_*` columns (mean $\pm 1.96 \times \text{SE}$). Added NA-replicate filtering so degenerate fits don't corrupt means.
  - **`run_settings_grid`**: Updated default patterns to `c("balanced","mild","strong","random")`. Kept scenario 1 only for now.
- Grid NOT yet rerun; code changes only.
- Also:
  - Discussed the missing sign-flip scenario for SSR (SSR $=1.0$ in all four current scenarios; need scenario where coefficients cross zero across groups to see SSR behavior).
  - Discussed adding scenario type as a grid factor for the next round.

**Decisions made:**
- Grid stays at $5 \times 7 \times 4 = 140$ settings (adding "random" pattern), scenario 1 only for now.
- Keep `objective = (1 - \text{mean\_ssr}) + \text{mean\_drift}` as the ranking criterion.

**Next:** Run the updated grid; then add scenario type as a grid factor for a multi-scenario comparison.

**Deviation from plan:** This is a refinement of the original grid design, not a deviation.

**Random imbalance justification (2026-07-15):**
- The "random" pattern draws group proportions from a flat $\text{Dirichlet}(1, \dots, 1)$, equivalent to $G$ independent $\text{Exponential}(1)$ draws normalized by their sum.
- This is distribution-free over the simplex: every partition of $n$ across $G$ groups receives equal prior probability weight.
- Over replicates, the pattern covers the full imbalance spectrum -- from near-balance to extreme concentration -- without favoring any particular shape.
- Contrasts with "strong" (deterministic monotone extreme) and "mild" (shallow deterministic), filling the gaps uniformly.
- Justification to be documented in the paper's Simulation section when drafted.

## 2026-07-16

**Focus:** Grid simulation run, degenerate-settings diagnosis, GitHub repo push.

- Fixed infinite-loop bug in `make_group_sizes` when $G \times \text{min\_per\_group} > \text{total\_n}$ (the `max(val-1, 5)` guard prevented the while-loop from ever reducing the sum). Fixed by lowering the floor dynamically and adding an iteration guard.
- Killed the 13-hour hung process (overnight run was stuck on the same bug).
- Ran the full grid successfully: 140 settings $\times$ 30 reps = 4200 replicates. Output: `results/grid_results.csv` (140 rows, 28 columns).
- Diagnosed pattern-level mean distortion: 6 degenerate rows ($G=40$, $n=100$, $\min\_n=2$) produce drift in hundreds to 39,303, skewing means.
  - Median drift: balanced 3.07, mild 3.16, strong 4.03, random 6.88. Sensibly ordered.
  - Mean drift: balanced 22.0, mild 1129.1 (inflated by one row at 39303), strong 35.9, random 216.4.
  - Recommendation: use medians or filter $\min\_n < 3$ (drops 6/140 rows) for all paper aggregations.
- Documented degenerate-settings note in `paper/sections/simulation.tex`.
- Initialized git repo and pushed to GitHub: `https://github.com/Nadjoubiii/Regression-conclusion-stability-paper.git`

**Decisions made:**
- Paper simulation aggregates must use medians or explicitly exclude $\min\_n < 3$ settings.
- Future scenario-comparison grid should also enforce $\min\_n \geq 5$ to avoid degenerate sub-models.

**Next:** Analyze the full grid results. Produce summary plots. Draft the simulation section of the paper.

---

## 2026-07-17

**Focus:** Simulation diagnostic plots, context-drift decomposition analysis, A0 research poster.

- Created 7 diagnostic plots from grid results (filtered to min\_group\_size >= 3):
  - `drift_by_G_and_pattern.png` — boxplot: drift rises with G, strong/random amplify it.
  - `ssr_by_G_and_pattern.png` — SSR flat at 1.0 (Scenario 1 has no sign flips).
  - `context_vs_raw_drift.png` — log-log scatter: all points below 1:1 line, confirming context normalization shrinks drift systematically.
  - `drift_vs_avgn_by_G.png` — drift drops steeply as per-group n grows beyond ~50.
  - `drift_shrinkage_pct.png` — shrinkage % rises with CSS; larger covariate shift = more context normalization matters.
  - `ssr_vs_drift.png` — SSR flat at 1.0 regardless of drift magnitude (Scenario 1 limitation).
  - `drift_heatmap.png` — 4-panel heatmap of drift by G $\times$ total\_n, faceted by pattern; drift explodes at high G + small n.
- Derived and documented the mathematical decomposition of context-normalized drift:
  - $D_j^\star = \widetilde{D}_j \times (1 + M_j)$ — total observed drift = genuine component $\times$ mechanical inflation from covariate spread.
  - Showed OLS variance derivation: $\text{Var}(\hat\beta^{(g)} - \hat\beta^{(\text{pooled})}) = \sigma^2[(X_g'X_g)^{-1} + (X'X)^{-1}]$.
  - Three diagnostic regimes: (1) $M_j \approx 0 \Rightarrow \widetilde{D}_j \approx D_j^\star$ (all real), (2) large $M_j$ + small $\widetilde{D}_j$ = artifact, (3) both large = genuine heterogeneity.
- Designed and compiled an **A0 landscape research poster** (`paper/poster.tex` $\to$ `poster.pdf`, 251 KB, 0 errors):
  - 3-column layout with 11 blocks covering: problem hook, Simpson's paradox diagram, "It's an Artifact" 3-panel meme, four models table, five metrics table with formulas, decomposition equation with OLS derivation, simulation grid with embedded plots, NHANES real-data results with coefficient CI plot, driver diagram (5 factors $\to$ instability), take-home messages, and references.
  - Visual elements include custom tikz diagrams for Simpson's paradox and causal drivers, 3-panel meme flow, highlighted equation box, and two embedded simulation plots.
- Redesigned poster per user feedback: replaced Simpson's tikz with actual image (`simpson.jpg`), fixed overlapping meme boxes, shortened text, reordered content (real-data evidence before metrics/simulation as proof of need), added future-work block (collinearity $\to$ higher dimensions $\to$ different models). Removed `mwe`-package dependency.

**Decisions made:**
- Context normalization decomposition is a core contribution and should drive the simulation section narrative.
- The "artifact" framing (separating mechanical from genuine drift) is a clear way to communicate the contribution to applied audiences.
- Poster can be used for departmental seminars or conference submission.

**Next:** Draft the simulation section using the plots and decomposition analysis. Then run multi-scenario comparison (Scenarios 2-4) and create a sign-flip scenario to observe SSR < 1 behavior.

---

<!-- TEMPLATE for future entries:

## YYYY-MM-DD

**Focus:** [one-line summary]

- [What changed or was done]
- [Decisions made and why]
- [Results or outputs produced]
- [Any deviations from plan and why]

**Next:** [Concrete next step]

-->

---

## 2026-09-08

**Focus:** Scenario 2 and Scenario 3 full-grid runners, aligned to the Scenario 1 benchmark grid.

- Created `scripts/run_simulation_scenario2.R` for the covariate-shift-only design and `scripts/run_simulation_scenario3.R` for the coefficient-heterogeneity-only design.
- Matched both runners to the completed Scenario 1 workflow: same grid over group count, total sample size, and imbalance pattern; same 30 replicates per setting; same live progress printing; same checkpoint behavior.
- Kept outputs separated by scenario so the new runs can be compared directly against Scenario 1 and Scenario 4 summaries.
- Verified both scripts parse successfully before runtime testing.
- Ran small runtime checks by sourcing `scripts/simulate.R` and evaluating each scenario at `n_per_group = c(30, 30, 30)`.
- Runtime check results:
  - Scenario 2: SSR = 1.000, drift = 1.832, context = 1.182, TPG = 0.026, CSS = 0.557.
  - Scenario 3: SSR = 1.000, drift = 2.790, context = 2.497, TPG = 0.066, CSS = 0.113.
- This keeps the multi-scenario comparison design consistent instead of mixing Scenario 1 with ad hoc runner settings.

**Decisions made:**
- Use the existing Scenario 1 runner as the exact template for Scenario 2 and 3, rather than the earlier Scenario 4 variant, so cross-scenario comparisons stay clean.

**Next:** Launch the full Scenario 2 and Scenario 3 grids, then summarize how covariate shift alone differs from coefficient heterogeneity alone across the five metrics.

---

## 2026-09-14

**Focus:** Cross-scenario synthesis, manuscript integration, mathematical discussion, and limitations.

- Created `scripts/compare_scenarios.R` and generated `results/scenario_comparison_observations.md`, which compares all four scenario outputs using the retained settings with minimum subgroup size at least 3.
- Identified that the saved Scenario 4 output uses different intermediate group counts, total sample sizes, and a larger replication budget than Scenarios 1--3.
- Separated full-grid descriptive summaries from the strict 56-setting common-grid comparison, avoiding an unsupported direct ranking over mismatched grids.
- Updated `paper/sections/simulation.tex` with the completed results for all four scenarios, the common-grid comparison rule, and the covariate-shift versus coefficient-heterogeneity interpretation.
- Expanded `paper/sections/discussion.tex` with the pooled design-weighted target, the subgroup-versus-pooled OLS variance expression, sign-instability intuition, and the target-group excess prediction-risk expression.
- Added a dedicated limitations section covering the low-dimensional linear design, the descriptive status of context-normalized drift, pooled-target weighting, observational interpretation, and the Scenario 4 grid mismatch.
- Replaced the conclusion placeholder in `paper/sections/conclusion.tex` with a concise synthesis and future-work statement.
- Corrected the bibliography path in `paper/main.tex` from `paper/references` to `references`, allowing BibTeX to locate the existing database.
- Compiled the manuscript with BibTeX and repeated `pdflatex` passes. The build completed successfully: `paper/main.pdf` is 13 pages with citations and references resolved.

**Decisions made:**
- Treat the common-grid comparison as the main basis for claims across all four scenarios; use full-grid summaries only for within-scenario description.
- Frame covariate shift as changing subgroup information, leverage, and transport conditions under a correctly specified common-slope model, rather than as automatically changing the population slope.

**Deviation from plan:** The work expanded from reporting simulation outcomes to providing a mathematical explanation and explicit limitations. This improves the manuscript's defensibility but requires researcher review of the interpretive claims before submission.

**Next:** Review the new mathematical discussion for accuracy and preferred emphasis, then decide whether to rerun Scenario 4 on the shared grid before preparing a final cross-scenario figure and table.

---

## 2026-10-17

**Focus:** Completed 200-replication four-scenario study and manuscript refresh.

- Created and ran `scripts/run_all_scenarios_mc200.R`, a resumable unified runner for all four scenarios.
- Completed the full $4 \times 140 \times 200 = 112{,}000$-replication study. Each scenario has 140 unique settings, 200 valid replications per setting, and no duplicate grid cells.
- Saved the new outputs separately under `results/mc200/`, preserving the earlier 30-replication files as exploratory results.
- Updated `scripts/compare_scenarios.R` to analyze the 200-replication outputs and generated `results/mc200/scenario_comparison_observations.md`.
- Corrected two interpretation errors exposed by the larger run: Scenario 4 has the largest median raw drift and pooled-versus-subgroup prediction gap; Scenario 3 has the largest share of retained settings with SSR below one and the largest median context-normalized drift.
- Added `scripts/make_mc200_figures.R` and generated a new figure set under `results/mc200/figures/`, including a cross-scenario drift comparison.
- Updated the simulation section, limitations, and the two-page professor brief with the new results, figure paths, and the correct pooled-versus-subgroup prediction-gap definition.
- Recompiled `paper/main.pdf` successfully at 12 pages and `paper/professor_brief.pdf` successfully at 2 pages.

**Decisions made:**
- The 200-replication unified grid is now the sole basis for headline simulation claims. The older 30-replication runs remain only as development artifacts.
- Use medians over settings with minimum subgroup size at least 3 for primary cross-scenario summaries.

**Next:** Add one targeted robustness extension, preferably out-of-sample validation for the empirical illustration or a reduced-grid sensitivity analysis for predictor correlation and heterogeneity strength.

---

## 2026-10-17 (Submission Strengthening)

**Focus:** Standard-method benchmark, held-out empirical validation, and reproducibility package.

- Added `scripts/run_interaction_benchmark.R`, a resumable reduced-grid benchmark of the standard group-slope interaction F-test at $\alpha=0.05$.
- Completed the benchmark: 72 scenario-setting cells $\times$ 200 replications = 14,400 additional simulation replicates.
- Benchmark results: average interaction-test rejection rates were 0.051 (Scenario 1), 0.049 (Scenario 2), 0.852 (Scenario 3), and 0.845 (Scenario 4).
- Added the benchmark design and results table to the Methods and Simulation sections. The manuscript now states that the diagnostics complement the interaction test by describing effect magnitude, covariate separation, and the within-group predictive cost of pooling.
- Added `scripts/nhanes/repeated_cv_age_decade.R` and ran 20 repetitions of stratified five-fold cross-validation.
- The pooled model had higher held-out RMSE in every age group. Across 800 group-fold evaluations, pooled RMSE exceeded age-specific RMSE by 0.911 on average; the descriptive repeated-CV interval was [0.813, 1.008].
- Added the repeated-CV design, result, and figure to the Methods and Empirical Illustration sections.
- Added a main 200-replication scenario summary table, `README.md` with commands and output locations, and a data-and-code availability statement linking the repository.
- Updated `paper/professor_brief.tex` with the held-out validation and interaction-test comparison.
- Final builds succeeded: `paper/main.pdf` is 13 pages and `paper/professor_brief.pdf` is 2 pages, with no unresolved references or layout warnings.

**Decisions made:**
- Use the interaction F-test as a benchmark, not as a competing replacement for the descriptive diagnostics.
- Describe repeated-CV intervals as variation over repeated fold assignments rather than formal population confidence intervals.

**Next:** Review the final submission package, verify the public repository and data-source terms, then select a journal and prepare its manuscript-specific cover letter and formatting.
