# Authorship and AI Contribution Record

This file tracks which ideas, claims, and decisions originated with the researcher versus which were produced by AI assistance (GitHub Copilot / Claude). Keep this updated honestly. It is primarily for your own clarity and for disclosure if required at submission.

**Rule:** If you generate a claim, equation, or decision yourself, even if AI helped phrase it, it is yours. If AI generated an idea you had not thought of and you adopted it, record it here.

---

## Research Question and Core Framing

| Item | Origin | Notes |
|------|--------|-------|
| Core question: when does pooled regression break down across subpopulations? | **Researcher** | |
| Focus on finite-sample empirical study rather than theory | **Researcher** | |
| Decision to use four comparison models (pooled, intercept shift, interactions, separate) | **Researcher** | |
| Decision to use sign stability as a metric | **Researcher** | |
| Decision to add standardized drift | **Researcher** | |
| Context-normalized drift metric definition | **Researcher** | Researcher identified the concept; AI implemented the formula and code |
| TPG (transported prediction gap) as metric 4 | **Researcher** | |
| CSS (covariate shift summary) as metric 5 | **Researcher** | |

---

## Simulation Study

| Item | Origin | Notes |
|------|--------|-------|
| Four simulation scenarios (no heterogeneity, covariate shift, coefficient heterogeneity, combined) | **Researcher** | |
| Grid design across G, total_n, pattern | **Researcher** | |
| Objective function: $(1 - \text{mean\_ssr}) + \text{mean\_drift}$ | **Researcher** | Researcher confirmed formula; AI verified against CSV |
| Code implementation of `simulate.R` | **AI** | Researcher directed design; AI wrote and debugged code |
| Bug fixes in `make_group_sizes`, `generate_predictors`, `compute_coef_drift` | **AI** | |
| Context-normalized drift formula in methods section | **Researcher (conceptual) / AI (LaTeX wording)** | |

---

## Real-Data Case Studies

| Item | Origin | Notes |
|------|--------|-------|
| Choice of NHANES as case study dataset | **AI suggestion, Researcher approved** | AI proposed based on subpopulation heterogeneity fit; researcher confirmed |
| Choice of AgeDecade as subgrouping variable | **Researcher** | Researcher chose from a list AI provided |
| Observation that BPSysAve is the most unstable predictor | **Analysis output** | Emerged from code; interpretation is researcher's |
| Interpretation of BPSysAve sign reversal in older decades as regime change | **Researcher** | AI described the pattern; researcher judged "regime change" framing |
| Size-sensitivity check idea (compare metrics with/without 0-9 group) | **Researcher** | Researcher raised the concern; AI implemented the check |
| Conclusion that BPSysAve instability is not just a small-sample artifact | **Researcher (based on output)** | |
| Import, EDA, and analysis scripts | **AI** | Researcher directed scope and variable selection |
| Coefficient CI plot (BPSysAve by age decade) | **AI** | Researcher requested the plot; AI designed and produced it |

---

## Paper Draft

| Item | Origin | Notes |
|------|--------|-------|
| Methods section structure and metric definitions | **Researcher (structure) / AI (prose and LaTeX)** | Researcher reviewed and approved all text |
| Real-data section prose | **AI (first draft)** | Based on researcher-directed empirical findings; needs researcher review and rewrite of key claims |
| Discussion section prose | **AI (first draft)** | Researcher should rewrite interpretive paragraphs before submission |
| Introduction | **AI (first draft)** | Structure and framing directed by researcher during literature review; AI wrote prose. Researcher should review all positioning claims before submission. |
| Simulation section | **Not yet drafted** | |
| `paper/references.bib` | **AI** | All citations drawn from researcher-provided literature notes; `hte_ref` citation (Wager & Athey 2018) proposed by AI, needs researcher confirmation. |
| Berk et al. as theoretical foundation for covariate-distribution dependence of OLS coefficients | **AI suggestion, researcher approved** | AI identified this as the key theoretical grounding during literature review; researcher confirmed. |
| Framing Liu et al. (2020) and Bertsimas & Paskov (2020) as contrasts rather than central references | **AI** | Researcher should confirm this positioning is accurate and agrees with intended contribution. |

---

## Simulation Enhancements (2026-07-15)

| Item | Origin | Notes |
|------|--------|-------|
| Addition of "random" imbalance pattern (Gamma weights) to grid | **AI** | Researcher asked for random imbalance mimicking real-data patterns; AI chose Gamma(1,1) distribution |
| Minimum group-size floor (`min_per_group = 5`) | **AI** | Prevents degenerate $n=1$ groups that caused NA results |
| Expansion of `evaluate_setting` to all 5 metrics | **Researcher** | Researcher directed; AI implemented |
| Standard deviation and 95% CI columns in grid output | **Researcher** | Researcher directed; AI implemented |
| NA-replicate filtering in `evaluate_setting` | **AI** | Safety feature to avoid corrupted aggregate metrics
## 2026-07-16 Grid Run

