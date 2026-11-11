-- =====================================================
-- PROJECT 5: EU M&A REGULATORY RISK & DEAL STRATEGY
-- SQL KPI ANALYSIS
-- =====================================================

USE eu_merger_analysis;

-- =====================================================
-- KPI 1 | Q01: Merger Case Volume by Notification Year
-- =====================================================

SELECT
    YEAR(notification_dt) AS notification_year,
    COUNT(DISTINCT case_id) AS total_merger_cases
FROM cases_core
WHERE notification_dt IS NOT NULL
GROUP BY YEAR(notification_dt)
ORDER BY notification_year;


-- =====================================================
-- KPI 1 | Q02: Regulatory Decision Activity by Year
-- =====================================================
-- Objective:
-- Measure historical EU merger decision activity
-- separately from merger case notification volume.
--
-- Counting rules:
-- 1. Each recorded decision event is counted once.
-- 2. A merger case may have multiple decisions.
-- 3. Use the validated analytical decision date.
-- 4. Results are descriptive, not clearance rates.
-- =====================================================

USE eu_merger_analysis;

SELECT
    YEAR(decision_date_analytical) AS decision_year,

    COUNT(*) AS total_decision_events,

    COUNT(DISTINCT case_id)
        AS distinct_cases_with_decisions

FROM decisions_core

WHERE decision_date_analytical IS NOT NULL

GROUP BY YEAR(decision_date_analytical)

ORDER BY decision_year ASC;


-- =====================================================
-- KPI 2 | Q03: Phase II Initiation Evidence and Coverage
-- =====================================================
-- Objective:
-- Establish the available notification and decision
-- evidence before calculating the historical Phase II
-- initiation rate.
--
-- Counting rules:
-- 1. Each merger case is counted once.
-- 2. Use the 10,376 validated core merger cases.
-- 3. Identify Phase II initiation using the validated
--    phase_ii_initiated_recorded flag.
-- 4. Report missing notification evidence explicitly.
-- 5. Do not interpret this audit as a final Phase II rate.
-- =====================================================

USE eu_merger_analysis;

SELECT
    COUNT(*) AS total_core_cases,

    SUM(notification_dt IS NOT NULL)
        AS cases_with_notification_date,

    SUM(
        notification_dt IS NOT NULL
        AND decision_count > 0
    ) AS notified_cases_with_decisions,

    SUM(phase_ii_initiated_recorded = 1)
        AS phase_ii_initiation_cases,

    SUM(
        phase_ii_initiated_recorded = 1
        AND notification_dt IS NOT NULL
    ) AS phase_ii_with_notification_date,

    SUM(
        phase_ii_initiated_recorded = 1
        AND notification_dt IS NULL
    ) AS phase_ii_missing_notification_date,

    SUM(
        notification_dt IS NOT NULL
        AND no_selected_outcome = 1
    ) AS notified_cases_without_selected_outcome

FROM cases_core;


-- =====================================================
-- KPI 2 | Q04: Phase II Denominator Eligibility Assessment
-- =====================================================
-- Objective:
-- Classify notified merger cases according to their
-- recorded regulatory decision evidence.
--
-- Counting rules:
-- 1. Count each distinct merger case once.
-- 2. Include only cases with a notification date.
-- 3. Separate cases without decision records.
-- 4. Distinguish procedural-only cases from cases
--    with recorded outcome-related decisions.
-- 5. Identify Phase II initiations in each group.
-- 6. Do not automatically treat referrals or
--    outside-scope cases as substantive reviews.
-- =====================================================

USE eu_merger_analysis;

SELECT
    CASE
        WHEN decision_count = 0
            THEN 'No recorded decisions'

        WHEN no_selected_outcome = 1
             AND phase_ii_initiated_recorded = 1
            THEN 'Phase II initiated - no selected outcome'

        WHEN no_selected_outcome = 1
            THEN COALESCE(
                no_outcome_reason,
                'Other procedural-only case'
            )

        WHEN latest_outcome_category =
             'Outside regulation scope'
            THEN 'Outside regulation scope'

        ELSE 'Outcome-related decision recorded'
    END AS evidence_group,

    COUNT(DISTINCT case_id) AS total_cases,

    COUNT(DISTINCT CASE
        WHEN phase_ii_initiated_recorded = 1
        THEN case_id
    END) AS phase_ii_cases

FROM cases_core

WHERE notification_dt IS NOT NULL

