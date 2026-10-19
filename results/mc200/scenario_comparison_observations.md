# Scenario Comparison Observations

Generated on 2026-10-17 00:13:00.

This note compares the four simulation scenarios using the saved grid outputs in `results/`. The main comparison uses only settings with `min_group_size >= 3`, because very sparse subgroup corners create unstable outliers that distort mean-based summaries.

## Coverage and comparability

```text
 scenario settings degenerate_settings reps_min reps_max
       S1      136                   0      200      200
       S2      136                   0      200      200
       S3      136                   0      200      200
       S4      136                   0      200      200
```

Observations:
- All four scenarios retain 136/140 (S1), 136/140 (S2), 136/140 (S3), and 136/140 (S4) settings after the `min_group_size >= 3` filter.
- All scenarios use the same 140-setting design: `G` values 2, 3, 5, 15, 40; `total_n` values 100, 300, 1200, 3000, 6000, 30000, 2e+05; and all four imbalance patterns.
- Every completed setting uses 200 replications, so Monte Carlo means and interval widths are directly comparable across scenarios.
- Degenerate sparse-corner settings are concentrated where `G` is large and `total_n` is small; keeping them out is important for fair cross-scenario comparisons.

## Unified-grid comparison

```text
 scenario median_ssr mean_ssr share_ssr_below_1 median_drift mean_drift
       S1          1    0.980             0.331        3.644     11.461
       S2          1    0.979             0.309        3.781     11.755
       S3          1    0.976             0.375       24.640     46.444
       S4          1    0.976             0.360       25.414     48.144
 median_context median_tpg median_css median_shrink_pct
          3.114      0.004      0.057             5.405
          2.474      0.004      0.502            33.243
         21.744      0.064      0.059             5.491
         16.122      0.065      0.508            33.452
```

Unified-grid observations:
- This is the headline comparison because every scenario is evaluated on the same retained settings with the same replication budget.
- Scenario 4 has the lowest mean SSR and the highest median raw drift and pooled-versus-subgroup prediction gap. Scenario 3 has the largest share of retained settings with SSR below one.
- Scenario 3 has the highest median context-normalized drift. This is consistent with coefficient heterogeneity remaining after little adjustment for covariate separation, whereas normalization removes a larger mechanical component in Scenario 4.
- Scenario 2 still has the highest CSS and the largest shrinkage from raw to context-normalized drift, which is the expected signature of primarily mechanical instability.
- Scenario 3 remains the cleanest coefficient-heterogeneity benchmark: drift and TPG are much larger than Scenario 1, while CSS stays near the no-heterogeneity baseline.
- Scenario 1: no heterogeneity: median SSR = 1.000, median drift = 3.644, median context drift = 3.114, median TPG = 0.0043, median CSS = 0.057, median shrinkage = 5.4%, SSR < 1 in 33.1% of retained settings.
- Scenario 2: covariate shift only: median SSR = 1.000, median drift = 3.781, median context drift = 2.474, median TPG = 0.0044, median CSS = 0.502, median shrinkage = 33.2%, SSR < 1 in 30.9% of retained settings.
- Scenario 3: coefficient heterogeneity only: median SSR = 1.000, median drift = 24.640, median context drift = 21.744, median TPG = 0.0636, median CSS = 0.059, median shrinkage = 5.5%, SSR < 1 in 37.5% of retained settings.
- Scenario 4: combined heterogeneity: median SSR = 1.000, median drift = 25.414, median context drift = 16.122, median TPG = 0.0645, median CSS = 0.508, median shrinkage = 33.5%, SSR < 1 in 36.0% of retained settings.

## Relative to Scenario 1

```text
 scenario drift_vs_s1 context_vs_s1 tpg_vs_s1 css_vs_s1
       S1       1.000         1.000     1.000     1.000
       S2       1.038         0.794     1.003     8.767
       S3       6.761         6.983    14.665     1.023
       S4       6.974         5.177    14.869     8.864
```

Comparative observations:
- Scenario 2: covariate shift only relative to Scenario 1: drift 1.04x, context drift 0.79x, TPG 1.00x, CSS 8.77x.
- Scenario 3: coefficient heterogeneity only relative to Scenario 1: drift 6.76x, context drift 6.98x, TPG 14.66x, CSS 1.02x.
- Scenario 4: combined heterogeneity relative to Scenario 1: drift 6.97x, context drift 5.18x, TPG 14.87x, CSS 8.86x.
- Scenario 2 isolates mechanical instability: CSS jumps the most, but SSR remains at or extremely near 1 and TPG stays relatively small compared with Scenarios 3 and 4.
- Scenario 3 isolates genuine relationship instability: it raises drift, context drift, and TPG sharply with much lower CSS than Scenario 2.
- Scenario 4 combines both mechanisms: it has the largest raw drift and pooled-versus-subgroup prediction gap, while its context-normalized drift remains well above the Scenario 1 baseline.

