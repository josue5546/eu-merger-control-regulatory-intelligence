-- =====================================================
-- Stage 3 — SQL Analysis
-- Q01: Create EU Merger Analysis Database
-- =====================================================

CREATE DATABASE IF NOT EXISTS eu_merger_analysis;

USE eu_merger_analysis;

SELECT DATABASE() AS active_database;

-- =====================================================
-- Q02: Validate Core Merger Case Import
-- =====================================================

SELECT
    COUNT(*) AS total_cases,
    COUNT(DISTINCT case_id) AS unique_cases,
    SUM(outcome_kpi_eligible) AS outcome_eligible,
    SUM(timing_kpi_eligible) AS timing_eligible,
    SUM(phase_ii_initiated_recorded) AS phase_ii_cases
FROM eu_merger_analysis.cases_core;

-- =====================================================
-- Q15: Validate Date Formats Before Conversion
-- =====================================================

USE eu_merger_analysis;

SELECT 'notification_dt' AS column_name,
       SUM(notification_dt IS NOT NULL
           AND TRIM(notification_dt) <> ''
           AND notification_dt NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AS invalid_formats
FROM cases_core

UNION ALL
SELECT 'outcome_dt',
       SUM(outcome_dt IS NOT NULL AND TRIM(outcome_dt) <> ''
           AND outcome_dt NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
FROM cases_core

UNION ALL
SELECT 'latest_outcome_date',
       SUM(latest_outcome_date IS NOT NULL
           AND TRIM(latest_outcome_date) <> ''
           AND latest_outcome_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
FROM cases_core

UNION ALL
SELECT 'notification_date',
       SUM(notification_date IS NOT NULL
           AND TRIM(notification_date) <> ''
           AND notification_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
FROM cases_core

UNION ALL
SELECT 'last_recorded_decision_date',
       SUM(last_recorded_decision_date IS NOT NULL
           AND TRIM(last_recorded_decision_date) <> ''
           AND last_recorded_decision_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
FROM cases_core

UNION ALL
SELECT 'source_outcome_date',
       SUM(source_outcome_date IS NOT NULL
           AND TRIM(source_outcome_date) <> ''
           AND source_outcome_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
FROM cases_core

UNION ALL
SELECT 'analytical_outcome_date',
       SUM(analytical_outcome_date IS NOT NULL
           AND TRIM(analytical_outcome_date) <> ''
           AND analytical_outcome_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
FROM cases_core;

-- =====================================================
-- Q16: Standardise Missing Values and Convert Dates
-- =====================================================

USE eu_merger_analysis;

-- Allow the controlled update
SET @previous_safe_updates = @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

-- Convert empty strings into proper NULL values
UPDATE cases_core
SET
    notification_dt = NULLIF(TRIM(notification_dt), ''),
    outcome_dt = NULLIF(TRIM(outcome_dt), ''),
    latest_outcome_date = NULLIF(TRIM(latest_outcome_date), ''),
    notification_date = NULLIF(TRIM(notification_date), ''),
    last_recorded_decision_date =
        NULLIF(TRIM(last_recorded_decision_date), ''),
    source_outcome_date =
        NULLIF(TRIM(source_outcome_date), ''),
    analytical_outcome_date =
        NULLIF(TRIM(analytical_outcome_date), '');

-- Restore previous safe-update setting
SET SQL_SAFE_UPDATES = @previous_safe_updates;

-- Convert the seven columns
ALTER TABLE cases_core
    MODIFY COLUMN notification_dt DATE NULL,
    MODIFY COLUMN outcome_dt DATE NULL,
    MODIFY COLUMN latest_outcome_date DATE NULL,
    MODIFY COLUMN notification_date DATE NULL,
    MODIFY COLUMN last_recorded_decision_date DATE NULL,
    MODIFY COLUMN source_outcome_date DATE NULL,
    MODIFY COLUMN analytical_outcome_date DATE NULL;
    
    -- =====================================================
-- Q18: Validate Date Types and Case Count
-- =====================================================

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'eu_merger_analysis'
  AND TABLE_NAME = 'cases_core'
  AND DATA_TYPE = 'date'
ORDER BY ORDINAL_POSITION;

-- Verify no case records were lost
SELECT
    COUNT(*) AS total_cases,
    COUNT(DISTINCT case_id) AS unique_cases,
    SUM(notification_dt IS NULL) AS missing_notification,
    SUM(outcome_dt IS NULL) AS missing_outcome
FROM eu_merger_analysis.cases_core;

-- =====================================================
-- Q19: Create Regulatory Decisions Staging Table
-- =====================================================

USE eu_merger_analysis;

CREATE TABLE IF NOT EXISTS decisions_core_staging (

    case_id LONGTEXT NULL,
    decision_id LONGTEXT NULL,
    decision_number LONGTEXT NULL,
    decision_date LONGTEXT NULL,
    decision_type_codes LONGTEXT NULL,
    decision_type_labels LONGTEXT NULL,
    decision_type_count LONGTEXT NULL,
    regulation LONGTEXT NULL,
    decision_category LONGTEXT NULL,
    decision_date_analytical LONGTEXT NULL,
    date_correction_applied LONGTEXT NULL,
    subsequently_withdrawn_decision LONGTEXT NULL

) CHARACTER SET utf8mb4;

-- =====================================================
-- Q21: Validate Regulatory Decisions Import
-- =====================================================

SELECT
    COUNT(*) AS total_decisions,
    COUNT(DISTINCT case_id) AS cases_with_decisions,
    SUM(
        case_id IS NULL OR TRIM(case_id) = ''
    ) AS missing_case_ids,
    SUM(
        decision_id IS NULL OR TRIM(decision_id) = ''
    ) AS missing_decision_ids
FROM eu_merger_analysis.decisions_core_staging;

-- =====================================================
-- Q22: Validate Regulatory Decision Integrity
-- =====================================================

USE eu_merger_analysis;

-- Check duplicate decision identifiers
SELECT
    COUNT(*) AS duplicate_decision_groups
FROM (
    SELECT case_id, decision_id
    FROM decisions_core_staging
    GROUP BY case_id, decision_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- Check whether all decisions belong to a core merger case
SELECT
    COUNT(*) AS orphan_decisions
FROM decisions_core_staging AS d
LEFT JOIN cases_core AS c
    ON d.case_id = c.case_id
WHERE c.case_id IS NULL;

-- Check missing and incorrectly formatted dates
SELECT
    SUM(
        decision_date IS NULL
        OR TRIM(decision_date) = ''
    ) AS missing_decision_dates,

    SUM(
        decision_date IS NOT NULL
        AND TRIM(decision_date) <> ''
        AND decision_date NOT REGEXP
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    ) AS invalid_date_formats,

    SUM(
        decision_date_analytical IS NULL
        OR TRIM(decision_date_analytical) = ''
    ) AS missing_analytical_dates

FROM decisions_core_staging;

-- Inspect sample records for correct column alignment
SELECT
    case_id,
    decision_id,
    decision_date,
    decision_type_labels,
    decision_category,
    decision_date_analytical,
    date_correction_applied
FROM decisions_core_staging
LIMIT 5;

-- =====================================================
-- Q22B: Consolidated Regulatory Decision Validation
-- =====================================================

USE eu_merger_analysis;

SELECT
    (
        SELECT COUNT(*)
        FROM (
            SELECT case_id, decision_id
            FROM decisions_core_staging
            GROUP BY case_id, decision_id
            HAVING COUNT(*) > 1
        ) AS duplicates
    ) AS duplicate_decision_groups,

    (
        SELECT COUNT(*)
        FROM decisions_core_staging AS d
        LEFT JOIN cases_core AS c
            ON d.case_id = c.case_id
        WHERE c.case_id IS NULL
    ) AS orphan_decisions,

    SUM(
        decision_date IS NULL
        OR TRIM(decision_date) = ''
    ) AS missing_decision_dates,

    SUM(
        decision_date IS NOT NULL
        AND TRIM(decision_date) <> ''
        AND decision_date NOT REGEXP
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    ) AS invalid_date_formats,

    SUM(
        decision_date_analytical IS NULL
        OR TRIM(decision_date_analytical) = ''
    ) AS missing_analytical_dates

FROM decisions_core_staging;
-- =====================================================
-- Q23: Create Permanent Regulatory Decisions Table
-- =====================================================

USE eu_merger_analysis;

CREATE TABLE decisions_core (

    case_id VARCHAR(40) NOT NULL,
    decision_id VARCHAR(180) NOT NULL,
    decision_number TEXT NULL,

    decision_date DATE NOT NULL,

    decision_type_codes TEXT NULL,
    decision_type_labels TEXT NULL,
    decision_type_count INT NULL,

    regulation VARCHAR(150) NULL,
    decision_category VARCHAR(120) NULL,

    decision_date_analytical DATE NOT NULL,

    date_correction_applied TINYINT NULL,
    subsequently_withdrawn_decision TINYINT NULL,

    PRIMARY KEY (case_id, decision_id)

);

-- =====================================================
-- Q24: Transfer Regulatory Decisions to Permanent Table
-- =====================================================

INSERT INTO decisions_core (
    case_id,
    decision_id,
    decision_number,
    decision_date,
    decision_type_codes,
    decision_type_labels,
    decision_type_count,
    regulation,
    decision_category,
    decision_date_analytical,
    date_correction_applied,
    subsequently_withdrawn_decision
)

SELECT
    case_id,
    decision_id,
    NULLIF(TRIM(decision_number), ''),
    STR_TO_DATE(decision_date, '%Y-%m-%d'),
    NULLIF(TRIM(decision_type_codes), ''),
    NULLIF(TRIM(decision_type_labels), ''),
    CAST(NULLIF(TRIM(decision_type_count), '') AS UNSIGNED),
    NULLIF(TRIM(regulation), ''),
    NULLIF(TRIM(decision_category), ''),
    STR_TO_DATE(decision_date_analytical, '%Y-%m-%d'),
    CAST(NULLIF(TRIM(date_correction_applied), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(subsequently_withdrawn_decision), '') AS UNSIGNED)

FROM decisions_core_staging;

-- =====================================================
-- Q25: Validate Permanent Regulatory Decisions Table
-- =====================================================

SELECT
    COUNT(*) AS total_decisions,

    COUNT(DISTINCT case_id) AS unique_cases,

    COUNT(DISTINCT decision_id) AS unique_decisions,

    SUM(decision_date IS NULL) AS missing_dates,

    SUM(date_correction_applied) AS corrected_decisions,

    SUM(subsequently_withdrawn_decision)
        AS withdrawn_decision_flags

FROM decisions_core;



-- =====================================================
-- Q28: Validate Imported Sector Data - Sector_core
-- =====================================================

USE eu_merger_analysis;

SELECT
    COUNT(*) AS total_sector_records,
    COUNT(DISTINCT case_id) AS cases_with_sectors,
    COUNT(DISTINCT sector_code) AS unique_sector_codes,

    SUM(case_id IS NULL OR TRIM(case_id) = '')
        AS missing_case_ids,

    SUM(sector_code IS NULL OR TRIM(sector_code) = '')
        AS missing_sector_codes,

    SUM(sector_label IS NULL OR TRIM(sector_label) = '')
        AS missing_sector_labels

FROM sectors_core;


-- =====================================================
-- Q29: Check Duplicate Sector Associations
-- =====================================================

SELECT COUNT(*) AS duplicate_sector_groups
FROM (
    SELECT
        case_id,
        sector_code
    FROM sectors_core
    GROUP BY case_id, sector_code
    HAVING COUNT(*) > 1
) AS duplicates;


-- =====================================================
-- Q30: Check Orphan Sector Records
-- =====================================================

SELECT
    COUNT(*) AS orphan_sector_records
FROM sectors_core AS s
LEFT JOIN cases_core AS c
    ON s.case_id = c.case_id
WHERE c.case_id IS NULL;


-- =====================================================
-- Q31: Verify Imported Column Types
-- =====================================================

SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'eu_merger_analysis'
  AND TABLE_NAME = 'sectors_core'
ORDER BY ORDINAL_POSITION;


-- =====================================================
-- Q32: Final Sector Import Validation
-- =====================================================

USE eu_merger_analysis;

SELECT
    (SELECT COUNT(*) FROM sectors_core)
        AS total_records,

    (SELECT COUNT(DISTINCT case_id) FROM sectors_core)
        AS cases_with_sectors,

    (SELECT COUNT(DISTINCT sector_code) FROM sectors_core)
        AS unique_sector_codes,

    (SELECT COUNT(*) FROM (
        SELECT case_id, sector_code
        FROM sectors_core
        GROUP BY case_id, sector_code
        HAVING COUNT(*) > 1
    ) AS duplicates)
        AS duplicate_associations,

    (SELECT COUNT(*)
     FROM sectors_core AS s
     LEFT JOIN cases_core AS c
        ON s.case_id = c.case_id
     WHERE c.case_id IS NULL)
        AS orphan_records,

    (SELECT COUNT(*)
     FROM sectors_core
     WHERE case_id IS NULL OR TRIM(case_id) = ''
        OR sector_code IS NULL OR TRIM(sector_code) = ''
        OR sector_label IS NULL OR TRIM(sector_label) = '')
        AS records_with_missing_fields;