GROUP BY evidence_group

ORDER BY total_cases DESC;


-- =====================================================
-- KPI 2 | Q05: Historical Phase II Initiation Rate
-- =====================================================
-- Objective:
-- Calculate the proportion of eligible notified
-- merger cases with recorded Phase II initiation.
--
-- Eligibility rules:
-- 1. Count each distinct core merger case once.
-- 2. Require a recorded notification date.
-- 3. Include cases with outcome-related decisions.
-- 4. Include Phase II initiation cases without a
--    selected final outcome.
-- 5. Exclude referral-only cases, outside-scope
--    cases and cases without decision records.
-- 6. Treat this as an evidence-qualified historical
--    rate, not a transaction-specific risk estimate.
-- =====================================================

USE eu_merger_analysis;

WITH case_evidence AS (

    SELECT
        case_id,
        phase_ii_initiated_recorded,

        CASE
            WHEN decision_count = 0
                THEN 'No recorded decisions'

            WHEN no_selected_outcome = 1
                 AND phase_ii_initiated_recorded = 1
                THEN 'Phase II initiated - no selected outcome'

            WHEN no_selected_outcome = 1
                THEN COALESCE(
                    no_outcome_reason,
                    'Other procedural-only case'
                )

            WHEN latest_outcome_category =
                 'Outside regulation scope'
                THEN 'Outside regulation scope'

            ELSE 'Outcome-related decision recorded'
        END AS evidence_group

    FROM cases_core

    WHERE notification_dt IS NOT NULL
),

eligible_cases AS (

    SELECT
        case_id,
        phase_ii_initiated_recorded,
        evidence_group,

        CASE
            WHEN evidence_group IN (
                'Outcome-related decision recorded',
                'Phase II initiated - no selected outcome'
            )
            THEN 1
            ELSE 0
        END AS is_eligible

    FROM case_evidence
)

SELECT
    COUNT(*) AS notification_dated_cases,

    SUM(is_eligible) AS eligible_cases,

    SUM(
        CASE
            WHEN is_eligible = 1
                 AND phase_ii_initiated_recorded = 1
            THEN 1
            ELSE 0
        END
    ) AS phase_ii_cases,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN is_eligible = 1
                     AND phase_ii_initiated_recorded = 1
                THEN 1
                ELSE 0
            END
        ) / NULLIF(SUM(is_eligible), 0),
        2
    ) AS phase_ii_initiation_rate_pct,

    SUM(
        CASE WHEN is_eligible = 0 THEN 1 ELSE 0 END
    ) AS excluded_cases

FROM eligible_cases;


-- =====================================================
-- KPI 2 | Q06: Phase II Initiation Rate by Period and Regulation
-- =====================================================
-- Objective:
-- Compare historical Phase II initiation rates across
-- notification periods and EU merger-control regimes.
--
-- Counting rules:
-- 1. Count each eligible merger case once.
-- 2. Apply the same eligibility rules as KPI 2 Q05.
-- 3. Group cases by notification year, not decision year.
-- 4. Keep regulatory regimes separate.
-- 5. Exclude referral-only, outside-scope and cases
--    without decision records from the denominator.
-- 6. Retain Phase II initiation cases without a
--    selected final outcome.
-- 7. Treat 2026 as an incomplete calendar year.
-- 8. Results are descriptive, not causal estimates.
-- =====================================================

USE eu_merger_analysis;

WITH case_population AS (

    SELECT
        case_id,
        regulation,
        YEAR(notification_dt) AS notification_year,
        phase_ii_initiated_recorded,

        CASE
            WHEN decision_count = 0 THEN 0

            WHEN no_selected_outcome = 1
                 AND phase_ii_initiated_recorded = 1
                THEN 1

            WHEN no_selected_outcome = 1 THEN 0

            WHEN latest_outcome_category =
                 'Outside regulation scope'
                THEN 0

            ELSE 1
        END AS is_eligible

    FROM cases_core

    WHERE notification_dt IS NOT NULL
),

period_groups AS (

    SELECT
        *,
        CASE
            WHEN notification_year BETWEEN 1990 AND 1999
                THEN '1990-1999'

            WHEN notification_year BETWEEN 2000 AND 2003
                THEN '2000-2003'

            WHEN notification_year BETWEEN 2004 AND 2009
                THEN '2004-2009'

            WHEN notification_year BETWEEN 2010 AND 2019
                THEN '2010-2019'

            WHEN notification_year BETWEEN 2020 AND 2025
                THEN '2020-2025'

            WHEN notification_year = 2026
                THEN '2026 - Incomplete'

            ELSE 'Other period'
        END AS notification_period

    FROM case_population
)

