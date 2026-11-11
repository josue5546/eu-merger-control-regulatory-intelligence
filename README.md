# EU Merger Control Analysis & M&A Diligence Strategy

**Business, Data Analytics & Strategy Consulting Portfolio Project**

**Tools:** MySQL | Python (Google Colab) | Power BI | ChatGPT (AI-Assisted)

## Project Overview

This project examines historical European Commission merger-control decisions using **10,376 merger cases** to understand regulatory review patterns, sector differences and potential implications for mergers and acquisitions (M&A).

The aim was to identify factors associated with longer regulatory reviews and conditional clearances, and to recommend practical steps that businesses can take when preparing for an acquisition in the European Union.

The project combines SQL analysis, statistical hypothesis testing, logistic regression, Power BI dashboards and strategic business recommendations.

Rather than predicting whether an acquisition will be approved, the analysis focuses on how historical evidence can support better regulatory due diligence and transaction planning.

## Key Findings

- **3.09%** of eligible merger cases entered Phase II, representing 309 of 9,993 cases.
- Phase I cases had a median observed review interval of **31 calendar days**, compared with **173 days** for Phase II cases.
- A Mann–Whitney U test confirmed a statistically significant difference in the historical review-duration distributions (p ≈ 2.321 × 10⁻¹⁵³).
- **5.05%** of eligible cleared cases received conditional clearance, representing 489 of 9,678 cases.
- Sector analysis identified differences in conditional-clearance rates across economic activities, with 51 sector codes meeting the minimum 50-case comparison threshold.

An adjusted logistic regression model covering 9,390 cases identified positive associations between conditional clearance and two sector indicators:

- **Chemicals:** Adjusted odds ratio of 2.79 (95% CI: 1.74–4.46).
- **Pharmaceuticals:** Adjusted odds ratio of 8.16 (95% CI: 4.86–13.69).

Both associations remained statistically significant after Holm multiple-testing correction.

These findings describe historical statistical associations. They do not establish causation or predict the regulatory outcome of a specific acquisition.

## Business Recommendation

The analysis supports prioritising regulatory due diligence before making significant transaction commitments.

Three practical workstreams are recommended:

**1. Establish regulatory filing exposure**

Identify the acquiring and target companies, ownership arrangements, relevant jurisdictions and potential merger notification requirements. Any filing obligations should be verified by qualified competition counsel.

**2. Assess competition concerns**

Investigate product and geographic market overlaps, market positions, relevant European Commission precedents and potential remedies.

**3. Prepare transaction contingencies**

Develop regulatory review scenarios, assess possible closing delays and establish management decision points before proceeding with the acquisition.

To support prioritisation, the project also introduces a **Decision-Changing Evidence Score (DCES)**:

**DCES = (Decision Impact × Uncertainty Reduced × Actionability) ÷ Effort**

The framework provides a structured way to rank proposed investigations according to their potential value for management decisions.

A proposed 90-day regulatory diligence roadmap translates these priorities into workstreams, responsibilities, expected deliverables and decision gates.

No client intervention has been implemented, and no transaction-specific legal conclusion or realised commercial benefit is claimed.

## Technical Approach

**MySQL:** Supported case-level validation, regulatory outcome classification, eligibility checks, decision-event analysis and historical case comparisons.

**Python:** Conducted statistical hypothesis testing, including Mann–Whitney U testing, bootstrap confidence intervals, sector comparisons and adjusted logistic regression.

The analysis examined three main hypotheses:

- **H1:** Differences in observed review-duration distributions between Phase I and Phase II cases.
- **H2:** Associations between sector classification and conditional-clearance outcomes.
- **H3:** Differences in Phase II initiation rates across historical periods.

**Power BI:** Developed a four-page dashboard covering the historical merger landscape, regulatory review pathways, sector intelligence and proposed M&A diligence strategy.

**Consulting analysis:** Combined statistical evidence with a practical decision framework, DCES prioritisation and a proposed regulatory diligence roadmap.

## AI Usage & Transparency

I used **ChatGPT** to support this project.

AI assisted with developing and troubleshooting code, understanding statistical methods, structuring the analytical approach, interpreting results and preparing the consulting report and management presentation.

My role involved working through the analysis in MySQL, Python and Power BI, reviewing analytical outputs and checking key calculations.
ChatGPT was used as both a learning and productivity tool to support a structured, evidence-based analytical workflow.

## Project Deliverables

Explore the completed analysis and supporting documents:

| **Deliverable** | **Description** |
|---|---|
| [Consulting Reports](./reports/) | Full English consulting report, editable Word version and French executive summary covering the findings, methodology and proposed regulatory diligence strategy. |
| [Management Presentation](./presentation/) | Executive PowerPoint presentation highlighting regulatory evidence, statistical findings, DCES priorities, the proposed roadmap and conclusions. |
| [Power BI Dashboard](./powerbi/) | Four-page regulatory intelligence dashboard covering historical merger outcomes, review pathways, sector comparisons and management recommendations. |
| [SQL Analysis](./sql/) | MySQL queries supporting case-level validation, regulatory outcome analysis, eligibility checks and historical comparisons. |
| [Python Analysis](./python/) | Google Colab statistical analysis covering hypothesis testing, review-duration comparisons, logistic regression and interpretation of results. |

## Data Source

**European Commission — Directorate-General for Competition (DG COMP)**

**Dataset:** EU Competition: Merger Case Publications

**[Access and download the original dataset — European Data Portal](https://data.europa.eu/data/datasets/cc7e224e-6569-40f0-8037-d3389aa0fae7?locale=en)**

The dataset contains publicly available merger-control case records published by the European Commission, including case information, notification dates, regulatory decisions and economic activity classifications.

It is distributed in machine-readable JSON format.

### Limitations

The analysis relies on historical published merger-control records rather than the full population of potential acquisitions.

Different metrics use different eligible case populations, and individual cases may belong to multiple sectors.

The 2026 reporting year is incomplete and should not be compared directly with completed years.

Observed review durations are calendar-day intervals, not statutory regulatory deadlines. Statistical associations do not establish causation, and the findings cannot determine the likelihood of clearance for an individual transaction.

---

*This project demonstrates how data analytics, statistical reasoning, AI-assisted workflows and practical consulting methods can help businesses make better-informed regulatory and M&A decisions.*
