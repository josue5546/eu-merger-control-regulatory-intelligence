# SQL — Merger Control Data Analysis

This folder contains SQL scripts associated with the preparation, validation and analysis of European Commission merger-control data.

The SQL work supports a consistent understanding of historical merger activity, regulatory outcomes and case-level eligibility.

## Analytical objectives

The analysis focuses on questions such as:

- How many distinct merger cases are represented?
- What regulatory outcomes were recorded?
- How often was Phase II initiated among eligible cases?
- How do review pathways and decision records differ?
- Which cases meet the eligibility criteria for each KPI?
- How can data quality and counting rules be checked before reporting?

## Data structure

The analytical model uses four main tables:

| Table | Purpose |
|---|---|
| `cases` | Case-level information, classifications and eligibility |
| `Decisions` | Recorded regulatory decision events |
| `sectors` | Economic sector associations for merger cases |
| `PhaseII_Pathways` | Reconstructed histories for cases entering Phase II |

A merger case may have multiple recorded decisions or sector associations. Therefore, event counts and sector memberships must not be treated as distinct case totals.

## Key validated benchmarks

| Metric | Result |
|---|---:|
| Distinct merger cases | 10,376 |
| Recorded decision events | 11,579 |
| Cases with recorded decisions | 10,337 |
| Cases with classifiable outcomes | 9,968 |
| Phase II initiation cases | 309 |
| Phase II rate-eligible cases | 9,993 |

These benchmarks provide useful reconciliation checks when reviewing SQL outputs.

## Tools

- MySQL Workbench.
- SQL for data validation, aggregation and analytical querying.
- Power BI for subsequent reporting.

## Important considerations

Different analyses use different eligible case populations.

When interpreting results, check whether the query counts distinct cases, decision events or sector memberships.

The SQL analysis supports historical regulatory intelligence and does not establish a legal conclusion for a particular acquisition.
