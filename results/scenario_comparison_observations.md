# Scenario Comparison Observations

Generated on 2026-09-22 10:57:30.

This note compares the four simulation scenarios using the saved grid outputs in `results/`. The main comparison uses only settings with `min_group_size >= 3`, because very sparse subgroup corners create unstable outliers that distort mean-based summaries.

## Coverage and comparability

```text
 scenario settings degenerate_settings reps_min reps_max
       S1      136                   0       30       30
       S2      136                   0       30       30
       S3      136                   0       30       30
       S4      136                   0       30       30
```

Observations:
- All four scenarios retain 136/140 (S1), 136/140 (S2), 136/140 (S3), and 136/140 (S4) settings after the `min_group_size >= 3` filter.
- All scenarios use the same 140-setting design: `G` values 2, 3, 5, 15, 40; `total_n` values 100, 300, 1200, 3000, 6000, 30000, 2e+05; and all four imbalance patterns.
- Every completed setting uses 30 replications, so Monte Carlo means and interval widths are directly comparable across scenarios.
- Degenerate sparse-corner settings are concentrated where `G` is large and `total_n` is small; keeping them out is important for fair cross-scenario comparisons.

## Unified-grid comparison

```text
 scenario median_ssr mean_ssr share_ssr_below_1 median_drift mean_drift
       S1          1    0.980             0.272        3.807     13.603
       S2          1    0.978             0.265        3.978     12.087
       S3          1    0.977             0.272       24.120     44.791
       S4          1    0.976             0.294       25.452     47.505
 median_context median_tpg median_css median_shrink_pct
          3.455      0.005      0.064             5.886
          2.633      0.004      0.498            33.069
         21.753      0.063      0.058             5.471
         16.117      0.065      0.495            32.689
```

Unified-grid observations:
- This is the headline comparison because every scenario is evaluated on the same retained settings with the same replication budget.
- Scenario 4 has the weakest sign stability by mean SSR and unstable-setting share, as well as the highest median raw drift and transported prediction gap.
- Scenario 3 has the highest median context-normalized drift. This is consistent with coefficient heterogeneity remaining after little adjustment for covariate separation, whereas normalization removes a larger mechanical component in Scenario 4.
- Scenario 2 still has the highest CSS and the largest shrinkage from raw to context-normalized drift, which is the expected signature of primarily mechanical instability.
- Scenario 3 remains the cleanest coefficient-heterogeneity benchmark: drift and TPG are much larger than Scenario 1, while CSS stays near the no-heterogeneity baseline.
- Scenario 1: no heterogeneity: median SSR = 1.000, median drift = 3.807, median context drift = 3.455, median TPG = 0.0050, median CSS = 0.064, median shrinkage = 5.9%, SSR < 1 in 27.2% of retained settings.
- Scenario 2: covariate shift only: median SSR = 1.000, median drift = 3.978, median context drift = 2.633, median TPG = 0.0038, median CSS = 0.498, median shrinkage = 33.1%, SSR < 1 in 26.5% of retained settings.
- Scenario 3: coefficient heterogeneity only: median SSR = 1.000, median drift = 24.120, median context drift = 21.753, median TPG = 0.0632, median CSS = 0.058, median shrinkage = 5.5%, SSR < 1 in 27.2% of retained settings.
- Scenario 4: combined heterogeneity: median SSR = 1.000, median drift = 25.452, median context drift = 16.117, median TPG = 0.0650, median CSS = 0.495, median shrinkage = 32.7%, SSR < 1 in 29.4% of retained settings.

## Relative to Scenario 1

```text
 scenario drift_vs_s1 context_vs_s1 tpg_vs_s1 css_vs_s1
       S1       1.000         1.000     1.000     1.000
       S2       1.045         0.762     0.756     7.724
       S3       6.336         6.296    12.691     0.899
       S4       6.686         4.665    13.048     7.676
```

Comparative observations:
- Scenario 2: covariate shift only relative to Scenario 1: drift 1.04x, context drift 0.76x, TPG 0.76x, CSS 7.72x.
- Scenario 3: coefficient heterogeneity only relative to Scenario 1: drift 6.34x, context drift 6.30x, TPG 12.69x, CSS 0.90x.
- Scenario 4: combined heterogeneity relative to Scenario 1: drift 6.69x, context drift 4.66x, TPG 13.05x, CSS 7.68x.
- Scenario 2 isolates mechanical instability: CSS jumps the most, but SSR remains at or extremely near 1 and TPG stays relatively small compared with Scenarios 3 and 4.
- Scenario 3 isolates genuine relationship instability: it raises drift, context drift, and TPG sharply with much lower CSS than Scenario 2.
- Scenario 4 combines both mechanisms: it is worst on sign stability, raw drift, and transported prediction error, while its context-normalized drift remains well above the Scenario 1 baseline.

