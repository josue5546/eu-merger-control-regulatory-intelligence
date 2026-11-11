# Power BI — Regulatory Intelligence Dashboard

This folder contains the final Power BI dashboard developed for the EU Merger Control and M&A Regulatory Intelligence analysis.

The dashboard presents historical regulatory data in a format designed to support business interpretation and M&A due-diligence planning.

## Dashboard overview

### Page 1 — Executive Dossier

Provides a high-level view of merger activity, regulatory outcomes and data coverage.

Key findings include:

- 10,376 historical merger cases.
- 3.09% Phase II initiation rate among eligible cases.
- 95.28% regulatory evidence coverage.
- Historical merger notification trends.

### Page 2 — Regulatory Review Pathways

Examines recorded decision events, Phase II case histories and observed review durations.

The median observed interval was 31 calendar days for Phase I and 173 calendar days for Phase II in the defined timing-eligible populations.

These are historical calendar-day intervals, not statutory review deadlines.

### Page 3 — M&A Intelligence Terminal

Explores sector-level conditional-clearance patterns and adjusted statistical associations.

The dashboard includes 51 qualifying sector codes and adjusted odds ratios for chemicals and pharmaceuticals.

Sector memberships can overlap, and statistical associations should not be interpreted as predictions of an individual transaction's outcome.

### Page 4 — Regulatory Diligence & Deal Strategy

Translates analytical evidence into three proposed workstreams:

1. Screen filing exposure and jurisdictional requirements.
2. Assess competition concerns and relevant precedents.
3. Plan regulatory contingencies and management decision gates.

## Tools and methods

- Microsoft Power BI Desktop.
- DAX measures and eligibility filters.
- Relational modelling of cases, decisions and sector memberships.
- Statistical results prepared through Python.

## Important limitations

The dashboard is based on historical published merger-control information. Different measures use different eligible populations.

The 2026 reporting year is incomplete. Sector memberships overlap, and historical outcomes do not determine the likely regulatory result of a proposed acquisition.

The dashboard is intended to support regulatory intelligence and due-diligence planning, not to provide legal advice.
