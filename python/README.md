# Python — Statistical Analysis and Regulatory Evidence

This folder contains the Python analysis associated with the EU Merger Control and M&A Regulatory Intelligence case study.

The objective is to go beyond descriptive statistics and examine whether observed differences in review patterns and sector outcomes are supported by statistical evidence.

The analysis was developed using Google Colab.

## Main areas of analysis

### 1. Regulatory review durations

The analysis compares observed Phase I and Phase II review intervals.

A two-sided Mann–Whitney U test was used because review durations are skewed and the two groups have substantially different sample sizes.

Key validated results:

| Measure | Result |
|---|---:|
| Phase I sample | 9,471 cases |
| Phase II sample | 237 cases |
| Phase I median | 31 calendar days |
| Phase II median | 173 calendar days |
| Difference between medians | 142 days |
| Mann–Whitney U, Phase II first | 2,244,455 |
| p-value | Approximately 2.321 × 10⁻¹⁵³ |
| Bootstrap 95% CI for median difference | 138–151 days |

These findings show a substantial difference in the historical distributions. They do not prove that entering Phase II causes a particular delay.

### 2. Sector-level analysis

Sector comparisons examine differences in conditional-clearance outcomes across economic activities.

Descriptive sector rates are useful for identifying areas that may require further investigation, but overlapping sector memberships and differences in case characteristics limit direct comparisons.

### 3. Adjusted logistic regression

The adjusted model used 9,390 cases and included review-phase and historical-period controls.

| Sector indicator | Adjusted odds ratio | 95% confidence interval |
|---|---:|---|
| Chemicals | 2.7854 | 1.7386–4.4623 |
| Pharmaceuticals | 8.1585 | 4.8627–13.6880 |

Both displayed associations remained statistically significant after Holm multiple-testing correction.

These odds ratios describe conditional associations under the model. They are not clearance probabilities, causal effects or deal-specific risk scores.

### 4. Historical period comparisons

Exploratory analysis also considered whether Phase II initiation patterns varied across historical periods.

The period findings were not sufficiently robust to support a transaction-level prediction. They are therefore treated as historical context rather than a forecasting tool.

## Tools and libraries

The analytical workflow uses Python in Google Colab, with common data-analysis and statistical libraries such as:

- pandas and NumPy for data preparation.
- SciPy for statistical testing.
- statsmodels for regression and statistical inference.
- Matplotlib for analytical visualisations.

Refer to the individual notebooks for their exact imports, calculations and execution order.

## Interpretation

Statistical significance does not automatically mean a result is commercially important or causal.

The purpose of these tests is to strengthen the evidence behind regulatory diligence priorities while making the assumptions, limitations and uncertainty clear.

The findings should support further investigation, not replace legal or economic analysis of a proposed acquisition.