## By number of groups

```text
 scenario  G median_ssr median_drift median_context median_tpg median_css
       S1  2      1.000        0.988          0.948      0.001      0.032
       S1  3      1.000        2.004          1.911      0.001      0.035
       S1  5      1.000        3.717          3.255      0.005      0.059
       S1 15      1.000       12.322         11.127      0.017      0.112
       S1 40      0.995       31.682         25.173      0.022      0.130
       S2  2      1.000        1.216          0.642      0.001      0.900
       S2  3      1.000        2.134          1.315      0.002      0.620
       S2  5      1.000        3.768          2.544      0.003      0.478
       S2 15      1.000       13.275          9.695      0.016      0.375
       S2 40      0.994       29.978         21.083      0.022      0.363
       S3  2      1.000       18.926         18.390      0.088      0.033
       S3  3      1.000       19.248         18.547      0.062      0.038
       S3  5      1.000       17.013         16.276      0.050      0.056
       S3 15      1.000       23.576         19.968      0.047      0.095
       S3 40      0.998       55.699         47.344      0.052      0.131
       S4  2      1.000       18.618          9.828      0.087      0.899
       S4  3      1.000       21.029         13.035      0.063      0.621
       S4  5      1.000       20.660         13.741      0.051      0.473
       S4 15      1.000       26.859         19.056      0.048      0.370
       S4 40      0.997       58.769         42.852      0.056      0.357
 median_shrink_pct
             3.285
             3.387
             5.559
            10.051
            11.631
            47.362
            38.179
            32.303
            27.266
            26.518
             3.043
             3.610
             5.276
             8.702
            11.594
            47.316
            38.318
            32.049
            27.026
            26.276
```

Observations by `G`:
- Median drift grows with `G` in every scenario, but the growth is steepest where coefficient heterogeneity is present. The `G=40` to `G=2` drift ratio is S1 32.08x; S2 24.66x; S3 2.94x; S4 3.16x.
- Scenario 1 shows that even without true heterogeneity, splitting the sample into many groups creates nontrivial finite-sample drift. That is the baseline mechanical penalty of subgrouping.
- Scenario 2 amplifies that baseline mostly through CSS and moderate drift inflation, not through sign reversals.
- Scenarios 3 and 4 deteriorate more sharply as `G` rises, which is consistent with more subgroup-specific coefficients being estimated from smaller effective samples.
- The TPG increase from `G=2` to `G=40` is mild in Scenario 1, noticeable in Scenario 2, and materially larger in Scenarios 3 and 4.

## By imbalance pattern

```text
 scenario  pattern median_ssr median_drift median_context median_tpg median_css
       S1 balanced      1.000        3.029          2.830      0.002      0.051
       S1     mild      1.000        3.131          2.921      0.002      0.053
       S1   strong      1.000        4.013          3.882      0.004      0.063
       S1   random      0.998        6.768          5.980      0.018      0.086
       S2 balanced      1.000        3.233          2.197      0.003      0.498
       S2     mild      1.000        3.189          2.162      0.002      0.496
       S2   strong      1.000        4.031          2.728      0.004      0.497
       S2   random      1.000        6.010          4.043      0.010      0.508
       S3 balanced      1.000       21.097         19.253      0.056      0.049
       S3     mild      1.000       23.386         19.769      0.057      0.051
       S3   strong      1.000       28.864         27.401      0.071      0.059
       S3   random      1.000       27.829         25.388      0.077      0.079
       S4 balanced      1.000       22.407         14.272      0.056      0.484
       S4     mild      1.000       23.351         15.062      0.057      0.496
       S4   strong      1.000       29.980         19.520      0.070      0.492
       S4   random      1.000       31.807         20.803      0.080      0.521
 median_shrink_pct
             4.819
             5.135
             5.737
             7.832
            33.087
            33.288
            32.778
            33.069
             4.535
             4.747
             5.497
             7.366
            32.284
            33.159
            32.550
            33.995
```

