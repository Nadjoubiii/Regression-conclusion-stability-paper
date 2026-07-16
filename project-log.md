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

<!-- TEMPLATE for future entries:

## YYYY-MM-DD

**Focus:** [one-line summary]

- [What changed or was done]
- [Decisions made and why]
- [Results or outputs produced]
- [Any deviations from plan and why]

**Next:** [Concrete next step]

-->