## By number of groups

```text
 scenario  G median_ssr median_drift median_context median_tpg median_css
       S1  2      1.000        1.049          1.036      0.001      0.031
       S1  3      1.000        1.901          1.777      0.001      0.037
       S1  5      1.000        3.501          3.114      0.002      0.049
       S1 15      1.000       12.551         11.646      0.013      0.098
       S1 40      0.995       31.142         25.571      0.022      0.130
       S2  2      1.000        1.256          0.660      0.001      0.901
       S2  3      1.000        2.070          1.281      0.001      0.621
       S2  5      1.000        3.706          2.474      0.002      0.475
       S2 15      1.000       12.469          9.096      0.013      0.377
       S2 40      0.995       31.863         22.423      0.022      0.358
       S3  2      1.000       20.097         18.485      0.088      0.033
       S3  3      1.000       17.143         16.551      0.062      0.037
       S3  5      1.000       19.042         18.115      0.050      0.051
       S3 15      1.000       24.826         20.663      0.046      0.097
       S3 40      0.998       54.554         49.198      0.055      0.131
       S4  2      1.000       20.809         10.736      0.088      0.900
       S4  3      1.000       17.826         11.008      0.063      0.622
       S4  5      1.000       19.570         13.181      0.051      0.475
       S4 15      1.000       25.700         18.094      0.046      0.375
       S4 40      0.998       57.696         42.521      0.056      0.357
 median_shrink_pct
             3.070
             3.538
             4.672
             8.890
            11.476
            47.350
            38.227
            32.140
            27.324
            26.403
             3.078
             3.499
             4.841
             8.830
            11.525
            47.365
            38.206
            32.139
            27.285
            26.316
```

Observations by `G`:
- Median drift grows with `G` in every scenario. The `G=40` to `G=2` drift ratio is S1 29.69x; S2 25.36x; S3 2.71x; S4 2.77x.
- The proportional rise is largest in Scenarios 1 and 2 because their low-group baselines are small. In absolute terms, Scenarios 3 and 4 still have the largest drift at `G=40`, consistent with coefficient heterogeneity adding to finite-sample instability.
- Scenario 1 shows that even without true heterogeneity, splitting the sample into many groups creates nontrivial finite-sample drift. That is the baseline mechanical penalty of subgrouping.
- Scenario 2 amplifies that baseline mostly through CSS and moderate drift inflation, not through sign reversals.
- Scenarios 3 and 4 deteriorate more sharply as `G` rises, which is consistent with more subgroup-specific coefficients being estimated from smaller effective samples.
- The TPG increase from `G=2` to `G=40` is mild in Scenario 1, noticeable in Scenario 2, and materially larger in Scenarios 3 and 4.

## By imbalance pattern

```text
 scenario  pattern median_ssr median_drift median_context median_tpg median_css
       S1 balanced      1.000        3.095          2.880      0.002      0.051
       S1     mild      1.000        3.077          2.850      0.002      0.051
       S1   strong      1.000        3.922          3.740      0.004      0.059
       S1   random      1.000        6.827          6.269      0.007      0.087
       S2 balanced      1.000        3.231          2.198      0.002      0.490
       S2     mild      1.000        3.224          2.190      0.002      0.489
       S2   strong      1.000        4.029          2.727      0.004      0.509
       S2   random      1.000        6.901          4.351      0.006      0.511
       S3 balanced      1.000       21.039         18.145      0.054      0.052
       S3     mild      1.000       23.120         19.360      0.056      0.053
       S3   strong      1.000       28.792         28.101      0.068      0.059
       S3   random      0.999       27.391         26.289      0.093      0.085
       S4 balanced      1.000       22.211         14.237      0.056      0.495
       S4     mild      1.000       23.669         15.150      0.057      0.493
       S4   strong      1.000       30.049         19.164      0.069      0.509
       S4   random      1.000       28.330         18.458      0.093      0.517
 median_shrink_pct
             4.726
             4.794
             5.500
             7.860
            32.774
            32.606
            33.545
            33.727
             4.845
             4.980
             5.456
             7.761
            33.007
            32.783
            33.585
            33.802
```