Observations by pattern:
- The worst pattern by median drift is S1 -> random; S2 -> random; S3 -> strong; S4 -> random.
- The lowest-SSR pattern within each scenario is S1 -> random; S2 -> balanced; S3 -> balanced; S4 -> balanced.
- Balanced and mild settings are usually the most stable. Strong and random imbalance tend to increase drift because they leave some groups with less information and more leverage-sensitive estimates.
- Random imbalance is especially informative because it often produces worse instability than mild imbalance without imposing a deterministic size ordering. That makes it a useful bridge between clean theoretical patterns and messier real subgroup structures.
- In Scenario 2, pattern effects are seen mostly through CSS and shrinkage. In Scenarios 3 and 4, pattern effects also spill into SSR and TPG because distribution imbalance interacts with coefficient differences.

## Most unstable retained settings

Top settings by objective/drift:
```text
 scenario_id  G total_n pattern min_group_size mean_ssr mean_drift
          S1 15   2e+05  random              5    0.980    253.186
          S4  2   2e+05  random          19807    1.000    236.274
          S3  2   2e+05  random          19905    1.000    229.969
          S3 40   2e+05  strong            243    1.000    193.153
          S4 40   2e+05  strong            243    1.000    188.882
          S4 15   2e+05  strong           1666    1.000    177.455
          S4  5   2e+05  random           1881    1.000    176.823
          S4  5   2e+05  strong          13333    1.000    175.795
          S4 40   2e+05  random             19    0.999    174.431
          S4  3   2e+05  strong          33333    1.000    174.108
          S4  2   2e+05  strong          66666    1.000    172.911
          S3 15   2e+05  strong           1666    1.000    172.402
 mean_context_drift mean_tpg mean_css objective
            239.086    0.028    0.056   253.206
            120.603    0.125    0.960   236.274
            228.539    0.123    0.006   229.969
            189.090    0.039    0.022   193.153
            140.853    0.039    0.341   188.882
            129.717    0.041    0.368   177.455
            120.423    0.051    0.468   176.823
            119.010    0.050    0.477   175.795
            130.000    0.032    0.342   174.432
            107.171    0.063    0.625   174.108
             90.810    0.088    0.904   172.911
            170.366    0.040    0.012   172.402
```

Top settings by lowest SSR:
```text
 scenario_id  G total_n  pattern min_group_size mean_ssr mean_drift
          S4 15     100   random              5    0.738     19.249
          S3 15     100   strong              5    0.738     17.651
          S2 15     100   random              5    0.743     20.132
          S3 40     300   random              5    0.752     34.683
          S1 15     100 balanced              6    0.754     15.210
          S3 15     100     mild              5    0.761     16.182
          S1 15     100   random              5    0.764     19.904
          S3 15     100   random              5    0.764     17.476
          S2 15     100 balanced              6    0.767     15.159
          S1 15     100   strong              5    0.767     19.957
          S2 15     100     mild              5    0.771     16.870
          S1 40     300   random              5    0.772     42.172
 mean_context_drift mean_tpg mean_css objective
             12.340    0.321    0.557    19.511
             11.943    0.306    0.473    17.913
             12.895    0.284    0.549    20.390
             24.052    0.306    0.443    34.931
             10.619    0.259    0.445    15.456
             11.151    0.300    0.462    16.421
             13.489    0.285    0.468    20.140
             12.099    0.319    0.442    17.712
              9.904    0.264    0.541    15.392
             13.692    0.289    0.458    20.190
             10.845    0.279    0.556    17.099
             29.328    0.285    0.441    42.400
```

Extreme-setting observations:
- The worst retained settings concentrate in Scenario 4 and, to a lesser extent, Scenario 3. They typically combine many groups, small minimum subgroup sizes, and either strong or random imbalance.
- Scenario 2 rarely appears among the worst SSR settings, which reinforces the point that covariate shift alone mostly changes magnitude and transportability, not coefficient sign.
- When Scenario 4 becomes extreme, raw drift and TPG rise together. That is the practical failure mode of pooled regression in this study: not just coefficient movement, but degraded cross-group prediction transfer.

## Bottom line

- Scenario 1 is the finite-sample baseline: instability exists even with no true heterogeneity, especially when many small groups are estimated separately.
- Scenario 2 is mostly mechanical: it produces very large covariate shift and noticeable raw-drift inflation, but little sign instability.
- Scenario 3 is mostly genuine: it substantially increases coefficient drift and prediction transfer gaps, with lower CSS than Scenario 2.
- Scenario 4 is the joint stress test: it has the largest raw drift and transport gap, plus the weakest sign stability. Scenario 3 retains the largest context-normalized drift because it has less covariate-shift inflation to remove.
- For paper-level comparisons, medians on the nondegenerate unified grid are the most defensible summary. Means remain useful for showing how badly the sparse-corner cases can explode, but they should not be the headline comparison across scenarios.