SELECT
    notification_period,
    regulation,

    COUNT(*) AS notification_dated_cases,

    SUM(is_eligible) AS eligible_cases,

    SUM(
        CASE
            WHEN is_eligible = 1
                 AND phase_ii_initiated_recorded = 1
            THEN 1
            ELSE 0
        END
    ) AS phase_ii_cases,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN is_eligible = 1
                     AND phase_ii_initiated_recorded = 1
                THEN 1
                ELSE 0
            END
        ) / NULLIF(SUM(is_eligible), 0),
        2
    ) AS phase_ii_rate_pct,

    SUM(
        CASE
            WHEN is_eligible = 0 THEN 1
            ELSE 0
        END
    ) AS excluded_cases

FROM period_groups

GROUP BY
    notification_period,
    regulation

ORDER BY
    MIN(notification_year),
    regulation;


-- =====================================================
-- KPI 3 | Q07: Case-Level Regulatory Outcome Distribution
-- =====================================================
-- Objective:
-- Measure the distribution of regulatory outcomes
-- across strictly eligible core merger cases.
--
-- Counting rules:
-- 1. Count each eligible merger case once.
-- 2. Use the validated outcome_kpi_eligible flag.
-- 3. Use the prepared outcome_category_for_sql field.
-- 4. Exclude unresolved multiple-outcome histories.
-- 5. Exclude the subsequently withdrawn prohibition
--    in M.10188 from effective-outcome reporting.
-- 6. Retain withdrawals and outside-scope cases as
--    separate categories, not as clearances.
-- 7. Calculate percentages using the same eligible
--    case population for every outcome category.
-- 8. Results remain provisional pending legal review
--    of classifications and sensitivity analysis.
-- =====================================================

USE eu_merger_analysis;

SELECT
    outcome_category_for_sql
        AS regulatory_outcome,

    COUNT(DISTINCT case_id)
        AS eligible_cases,

    ROUND(
        100.0 * COUNT(DISTINCT case_id)
        / NULLIF(
            (
                SELECT COUNT(DISTINCT case_id)
                FROM cases_core
                WHERE outcome_kpi_eligible = 1
            ),
            0
        ),
        2
    ) AS share_of_eligible_cases_pct

FROM cases_core

WHERE outcome_kpi_eligible = 1

GROUP BY outcome_category_for_sql

ORDER BY eligible_cases DESC;


-- =====================================================
-- KPI 3 | Q08: Regulatory Decision-Event Distribution
-- =====================================================
-- Objective:
-- Examine the distribution of recorded regulatory
-- decision events across all core merger cases.
--
-- Counting rules:
-- 1. Include all 11,579 validated decision records.
-- 2. Count each decision event once.
-- 3. A merger case may have multiple decision events.
-- 4. Group events by validated decision_category.
-- 5. Report the number of distinct cases separately.
-- 6. Preserve procedural and historical decisions,
--    including subsequently withdrawn decisions.
-- 7. Do not interpret decision-event percentages
--    as final merger-case outcome rates.
-- =====================================================

USE eu_merger_analysis;

SELECT
    decision_category
        AS regulatory_decision_category,

    COUNT(*) AS total_decision_events,

    COUNT(DISTINCT case_id)
        AS distinct_cases,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            (SELECT COUNT(*) FROM decisions_core),
            0
        ),
        2
    ) AS share_of_decision_events_pct,

    SUM(
        subsequently_withdrawn_decision = 1
    ) AS subsequently_withdrawn_events

FROM decisions_core

GROUP BY decision_category

ORDER BY total_decision_events DESC;


-- =====================================================
-- KPI 4 | Q09: Median Observed Interval by Review Phase
-- =====================================================
-- Objective:
-- Calculate the median observed notification-to-decision
-- interval separately for Phase I and Phase II cases.
--
-- Counting rules:
-- 1. Include only timing_kpi_eligible = 1.
-- 2. Count each eligible merger case once.
-- 3. Use analytical_interval_days (calendar days).
-- 4. Apply the documented date correction for M.7046.
-- 5. Separate Phase I and Phase II decisions.
-- 6. Include eligible prohibitions in Phase II.
-- 7. Use the median to reduce sensitivity to extremes.
-- 8. Report the mean and maximum as diagnostics.
-- 9. These intervals are not statutory review periods.
-- =====================================================