| Item | Origin | Notes |
|------|--------|-------|
| Infinite-loop bug fix in `make_group_sizes` | **AI** | Researcher reported crash; AI diagnosed and fixed the `max(val-1,5)` guard |
| Degenerate-settings diagnosis ($G=40, n=100, \min\_n=2$ skewing means) | **AI** | Researcher asked why mild drift looked wrong; AI identified the 6 outlier rows |
| Decision to use medians or filter $\min\_n < 3$ for paper aggregates | **AI** | Researcher approved |
| GitHub repo initialization and push | **AI** | Researcher provided repo link; AI executed git commands |
---

## 2026-07-17 Simulation Plots, Decomposition Analysis, and Poster

| Item | Origin | Notes |
|------|--------|-------|
| 7 diagnostic simulation plots (drift boxplot, context vs raw, etc.) | **AI** | Researcher asked for "relevant plots"; AI designed and produced all 7 |
| Context-normalized drift decomposition ($D_j^\star = \widetilde{D}_j \times (1+M_j)$) | **AI** | AI derived and documented the mathematical relationship; researcher reviewed and discussed |
| OLS variance derivation for drift decomposition | **AI** | Standard result, used for exposition |
| A0 research poster (`paper/poster.tex`, `poster.pdf`) | **AI** | AI designed layout, wrote content, created tikz diagrams, and compiled; researcher can modify before use |
| Simpson's paradox tikz diagram in poster | **AI** | Custom tikz drawing |
| "It's an Artifact" 3-panel meme flow in poster | **AI** | Designed as pedagogical hook; originally used `mwe` package, later replaced with text-only version |
| Poster redesign (layout fix, Simpson image, reorder, shorten text, future-work block) | **AI** | Redesign directed by user feedback; all changes AI-implemented |

## 2026-07-19/24 Simulation Section and Scenario 4

| Item | Origin | Notes |
|------|--------|-------|
| Simulation section draft (methods + results for Scenario 1) | **AI** | AI wrote full section based on grid results, plots, and decomposition analysis; researcher to review |
| `run_simulation_scenario4.R` grid runner | **AI** | Researcher directed; AI wrote matching-grid script with checkpointing and live progress |
| Scenario 4 analysis script and interpretation | **AI** | AI designed `analyze_s4.R`, ran diagnostics, interpreted findings; researcher to confirm |
| S4 key findings (SSR drops from 1.0, drift 7$\times$ S1, context shrink 32%) | **Analysis output** | Emerged from data; interpretation in log is AI-written |

## 2026-09-08 Scenario 2 and Scenario 3 Runners

| Item | Origin | Notes |
|------|--------|-------|
| `scripts/run_simulation_scenario2.R` full-grid runner | **AI** | Researcher requested a Scenario 2 standalone runner that matches Scenario 1 grid, progress, and checkpoint behavior |
| `scripts/run_simulation_scenario3.R` full-grid runner | **AI** | Researcher requested a Scenario 3 standalone runner that matches Scenario 1 grid, progress, and checkpoint behavior |
| Decision to mirror the completed Scenario 1 runner exactly for comparability | **Researcher** | Researcher explicitly asked for the same grid parameters and workflow structure |
| Parse and small runtime validation workflow for the new runners | **AI** | AI ran syntax checks and scenario-level smoke tests before closing the task |
| Reported Scenario 2 and Scenario 3 metric values from the smoke test | **Analysis output** | Numerical values came directly from code execution |

## 2026-09-14 Cross-Scenario Synthesis and Mathematical Discussion

| Item | Origin | Notes |
|------|--------|-------|
| `compare_scenarios.R` and generated cross-scenario observations report | **AI** | Researcher requested an extensive comparison; AI implemented the common-grid and full-grid summary workflow |
| Decision to use the 56-setting common grid for headline comparisons | **AI suggestion, researcher should confirm** | AI identified the saved Scenario 4 grid and replication mismatch, then proposed strict comparisons only on shared settings |
| Scenario 2 as a primarily design-dependent or mechanical signature | **AI interpretation of analysis output** | Based on high covariate shift, large normalization shrinkage, and low relative prediction gap; researcher should confirm phrasing and implication |
| Scenario 3 as a primarily structural coefficient-heterogeneity signature | **AI interpretation of analysis output** | Based on high remaining drift and transport gap with low covariate shift; researcher should confirm phrasing and implication |
| Scenario 4 as the joint high-instability case | **Analysis output / AI interpretation** | Relative ordering emerges from the common-grid summaries; prose interpretation was drafted by AI |
| Pooled design-weighted target and subgroup-versus-pooled OLS variance derivations | **AI** | Standard regression identities selected and written by AI for exposition; researcher requested a more mathematical discussion |
| Sign-instability approximation and target-group excess prediction-risk expression | **AI** | Standard approximate arguments included to explain the simulated patterns; researcher should review mathematical assumptions |
| Limitations section | **AI (first draft)** | Includes diagnostic, design, and observational limitations; researcher should revise and approve before submission |
| Bibliography-path correction in `paper/main.tex` | **AI** | Technical build correction, verified by successful BibTeX and LaTeX compilation |

