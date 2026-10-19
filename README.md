# Regression Conclusion Stability

This repository contains the code, simulation outputs, figures, and LaTeX source for the paper *How Stable Are Regression Conclusions Across Subpopulations? A Finite-Sample Empirical Study*.

## Reproducibility scope

The main simulation study uses four scenarios, 140 design settings per scenario, and 200 Monte Carlo replications per setting. The saved primary outputs are under `results/mc200/`. All random simulation runners set explicit seeds so that an interrupted run can resume from its checkpoint without recomputing completed scenario-setting cells.

The empirical illustration uses NHANES data after running the import script. The raw NHANES files are not redistributed unless their source terms permit it.

## Requirements

- R 4.4 or later
- R packages: `ggplot2`
- LaTeX distribution with `pdflatex` and BibTeX for the manuscript

## Main workflow

Run commands from the repository root.

```powershell
# Import and analyze the empirical illustration.
Rscript scripts/nhanes/import_nhanes.R
Rscript scripts/nhanes/analyze_age_decade.R
Rscript scripts/nhanes/repeated_cv_age_decade.R

# Run the primary 200-replication simulation study.
Rscript scripts/run_all_scenarios_mc200.R

# Recreate the simulation report and manuscript figures.
Rscript scripts/compare_scenarios.R
Rscript scripts/make_mc200_figures.R

# Run the reduced-grid benchmark against the standard interaction F-test.
Rscript scripts/run_interaction_benchmark.R

# Compile the manuscript.
Set-Location paper
pdflatex -interaction=nonstopmode -halt-on-error main.tex
bibtex main
pdflatex -interaction=nonstopmode -halt-on-error main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
```

## Primary outputs

- `results/mc200/grid_results_all_scenarios_mc200.csv`: complete 560-cell simulation output.
- `results/mc200/scenario_comparison_observations.md`: cross-scenario analysis.
- `results/mc200/figures/`: figures used in the manuscript.
- `results/interaction_benchmark/`: reduced-grid interaction-test benchmark.
- `results/interaction_benchmark/interaction_benchmark_summary_mc200.csv`: scenario-level interaction-test rejection-rate summary.
- `results/nhanes_age_decade_cv/`: repeated held-out validation outputs.
- `paper/main.tex`: manuscript source.

## Reproducibility statement

All numerical claims in the manuscript are derived from saved output files in this repository. The 200-replication simulation results are the primary evidence; earlier 30-replication files are retained only as development artifacts. The author is responsible for verifying the final manuscript, data-source terms, and submission materials.