USE eu_merger_analysis;

WITH eligible_cases AS (

    SELECT
        case_id,
        timing_phase,
        analytical_interval_days

    FROM cases_core

    WHERE timing_kpi_eligible = 1
      AND analytical_interval_days IS NOT NULL
      AND analytical_interval_days >= 0
      AND timing_phase IN ('Phase I', 'Phase II')
),

ranked_cases AS (

    SELECT
        case_id,
        timing_phase,
        analytical_interval_days,

        ROW_NUMBER() OVER (
            PARTITION BY timing_phase
            ORDER BY analytical_interval_days, case_id
        ) AS row_num,

        COUNT(*) OVER (
            PARTITION BY timing_phase
        ) AS group_size

    FROM eligible_cases
)

SELECT
    timing_phase,

    COUNT(*) AS eligible_cases,

    MIN(analytical_interval_days)
        AS minimum_days,

    ROUND(
        AVG(analytical_interval_days), 1
    ) AS mean_days,

    ROUND(
        AVG(
            CASE
                WHEN row_num IN (
                    FLOOR((group_size + 1) / 2),
                    FLOOR((group_size + 2) / 2)
                )
                THEN analytical_interval_days
            END
        ), 1
    ) AS median_days,

    MAX(analytical_interval_days)
        AS maximum_days,

    SUM(analytical_interval_days > 365)
        AS cases_over_365_days

FROM ranked_cases

GROUP BY timing_phase

ORDER BY timing_phase;


-- =====================================================
-- KPI 4 | Q10: Observed Intervals by Regulatory Outcome
-- =====================================================
-- Objective:
-- Compare notification-to-decision intervals across
-- Phase I clearances, Phase II clearances and prohibitions.
--
-- Counting rules:
-- 1. Include only timing_kpi_eligible = 1.
-- 2. Count each eligible merger case once.
-- 3. Use analytical_interval_days in calendar days.
-- 4. Group cases by outcome_category_for_sql.
-- 5. Separate unconditional and conditional clearances.
-- 6. Keep prohibitions as a distinct outcome category.
-- 7. Calculate medians using MySQL window functions.
-- 8. Report mean and maximum intervals as diagnostics.
-- 9. Preserve long intervals without automatic exclusion.
-- 10. Do not interpret these intervals as statutory
--     deadlines or evidence of causation.
-- =====================================================

USE eu_merger_analysis;

WITH eligible_cases AS (

    SELECT
        case_id,
        timing_phase,
        outcome_category_for_sql,
        analytical_interval_days

    FROM cases_core

    WHERE timing_kpi_eligible = 1
      AND analytical_interval_days IS NOT NULL
      AND analytical_interval_days >= 0
),

ranked_cases AS (

    SELECT
        case_id,
        timing_phase,
        outcome_category_for_sql,
        analytical_interval_days,

        ROW_NUMBER() OVER (
            PARTITION BY outcome_category_for_sql
            ORDER BY analytical_interval_days, case_id
        ) AS row_num,

        COUNT(*) OVER (
            PARTITION BY outcome_category_for_sql
        ) AS group_size

    FROM eligible_cases
)

SELECT
    timing_phase,

    outcome_category_for_sql AS regulatory_outcome,

    COUNT(*) AS eligible_cases,

    ROUND(
        AVG(analytical_interval_days), 1
    ) AS mean_days,

    ROUND(
        AVG(
            CASE
                WHEN row_num IN (
                    FLOOR((group_size + 1) / 2),
                    FLOOR((group_size + 2) / 2)
                )
                THEN analytical_interval_days
            END
        ), 1
    ) AS median_days,

    MIN(analytical_interval_days) AS minimum_days,

    MAX(analytical_interval_days) AS maximum_days,

    SUM(analytical_interval_days > 365)
        AS cases_over_365_days

FROM ranked_cases

GROUP BY
    timing_phase,
    outcome_category_for_sql

ORDER BY
    timing_phase,
    eligible_cases DESC;