Observations by pattern:
- The worst pattern by median drift is S1 -> random; S2 -> random; S3 -> strong; S4 -> strong.
- The lowest-SSR pattern within each scenario is S1 -> random; S2 -> random; S3 -> random; S4 -> random.
- Balanced and mild settings are usually the most stable. Strong and random imbalance tend to increase drift because they leave some groups with less information and more leverage-sensitive estimates.
- Random imbalance is especially informative because it often produces worse instability than mild imbalance without imposing a deterministic size ordering. That makes it a useful bridge between clean theoretical patterns and messier real subgroup structures.
- In Scenario 2, pattern effects are seen mostly through CSS and shrinkage. In Scenarios 3 and 4, pattern effects also spill into SSR and TPG because distribution imbalance interacts with coefficient differences.

## Most unstable retained settings

Top settings by objective/drift:
```text
 scenario_id  G total_n pattern min_group_size mean_ssr mean_drift
          S4 40   2e+05  random             12    0.999    199.804
          S4  3   2e+05  random          31751    1.000    197.123
          S4  5   2e+05  random           3320    1.000    196.946
          S3  5   2e+05  random           3320    1.000    189.452
          S3  3   2e+05  random          31751    1.000    189.404
          S4 40   2e+05  strong            243    1.000    188.496
          S3 40   2e+05  random             12    0.999    187.473
          S3 40   2e+05  strong            243    1.000    186.501
          S4  2   2e+05  random          57143    1.000    185.766
          S3  2   2e+05  random          57143    1.000    175.991
          S4 15   2e+05  strong           1666    1.000    175.164
          S4  5   2e+05  strong          13333    1.000    174.495
 mean_context_drift mean_tpg mean_css objective
            149.332    0.035    0.338   199.805
            121.481    0.073    0.623   197.123
            134.207    0.061    0.467   196.946
            187.565    0.060    0.010   189.452
            188.398    0.072    0.005   189.404
            140.576    0.039    0.341   188.496
            181.033    0.034    0.035   187.474
            182.614    0.038    0.021   186.501
             97.191    0.093    0.911   185.766
            175.299    0.093    0.004   175.991
            128.016    0.041    0.368   175.164
            118.117    0.050    0.477   174.495
```

Top settings by lowest SSR:
```text
 scenario_id  G total_n  pattern min_group_size mean_ssr mean_drift
          S2 15     100   random              5    0.735     20.564
          S3 15     100   random              5    0.735     18.826
          S4 15     100   random              5    0.745     21.055
          S1 15     100   random              5    0.748     20.622
          S3 40     300   random              5    0.752     48.877
          S3 15     100   strong              5    0.753     17.264
          S4 15     100   strong              5    0.756     18.346
          S4 40     300   random              5    0.761     52.271
          S4 15     100     mild              5    0.764     17.713
          S4 15     100 balanced              6    0.765     14.467
          S2 15     100   strong              5    0.767     18.100
          S2 15     100     mild              5    0.768     17.204
 mean_context_drift mean_tpg mean_css objective
             13.156    0.320    0.566    20.829
             12.769    0.344    0.478    19.091
             13.373    0.350    0.573    21.309
             13.988    0.319    0.472    20.874
             33.912    0.322    0.444    49.126
             11.973    0.322    0.447    17.511
             11.765    0.321    0.560    18.590
             34.036    0.317    0.538    52.509
             11.377    0.306    0.560    17.949
              9.381    0.289    0.543    14.703
             11.674    0.275    0.549    18.333
             11.110    0.278    0.549    17.436
```

Extreme-setting observations:
- The worst retained settings concentrate in Scenario 4 and, to a lesser extent, Scenario 3. They typically combine many groups, small minimum subgroup sizes, and either strong or random imbalance.
- Low-SSR settings occur in every scenario when group sizes are small. The scenario labels alone do not determine sign instability at this design boundary.
- When Scenario 4 becomes extreme, raw drift and TPG rise together. That is the practical failure mode of pooled regression in this study: not just coefficient movement, but degraded cross-group prediction transfer.

## Bottom line

- Scenario 1 is the finite-sample baseline: instability exists even with no true heterogeneity, especially when many small groups are estimated separately.
- Scenario 2 is mostly mechanical: it produces very large covariate shift and noticeable raw-drift inflation, but little sign instability.
- Scenario 3 is mostly genuine: it substantially increases coefficient drift and prediction transfer gaps, with lower CSS than Scenario 2.
- Scenario 4 is the joint stress test: it has the largest raw drift and pooled-versus-subgroup prediction gap. Scenario 3 retains the largest context-normalized drift because it has less covariate-shift inflation to remove.
- For paper-level comparisons, medians on the nondegenerate unified grid are the most defensible summary. Means remain useful for showing how badly the sparse-corner cases can explode, but they should not be the headline comparison across scenarios.
