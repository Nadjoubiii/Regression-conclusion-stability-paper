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