-- =====================================================
-- KPI 5 | Q11: Regulatory Evidence Coverage Assessment
-- =====================================================
-- Objective:
-- Assess the completeness and analytical usability
-- of historical EU merger case records.
--
-- Counting rules:
-- 1. Include all 10,376 core merger cases.
-- 2. Count each case once.
-- 3. Assess notification, decision and sector coverage.
-- 4. Identify cases eligible for outcome analysis.
-- 5. Define complete analytical coverage as having
--    notification, decision and sector information,
--    plus an eligible provisional outcome category.
-- 6. Report timing eligibility separately.
-- 7. Missing or unresolved cases remain in the
--    denominator for transparent coverage reporting.
-- 8. Evidence coverage is not a measure of legal
--    due-diligence completion or decision accuracy.
-- =====================================================

USE eu_merger_analysis;

WITH evidence AS (

    SELECT
        case_id,

        CASE
            WHEN notification_dt IS NOT NULL THEN 1
            ELSE 0
        END AS notification_present,

        CASE
            WHEN decision_count > 0 THEN 1
            ELSE 0
        END AS decision_present,

        CASE
            WHEN sector_count > 0 THEN 1
            ELSE 0
        END AS sector_present,

        CASE
            WHEN outcome_kpi_eligible = 1 THEN 1
            ELSE 0
        END AS outcome_eligible,

        CASE
            WHEN timing_kpi_eligible = 1 THEN 1
            ELSE 0
        END AS timing_eligible

    FROM cases_core
),

coverage AS (

    SELECT
        *,

        CASE
            WHEN notification_present = 1
             AND decision_present = 1
             AND sector_present = 1
             AND outcome_eligible = 1
            THEN 1
            ELSE 0
        END AS complete_evidence

    FROM evidence
)

SELECT
    COUNT(*) AS total_core_cases,

    SUM(notification_present)
        AS cases_with_notification,

    SUM(decision_present)
        AS cases_with_decisions,

    SUM(sector_present)
        AS cases_with_sectors,

    SUM(outcome_eligible)
        AS outcome_eligible_cases,

    SUM(timing_eligible)
        AS timing_eligible_cases,

    SUM(complete_evidence)
        AS complete_evidence_cases,

    ROUND(
        100.0 * SUM(complete_evidence)
        / NULLIF(COUNT(*), 0),
        2
    ) AS evidence_coverage_rate_pct,

    COUNT(*) - SUM(complete_evidence)
        AS cases_not_meeting_all_criteria

FROM coverage;


-- =====================================================
-- KPI 5 | Q12: Regulatory Evidence Gap Breakdown
-- =====================================================
-- Objective:
-- Identify the combinations of evidence gaps affecting
-- cases that fail the complete analytical coverage test.
--
-- Counting rules:
-- 1. Examine all 10,376 validated core merger cases.
-- 2. Count each case once.
-- 3. Assess the same four criteria used in KPI 5 Q11.
-- 4. Identify missing notification dates, absent
--    decisions, missing sectors and outcome ineligibility.
-- 5. Preserve overlapping issues within each case.
-- 6. Group cases by their exact combination of gaps.
-- 7. Exclude complete cases from the breakdown.
-- 8. Gap groups must total 490 distinct cases.
-- 9. Results describe analytical evidence limitations,
--    not confirmed defects in Commission records.
-- =====================================================

USE eu_merger_analysis;

WITH evidence_flags AS (

    SELECT
        case_id,

        CASE
            WHEN notification_dt IS NULL
            THEN 'Missing notification date'
        END AS notification_issue,

        CASE
            WHEN COALESCE(decision_count, 0) = 0
            THEN 'No recorded decision'
        END AS decision_issue,

        CASE
            WHEN COALESCE(sector_count, 0) = 0
            THEN 'Missing sector evidence'
        END AS sector_issue,

        CASE
            WHEN COALESCE(outcome_kpi_eligible, 0) <> 1
            THEN 'Outcome KPI ineligible'
        END AS outcome_issue

    FROM cases_core
),

incomplete_cases AS (

    SELECT
        case_id,

        CONCAT_WS(
            ' + ',
            notification_issue,
            decision_issue,
            sector_issue,
            outcome_issue
        ) AS evidence_gap_pattern

    FROM evidence_flags

    WHERE notification_issue IS NOT NULL
       OR decision_issue IS NOT NULL
       OR sector_issue IS NOT NULL
       OR outcome_issue IS NOT NULL
)

SELECT
    evidence_gap_pattern,

    COUNT(*) AS affected_cases,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            (SELECT COUNT(*) FROM cases_core),
            0
        ),
        2
    ) AS share_of_all_core_cases_pct

FROM incomplete_cases

GROUP BY evidence_gap_pattern