## 2026-10-17 High-Replication Simulation Refresh

| Item | Origin | Notes |
|------|--------|-------|
| Unified 200-replication runner, checkpointing, and separate output directory | **AI** | Researcher requested a stronger Monte Carlo design; AI implemented `run_all_scenarios_mc200.R` and its resume workflow |
| Decision to use 200 replications per scenario-setting cell | **AI suggestion, researcher adopted** | Chosen to reduce setting-level Monte Carlo uncertainty while keeping the full 560-cell grid computationally feasible |
| Completed 112,000-replication simulation output | **Analysis output** | Numerical results emerged from the completed run |
| Revised scenario-comparison report and manuscript numbers | **AI (analysis and prose) / Analysis output (values)** | AI updated reporting from the saved 200-replication output; researcher should confirm substantive interpretation |
| Correction of sign-stability and group-count interpretations | **AI** | AI identified that earlier prose overstated Scenario 4 sign instability and misdescribed proportional drift growth across scenarios |
| New 200-replication figures and cross-scenario comparison figure | **AI** | AI implemented `make_mc200_figures.R` and updated manuscript figure paths |
| Updated professor brief | **AI (first draft revision)** | Numerical table and mathematical prediction-gap expression updated to match the completed simulation and implementation |
| Replacement of the 56-setting common-grid comparison | **Analysis-driven correction** | The aligned 200-replication study makes all 136 retained settings directly comparable; this supersedes the earlier temporary 56-setting comparison |

## 2026-10-17 Interaction Benchmark and Held-Out Validation

| Item | Origin | Notes |
|------|--------|-------|
| Reduced-grid interaction F-test benchmark design and runner | **AI suggestion, researcher adopted** | AI proposed the benchmark to compare the diagnostics with standard interaction regression; researcher requested its implementation |
| Interaction-test rejection-rate results | **Analysis output** | Results came from the completed 14,400-replication benchmark |
| Interpretation that the diagnostics complement rather than replace the F-test | **AI interpretation, researcher should confirm** | Based on the F-test distinguishing slope-heterogeneity scenarios while the diagnostics quantify magnitude, covariate context, and predictive consequences |
| Repeated stratified cross-validation design and runner | **AI suggestion, researcher adopted** | AI proposed and implemented 20 repeats of five-fold validation after the researcher requested submission-strengthening steps |
| Held-out RMSE results and descriptive interval | **Analysis output** | Values came from 800 group-fold evaluations; interval is intentionally described as descriptive because repeated folds are dependent |
| Main results table, data-and-code availability statement, and reproducibility README | **AI** | AI drafted and implemented the submission materials using researcher-provided project outputs and repository link |

## Session Maintenance and Admin

| Item | Origin | Notes |
|------|--------|-------|
| Daily project-log template and session logging structure | **AI** | User requested a separate calendar/log file; AI created the initial format |
| MiKTeX warning diagnosis and cache-clearing steps | **AI** | Technical troubleshooting and wording were AI-assisted |
| Reminder to keep logging daily work and AI contributions | **AI** | Added to project instructions |

---

## Claims That Need Researcher Verification Before Submission

- [ ] All numerical results in `real_data.tex` match current CSV outputs.
- [ ] The framing of BPSysAve instability as "regime-dependent" reflects researcher's own judgment.
- [ ] The discussion limitation paragraph accurately represents what was and was not done.
- [ ] Any comparative claims ("larger than," "consistent with") are verified against literature.
- [ ] No references have been invented by AI (currently no citations in draft; verify when added).

---

## AI Disclosure Template (for submission if required)

> This paper used GitHub Copilot (Claude Sonnet 4.6-Codex 5.3-GPT .4-5.4 mini-Deepseek V4 Pro) as a coding and writing assistant. The assistant helped implement R analysis scripts, generate figures, and produce first-draft prose for the Methods, Real Data, and Discussion sections. All research questions, experimental decisions, empirical interpretations, and final claims were made by the author. All AI-generated text was reviewed and revised before inclusion.