ORDER BY affected_cases DESC;


-- =====================================================
-- KPI 6 | Q13: Conditional Clearance Rate by Review Phase
-- =====================================================
-- Objective:
-- Calculate the proportion of eligible cleared merger
-- cases that received conditional regulatory clearance.
--
-- Counting rules:
-- 1. Count each eligible merger case once.
-- 2. Require outcome_kpi_eligible = 1.
-- 3. Include only Phase I and Phase II clearances.
-- 4. Include unconditional and conditional clearances
--    in the denominator.
-- 5. Count conditional clearances in the numerator.
-- 6. Exclude withdrawals, prohibitions, outside-scope
--    cases and unresolved outcomes.
-- 7. Calculate separate Phase I and Phase II rates.
-- 8. Calculate the overall rate across cleared cases.
-- 9. Rates describe historical classifications, not
--    predicted remedies for a proposed transaction.
-- =====================================================

USE eu_merger_analysis;

WITH eligible_clearances AS (

    SELECT
        case_id,

        CASE
            WHEN outcome_category_for_sql IN (
                'Phase I - Unconditional clearance',
                'Phase I - Conditional clearance'
            ) THEN 'Phase I'

            WHEN outcome_category_for_sql IN (
                'Phase II - Unconditional clearance',
                'Phase II - Conditional clearance'
            ) THEN 'Phase II'
        END AS review_phase,

        CASE
            WHEN outcome_category_for_sql IN (
                'Phase I - Conditional clearance',
                'Phase II - Conditional clearance'
            ) THEN 1
            ELSE 0
        END AS is_conditional

    FROM cases_core

    WHERE outcome_kpi_eligible = 1
      AND outcome_category_for_sql IN (
          'Phase I - Unconditional clearance',
          'Phase I - Conditional clearance',
          'Phase II - Unconditional clearance',
          'Phase II - Conditional clearance'
      )
),

phase_summaries AS (

    SELECT
        review_phase,
        COUNT(*) AS eligible_cleared_cases,
        SUM(is_conditional) AS conditional_clearance_cases

    FROM eligible_clearances

    GROUP BY review_phase
),

combined_results AS (

    SELECT
        review_phase,
        eligible_cleared_cases,
        conditional_clearance_cases
    FROM phase_summaries

    UNION ALL

    SELECT
        'Overall',
        SUM(eligible_cleared_cases),
        SUM(conditional_clearance_cases)
    FROM phase_summaries
)

SELECT
    review_phase,
    eligible_cleared_cases,
    conditional_clearance_cases,

    ROUND(
        100.0 * conditional_clearance_cases
        / NULLIF(eligible_cleared_cases, 0),
        2
    ) AS conditional_clearance_rate_pct

FROM combined_results

ORDER BY
    CASE review_phase
        WHEN 'Phase I' THEN 1
        WHEN 'Phase II' THEN 2
        ELSE 3
    END;


-- =====================================================
-- KPI 6 | Q14: Conditional Clearance Rate by Sector
-- =====================================================
-- Objective:
-- Identify sectors with meaningful historical volumes
-- of cleared mergers and compare the proportion of
-- clearances that involved regulatory conditions.
--
-- Counting rules:
-- 1. Include only strictly outcome-eligible cases.
-- 2. Include Phase I and Phase II clearances only.
-- 3. Count each merger case once within each sector.
-- 4. Cases may belong to multiple sectors.
-- 5. Use sector_code as the grouping identifier.
-- 6. Require at least 50 cleared cases per sector
--    for this initial descriptive comparison.
-- 7. Display the 20 largest qualifying sectors
--    by eligible cleared-case volume.
-- 8. Report Phase II clearance counts as context.
-- 9. Sector rates are descriptive and do not prove
--    sector-specific regulatory causation.
-- =====================================================

USE eu_merger_analysis;

WITH eligible_clearances AS (

    SELECT
        case_id,
        outcome_category_for_sql,

        CASE
            WHEN outcome_category_for_sql IN (
                'Phase I - Conditional clearance',
                'Phase II - Conditional clearance'
            )
            THEN 1
            ELSE 0
        END AS is_conditional,

        CASE
            WHEN outcome_category_for_sql IN (
                'Phase II - Unconditional clearance',
                'Phase II - Conditional clearance'
            )
            THEN 1
            ELSE 0
        END AS is_phase_ii

    FROM cases_core

    WHERE outcome_kpi_eligible = 1
      AND outcome_category_for_sql IN (
          'Phase I - Unconditional clearance',
          'Phase I - Conditional clearance',
          'Phase II - Unconditional clearance',
          'Phase II - Conditional clearance'
      )
),

sector_analysis AS (

    SELECT
        s.sector_code,
        MAX(s.sector_label) AS sector_label,

        COUNT(DISTINCT c.case_id)
            AS eligible_cleared_cases,

        COUNT(DISTINCT CASE
            WHEN c.is_conditional = 1
            THEN c.case_id
        END) AS conditional_clearance_cases,

        COUNT(DISTINCT CASE
            WHEN c.is_phase_ii = 1
            THEN c.case_id
        END) AS phase_ii_cleared_cases

    FROM eligible_clearances c

    INNER JOIN sectors_core s
        ON c.case_id = s.case_id

    GROUP BY s.sector_code

    HAVING COUNT(DISTINCT c.case_id) >= 50
)

SELECT
    sector_code,
    sector_label,
    eligible_cleared_cases,
    conditional_clearance_cases,

    ROUND(
        100.0 * conditional_clearance_cases
        / NULLIF(eligible_cleared_cases, 0),
        2
    ) AS conditional_clearance_rate_pct,

    phase_ii_cleared_cases

FROM sector_analysis

ORDER BY
    eligible_cleared_cases DESC,
    sector_code ASC

LIMIT 20;


-- =====================================================
-- KPI 6 | Q15: Conditional Clearances by Sector and Phase
-- =====================================================
-- Objective:
-- Examine conditional-clearance patterns within
-- Phase I and Phase II for four selected sectors.
--
-- Counting rules:
-- 1. Include only strictly outcome-eligible cases.
-- 2. Include cleared merger cases only.
-- 3. Count each case once within each selected sector.
-- 4. Use the validated case-level outcome category.
-- 5. Calculate Phase I and Phase II rates separately.
-- 6. Preserve sectors with zero Phase II clearances.
-- 7. Do not interpret a zero denominator as a 0% rate.
-- 8. Selected sectors are not mutually exclusive.
-- 9. Results are exploratory, not statistical proof
--    of sector-specific regulatory differences.
-- =====================================================

USE eu_merger_analysis;

WITH selected_cases AS (

    SELECT DISTINCT
        s.sector_code,
        s.case_id,
        c.outcome_category_for_sql

    FROM sectors_core s

    INNER JOIN cases_core c
        ON s.case_id = c.case_id

    WHERE s.sector_code IN (
        'NaceSectorsC_21',
        'NaceSectorsC_20',
        'NaceSectorsJ_61',
        'NaceSectorsK_64'
    )

    AND c.outcome_kpi_eligible = 1

    AND c.outcome_category_for_sql IN (
        'Phase I - Unconditional clearance',
        'Phase I - Conditional clearance',
        'Phase II - Unconditional clearance',
        'Phase II - Conditional clearance'
    )
),

sector_counts AS (

    SELECT
        sector_code,

        COUNT(*) AS total_cleared_cases,

        SUM(
            outcome_category_for_sql IN (
                'Phase I - Unconditional clearance',
                'Phase I - Conditional clearance'
            )
        ) AS phase_i_cleared_cases,

        SUM(
            outcome_category_for_sql =
                'Phase I - Conditional clearance'
        ) AS phase_i_conditional_cases,

        SUM(
            outcome_category_for_sql IN (
                'Phase II - Unconditional clearance',
                'Phase II - Conditional clearance'
            )
        ) AS phase_ii_cleared_cases,

        SUM(
            outcome_category_for_sql =
                'Phase II - Conditional clearance'
        ) AS phase_ii_conditional_cases

    FROM selected_cases

    GROUP BY sector_code
)

SELECT
    sector_code,
    total_cleared_cases,

    phase_i_cleared_cases,
    phase_i_conditional_cases,

    ROUND(
        100.0 * phase_i_conditional_cases
        / NULLIF(phase_i_cleared_cases, 0),
        2
    ) AS phase_i_conditional_rate_pct,

    phase_ii_cleared_cases,
    phase_ii_conditional_cases,

    ROUND(
        100.0 * phase_ii_conditional_cases
        / NULLIF(phase_ii_cleared_cases, 0),
        2
    ) AS phase_ii_conditional_rate_pct

FROM sector_counts

ORDER BY total_cleared_cases DESC;

