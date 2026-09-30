SHOW VARIABLES LIKE 'local_infile';
Use government_procurement;
select database();
LOAD DATA LOCAL INFILE 'C:/Users/Avinash/Downloads/government_procurement_cleaned.csv'
INTO TABLE procurement_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    internal_id,
    portal_type,
    year,
    aoc_date,
    closing_date,
    title,
    tender_id,
    org_name,
    tender_type,
    contract_date,
    contract_value,
    organisation_name,
    number_of_bids,
    selected_bidder,
    completion_period
);

SELECT COUNT(*)
FROM procurement_data;

DESCRIBE procurement_data;

-- ============================================================
-- Question 1 — Tender Activity by Year
-- ============================================================

-- Business Question:
-- How many tenders were recorded in each year?

-- Why are we doing this?
-- We want to understand how tender activity has changed
-- over the years in the dataset.
--
-- This gives us a basic view of the procurement activity
-- before we move on to other analysis.

-- SQL Concepts Used:
-- COUNT(*)  → counts the number of tender records
-- GROUP BY  → groups the records by year
-- ORDER BY  → sorts the result by tender count


SELECT 
    year,
    COUNT(*) AS total_tender_count
FROM procurement_data
GROUP BY year
ORDER BY COUNT(*) DESC;


-- ============================================================
-- Interpretation
-- ============================================================

-- Tender activity generally increased over the years, although
-- there are some fluctuations between individual years.

-- 2025 has the highest number of tender records, with 615,047
-- tenders. 2023 is also very close, with 609,184 tenders.

-- Tender activity increased strongly from 2011 to 2015, followed
-- by some fluctuations between 2016 and 2022.

-- There was another large increase in tender activity in 2023,
-- reaching 609,184 tender records.

-- 2026 has only 103,315 records, but this data is incomplete,
-- so it should not be treated as a full-year comparison.


-- ============================================================
-- Question 2 — Tender Activity by Portal Type
-- ============================================================

-- Business Question:
-- How many tenders are recorded for each portal type?

SELECT 
    portal_type,
    COUNT(*) AS total_count
FROM procurement_data
GROUP BY portal_type;


-- ============================================================
-- Interpretation
-- ============================================================
-- ============================================================
-- Interpretation
-- ============================================================

-- The State portal has more tender records than the Central
-- portal in this dataset.

-- There are 2,916,702 tender records from the State portal,
-- compared with 2,005,258 records from the Central portal.

-- The State portal accounts for around 59.3% of the records,
-- while the Central portal accounts for around 40.7%.

-- This comparison is based only on the records available in
-- this dataset and does not mean that State governments
-- generally issue more tenders than the Central Government.

-- ============================================================
-- Question 3 — Highest and Lowest Tender Activity by Year
-- ============================================================

-- Business Question:
-- Which years had the highest and lowest number of tenders?

WITH yearly_tenders AS (
    SELECT
        year,
        COUNT(*) AS total_tenders
    FROM procurement_data
    GROUP BY year
)

SELECT
    year,
    total_tenders,
    'Highest Activity' AS benchmark
FROM yearly_tenders
WHERE total_tenders = (
    SELECT MAX(total_tenders)
    FROM yearly_tenders
)

UNION ALL

SELECT
    year,
    total_tenders,
    'Lowest Activity' AS benchmark
FROM yearly_tenders
WHERE total_tenders = (
    SELECT MIN(total_tenders)
    FROM yearly_tenders
);
-- ============================================================
-- Interpretation
-- ============================================================

-- 2025 had the highest tender activity, with 615,047
-- tender records.

-- 2011 had the lowest tender activity, with 2,808
-- tender records.

-- We used a CTE to first calculate the total tenders for
-- each year. Then MAX() and MIN() were used to identify
-- the highest and lowest yearly counts.

-- The benchmark column makes it clear whether each result
-- represents the highest or lowest activity.


-- ============================================================
-- Question 4 — Year-over-Year Tender Activity
-- ============================================================

-- Business Question:
-- How did tender activity change from one year to the next?

-- Why are we doing this?
-- We want to compare the number of tenders in each year
-- with the previous year.

-- SQL Concepts Used:
-- COUNT(*) → counts tenders for each year
-- GROUP BY → groups tenders by year
-- CTE → creates the yearly tender totals first
-- LAG() → gets the tender count from the previous year


WITH yearly_tenders AS (
    SELECT
        year,
        COUNT(*) AS total_tenders
    FROM procurement_data
    GROUP BY year
)

SELECT
    year,
    total_tenders,
    LAG(total_tenders) OVER (ORDER BY year) AS previous_year_tenders
FROM yearly_tenders
ORDER BY year;

-- ============================================================
-- Interpretation
-- ============================================================
-- The previous_year_tenders column shows the number of tenders
-- recorded in the previous year.

-- Tender activity increased from 2011 to 2015, going from
-- 2,808 tenders in 2011 to 278,672 tenders in 2015.

-- There were some fluctuations after 2015. For example,
-- tender activity decreased in 2016 compared with 2015 and
-- again in 2019 and 2020 compared with the previous year.

-- Tender activity increased strongly in 2023, reaching
-- 609,184 tenders compared with 415,741 in 2022.

-- Activity decreased in 2024 compared with 2023, but increased
-- again in 2025 to 615,047 tenders.

-- The 2026 count is much lower than 2025, but the 2026 data
-- is incomplete, so it should not be treated as a full-year
-- decline.

-- The first year, 2011, has no previous-year value because
-- there is no earlier year available in the dataset.


-- ============================================================
-- Question 5 — Standardized Tender Type Categories
-- ============================================================

-- Business Question:
-- What are the main categories represented in the tender_type
-- field?


WITH tender_counts AS (
    SELECT
        tender_type,
        COUNT(*) AS total_tenders
    FROM procurement_data
    GROUP BY tender_type
)

SELECT
    CASE
        WHEN tender_type IS NULL OR TRIM(tender_type) = ''
            THEN 'Not Recorded'

        WHEN tender_type IN ('works', 'goods', 'services', 'service')
            THEN 'Procurement Category Leak'

        WHEN tender_type IN ('1', '2', '5', '8', '0')
            THEN 'System Stage/ID Code'

        WHEN tender_type IN (
            'open',
            'open tender',
            'public',
            'ot',
            'open tender-srm',
            'national competitive bidding'
        )
            THEN 'Open Tender'

        WHEN tender_type IN (
            'limited',
            'limited tender-srm',
            'limited.',
            'lt',
            'lmtd'
        )
            THEN 'Limited Tender'

        WHEN tender_type IN (
            'single',
            'single tender-srm',
            'st',
            'ste(oem/oes)-srm',
            'nomination'
        )
            THEN 'Single/Direct Source'

        ELSE 'Other/Unclassified'
    END AS clean_tender_type,

SUM(total_tenders) AS total_tenders
FROM tender_counts
GROUP BY clean_tender_type
ORDER BY total_tenders DESC;

-- ============================================================
-- Interpretation
-- ============================================================

-- The largest group is Procurement Category Leak, with
-- 3,742,861 records.

-- This group mainly contains values such as works, goods and
-- services, which describe the procurement category rather than
-- the bidding method.

-- 527,162 records have no recorded tender type.

-- System Stage/ID Code is the next largest identified group,
-- with 314,761 records. This includes values such as 1, 2,
-- 5, 8 and 0.

-- Limited Tender and Open Tender have 155,238 and 151,433
-- records respectively.

-- The remaining records fall into Other/Unclassified and
-- Single/Direct Source categories.

-- This shows that the tender_type field contains different
-- kinds of information rather than one consistent category.

-- ============================================================
-- Question 6 — Organizations with the Highest Number of Tenders
-- ============================================================

CREATE INDEX idx_org_name
ON procurement_data(org_name(255));
SHOW INDEX FROM procurement_data;

SELECT
    org_name,
    COUNT(*) AS total_tenders
FROM procurement_data
WHERE org_name IS NOT NULL
GROUP BY org_name
ORDER BY total_tenders DESC
LIMIT 10;

-- ============================================================
-- Interpretation
-- ============================================================

-- West Bengal has the highest number of tender records, with
-- 785,197 tenders.

-- Maharashtra is next with 537,695 tenders, followed by
-- Kerala with 358,799 tenders.

-- Madhya Pradesh has 248,689 tender records, while BHEL EDN
-- has 173,569 records.

-- The remaining organizations in the top 10 are Haryana,
-- Uttar Pradesh, Tamil Nadu, Punjab and Odisha.

-- This result shows which organization names have the highest
-- number of tender records in the dataset.


-- ============================================================
-- Question 7 — Organizations with the Highest Total Contract Value
-- ============================================================

-- Business Question:
-- Which organizations have the highest total contract value?

SELECT
    COALESCE(
        NULLIF(TRIM(org_name), ''),
        'Unknown Organization'
    ) AS organization_name,
    SUM(contract_value) AS total_contract_value
FROM procurement_data
WHERE contract_value > 0
GROUP BY organization_name
ORDER BY total_contract_value DESC
LIMIT 10;

-- ============================================================
-- Interpretation
-- ============================================================

-- Madhya Pradesh has the highest total contract value, with
-- approximately ₹471.20 trillion.

-- Kerala is next with approximately ₹283.58 trillion,
-- followed by Maharashtra with approximately ₹197.93 trillion.

-- Punjab has a total contract value of approximately
-- ₹151.24 trillion, while Tamil Nadu and Haryana have
-- approximately ₹52.01 trillion and ₹41.81 trillion
-- respectively.

-- The result also includes specific organizations such as
-- Food Corporation of India and E-IN-C Branch - Military
-- Engineer Services among the top 10.

-- This result shows which organization names have the highest
-- total contract value among records where contract_value is
-- greater than zero.

-- ============================================================
-- Question 8 — Average Contract Value by Tender Type
-- ============================================================

-- Business Question:
-- What is the average contract value for each standardized
-- tender type category?


SELECT
    CASE
        WHEN tender_type IS NULL OR TRIM(tender_type) = ''
            THEN 'Not Recorded'

        WHEN tender_type IN (
            'works',
            'goods',
            'services',
            'service'
        )
            THEN 'Procurement Category Leak'

        WHEN tender_type IN (
            '1',
            '2',
            '5',
            '8',
            '0'
        )
            THEN 'System Stage/ID Code'

        WHEN tender_type IN (
            'open',
            'open tender',
            'public',
            'ot',
            'open tender-srm',
            'national competitive bidding'
        )
            THEN 'Open Tender'

        WHEN tender_type IN (
            'limited',
            'limited tender-srm',
            'limited.',
            'lt',
            'lmtd'
        )
            THEN 'Limited Tender'

        WHEN tender_type IN (
            'single',
            'single tender-srm',
            'st',
            'ste(oem/oes)-srm',
            'nomination'
        )
            THEN 'Single/Direct Source'

        ELSE 'Other/Unclassified'
    END AS clean_tender_type,

    ROUND(AVG(contract_value), 2) AS average_contract_value

FROM procurement_data
WHERE contract_value > 0
GROUP BY clean_tender_type
ORDER BY average_contract_value DESC;

-- ============================================================
-- Interpretation
-- ============================================================

-- Procurement Category Leak has the highest average contract
-- value at approximately ₹339.54 million.

-- Open Tender has the second-highest average contract value,
-- at approximately ₹86.40 million.

-- Other/Unclassified has an average contract value of
-- approximately ₹52.60 million, followed by Limited Tender
-- at approximately ₹26.87 million.

-- System Stage/ID Code, Not Recorded and Single/Direct Source
-- have lower average contract values of approximately
-- ₹4.00 million, ₹3.78 million and ₹2.47 million respectively.

-- This result shows that the average contract value differs
-- considerably across the standardized tender type categories.

-- ============================================================
-- Question 9 — Total Contract Value by Year
-- ============================================================

-- Business Question:
-- What is the total contract value for each year?


SELECT
    year,
    ROUND(SUM(contract_value), 2) AS total_contract_value
FROM procurement_data
WHERE contract_value > 0
GROUP BY year
ORDER BY year;

-- ============================================================
-- Interpretation
-- ============================================================

-- The total contract value varies significantly across the
-- years in the dataset.

-- 2021 has the highest total contract value, at approximately
-- ₹522.07 trillion.

-- 2022 is the next highest at approximately ₹293.34 trillion,
-- followed by 2019 at approximately ₹285.47 trillion.

-- From 2023 onwards, the total contract value is much lower
-- compared with the unusually high values recorded in 2019,
-- 2021 and 2022.

-- 2011 has the lowest total contract value among the completed
-- years, at approximately ₹46.22 billion.

-- 2026 has a much lower value because the year is incomplete
-- in the dataset, so it should not be directly compared with
-- the completed years.

-- This result shows how the total value of contracts recorded
-- in the dataset has changed across different years.

-- ============================================================
-- Question 10 — Contract Value Statistics by Year
-- ============================================================

-- Business Question:
-- What are the average, minimum and maximum contract values
-- for each year?


SELECT
    year,
    ROUND(AVG(contract_value), 2) AS average_contract_value,
    ROUND(MIN(contract_value), 2) AS minimum_contract_value,
    ROUND(MAX(contract_value), 2) AS maximum_contract_value
FROM procurement_data
WHERE contract_value > 0
GROUP BY year
ORDER BY year;

-- ============================================================
-- Interpretation
-- ============================================================

-- The average contract value varies significantly across the
-- years in the dataset.

-- 2021 has the highest average contract value, at approximately
-- ₹1.37 billion, followed by 2019 at approximately
-- ₹794.31 million and 2022 at approximately ₹725.28 million.

-- 2014 has an average contract value of approximately
-- ₹119.09 million, which is higher than most of the other
-- years between 2011 and 2018.

-- The minimum contract value is very small in most years,
-- reaching ₹0.01 in several years. This shows that the dataset
-- contains contracts with very small recorded values.

-- The maximum contract values are extremely high in some years.
-- For example, 2021 has a maximum of approximately
-- ₹170.00 trillion, while 2019 has a maximum of approximately
-- ₹150.00 trillion.

-- The large difference between the average and maximum values
-- in these years shows that a small number of very large
-- contract values are strongly affecting the yearly averages.

-- 2026 has a lower average and maximum value, but the year is
-- incomplete and should not be directly compared with completed
-- years.


-- ============================================================
-- Question 11 — Organizations with High Tender Count and
-- High Total Contract Value
-- ============================================================

-- Business Question:
-- Which organizations have both a high number of tenders and
-- a high total contract value?


SELECT
    org_name,
    COUNT(*) AS total_tenders,
    ROUND(SUM(contract_value), 2) AS total_contract_value
FROM procurement_data
WHERE contract_value > 0
GROUP BY org_name
ORDER BY total_tenders DESC
LIMIT 10;

-- ============================================================
-- Interpretation
-- ============================================================

-- Madhya Pradesh has the highest total contract value among
-- the top organizations by tender count, with approximately
-- ₹471.20 trillion across 242,326 tender records.

-- Kerala has 341,301 tender records with a total contract value
-- of approximately ₹283.58 trillion.

-- Maharashtra has 503,427 tender records and a total contract
-- value of approximately ₹197.93 trillion.

-- West Bengal has the highest tender count in this output,
-- with 768,395 records, but its total contract value is
-- approximately ₹27.94 trillion.

-- Punjab has 129,632 tender records but a much higher total
-- contract value of approximately ₹151.24 trillion.

-- This shows that a higher number of tenders does not
-- necessarily mean a higher total contract value. The size
-- of individual contracts also has a major effect on the
-- total contract value.

-- ============================================================
-- Question 12 — Contract Value Share by Portal
-- ============================================================

-- Business Question:
-- What percentage of the available contract value comes from
-- State and Central portals?


SELECT
    portal_type,
    ROUND(
        SUM(contract_value) * 100.0 /
        SUM(SUM(contract_value)) OVER (),
        2
    ) AS contract_value_percentage
FROM procurement_data
WHERE contract_value > 0
GROUP BY portal_type
ORDER BY contract_value_percentage DESC;

-- ============================================================
-- Interpretation
-- ============================================================

-- State portals account for 95.60% of the available contract
-- value in the dataset.

-- Central portals account for the remaining 4.40% of the
-- available contract value.

-- This shows that the available contract value in the dataset
-- is heavily concentrated in State portal records.

-- The calculation only includes records where contract_value
-- is greater than zero, so these percentages represent the
-- share of available positive contract value.

-- ============================================================
-- Question 13 — Average Number of Bids by Tender Type
-- ============================================================

-- Business Question:
-- What is the average number of bids received for each
-- standardized tender type category?


SELECT
    CASE
        WHEN tender_type IS NULL OR TRIM(tender_type) = ''
            THEN 'Not Recorded'

        WHEN tender_type IN (
            'works',
            'goods',
            'services',
            'service'
        )
            THEN 'Procurement Category Leak'

        WHEN tender_type IN (
            '1',
            '2',
            '5',
            '8',
            '0'
        )
            THEN 'System Stage/ID Code'

        WHEN tender_type IN (
            'open',
            'open tender',
            'public',
            'ot',
            'open tender-srm',
            'national competitive bidding'
        )
            THEN 'Open Tender'

        WHEN tender_type IN (
            'limited',
            'limited tender-srm',
            'limited.',
            'lt',
            'lmtd'
        )
            THEN 'Limited Tender'

        WHEN tender_type IN (
            'single',
            'single tender-srm',
            'st',
            'ste(oem/oes)-srm',
            'nomination'
        )
            THEN 'Single/Direct Source'

        ELSE 'Other/Unclassified'
    END AS clean_tender_type,

    ROUND(AVG(number_of_bids), 2) AS average_bids

FROM procurement_data
WHERE number_of_bids IS NOT NULL
GROUP BY clean_tender_type
ORDER BY average_bids DESC;

-- ============================================================
-- Interpretation
-- ============================================================

-- System Stage/ID Code has the highest average number of bids,
-- with an average of 19.39 bids per tender.

-- Open Tender has the second-highest average, with 4.09 bids,
-- followed by Procurement Category Leak with 3.85 bids.

-- Limited Tender has an average of 3.68 bids, while
-- Other/Unclassified has an average of 2.10 bids.

-- Single/Direct Source has a lower average of 0.93 bids, while
-- Not Recorded has the lowest average at 0.36 bids.

-- This result shows that the average number of bids varies
-- considerably across the standardized tender type categories.

-- ============================================================
-- Question 14 — Tender Distribution by Number of Bids
-- ============================================================

-- Business Question:
-- How are tenders distributed based on the number of bids
-- received?


SELECT
    CASE
        WHEN number_of_bids = 0
            THEN '0 Bids'

        WHEN number_of_bids BETWEEN 1 AND 3
            THEN '1-3 Bids'

        WHEN number_of_bids BETWEEN 4 AND 10
            THEN '4-10 Bids'

        WHEN number_of_bids > 10
            THEN 'More than 10 Bids'

        ELSE 'Not Recorded'
    END AS bid_category,

    COUNT(*) AS total_tenders

FROM procurement_data
GROUP BY bid_category
ORDER BY total_tenders DESC;

-- ============================================================
-- Interpretation
-- ============================================================

-- The largest group is tenders receiving 1-3 bids, with
-- 2,897,019 tender records.

-- Tenders receiving 4-10 bids account for 1,378,041 records.

-- 507,595 tenders have 0 recorded bids.

-- 139,305 tenders received more than 10 bids.

-- Overall, most tender records in the dataset fall within the
-- 1-3 bids category, while a much smaller number received more
-- than 10 bids.

-- ============================================================
-- Question 15 — Organizations with the Highest Average Number
-- of Bids
-- ============================================================

-- Business Question:
-- Which organizations have the highest average number of bids
-- received per tender?


SELECT
    org_name,
    ROUND(AVG(number_of_bids), 2) AS average_bids
FROM procurement_data
WHERE number_of_bids IS NOT NULL
GROUP BY org_name
ORDER BY average_bids DESC
LIMIT 10;

-- ============================================================
-- Interpretation
-- ============================================================

-- BHEL TRICHY has the highest average number of bids per tender,
-- with an average of 126.90 bids.

-- The Department of Revenue - Central Board of Excise and
-- Customs has an average of 60.00 bids per tender.

-- Coal India Limited - Internal Audit has an average of
-- 59.00 bids, followed by AOD Digboi - Indenter with
-- 56.00 bids.

-- The remaining organizations in the top 10 have average bids
-- ranging from 40.00 to 46.55.

-- This result shows that the average number of bids can vary
-- significantly across organizations, with some organizations
-- receiving much higher average participation per tender.

-- ============================================================
-- Question 16 — Tender Types with the Highest Average Number
-- of Bids
-- ============================================================

-- Business Question:
-- Which standardized tender types have the highest average
-- number of bids received?


SELECT
    CASE
        WHEN tender_type IS NULL OR TRIM(tender_type) = ''
            THEN 'Not Recorded'

        WHEN tender_type IN (
            'works',
            'goods',
            'services',
            'service'
        )
            THEN 'Procurement Category Leak'

        WHEN tender_type IN (
            '1',
            '2',
            '5',
            '8',
            '0'
        )
            THEN 'System Stage/ID Code'

        WHEN tender_type IN (
            'open',
            'open tender',
            'public',
            'ot',
            'open tender-srm',
            'national competitive bidding'
        )
            THEN 'Open Tender'

        WHEN tender_type IN (
            'limited',
            'limited tender-srm',
            'limited.',
            'lt',
            'lmtd'
        )
            THEN 'Limited Tender'

        WHEN tender_type IN (
            'single',
            'single tender-srm',
            'st',
            'ste(oem/oes)-srm',
            'nomination'
        )
            THEN 'Single/Direct Source'

        ELSE 'Other/Unclassified'
    END AS clean_tender_type,

    ROUND(AVG(number_of_bids), 2) AS average_bids

FROM procurement_data
WHERE number_of_bids IS NOT NULL
GROUP BY clean_tender_type
ORDER BY average_bids DESC;

-- ============================================================
-- Interpretation
-- ============================================================

-- System Stage/ID Code has the highest average number of bids,
-- with an average of 19.39 bids per tender.

-- Open Tender has the second-highest average, with 4.09 bids,
-- followed by Procurement Category Leak with 3.85 bids.

-- Limited Tender has an average of 3.68 bids, while
-- Other/Unclassified has an average of 2.10 bids.

-- Single/Direct Source has a lower average of 0.93 bids, while
-- Not Recorded has the lowest average at 0.36 bids.

-- This result shows that the average number of bids differs
-- across the standardized tender type categories.

-- ============================================================
-- Question 17 — State vs Central Tender Share by Year
-- ============================================================

-- Business Question:
-- What percentage of tenders came from State and Central
-- portals in each year?


SELECT year,
    ROUND(SUM(CASE
                WHEN portal_type = 'state' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS state_percentage,

    ROUND(
        SUM(
            CASE
                WHEN portal_type = 'central' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS central_percentage

FROM procurement_data
GROUP BY year
ORDER BY year;

-- ============================================================
-- Interpretation
-- ============================================================

-- From 2011 to 2015, the share of State and Central tenders
-- fluctuated, with Central accounting for a larger share in
-- most of these years.

-- In 2016 and 2017, all tender records in the dataset are from
-- the Central portal, with 100% Central and 0% State.

-- From 2019 onwards, the State portal accounts for a larger
-- share of tender records in each year.

-- The State share increased from 59.86% in 2019 to 81.93% in
-- 2023.

-- In 2024, the State share decreased to 77.28%, before increasing
-- again to 81.29% in 2025.

-- In 2026, the State share is 76.06%, but this year is incomplete
-- in the dataset.

-- Overall, the portal mix changes considerably across the years,
-- with State tenders making up a larger share in the more recent
-- years of the dataset.

-- ============================================================
-- Question 18 — Organization's Yearly Tender Count vs
-- Previous Year
-- ============================================================

WITH organization_yearly_metrics AS (
    SELECT
        org_name,
        year,
        COUNT(*) AS current_year_tenders
    FROM procurement_data
    WHERE org_name IS NOT NULL
    GROUP BY
        org_name,
        year
)

SELECT
    org_name,
    year,
    current_year_tenders,

    LAG(current_year_tenders) OVER (
        PARTITION BY org_name
        ORDER BY year
    ) AS previous_year_tenders,

    current_year_tenders
        - LAG(current_year_tenders) OVER (
            PARTITION BY org_name
            ORDER BY year
        ) AS absolute_change_volume

FROM organization_yearly_metrics

ORDER BY
    org_name,
    year DESC;

-- ============================================================
-- Interpretation
-- ============================================================

-- The result shows the number of tenders recorded for each
-- organization in each year, along with the previous year's
-- tender count and the absolute change.

-- A positive absolute_change_volume means the organization had
-- more tenders in the current year than in the previous year.
-- For example, AAI Cargo Logistics - Finance Department
-- increased from 1 tender in 2021 to 3 tenders in 2022,
-- resulting in a change of +2. :contentReference[oaicite:0]{index=0}

-- A negative absolute_change_volume means the number of tenders
-- decreased compared with the previous year. For example,
-- AAI Cargo Logistics - Operation Department decreased from
-- 7 tenders in 2023 to 3 tenders in 2025, with the output also
-- showing year-to-year changes in between. :contentReference[oaicite:1]{index=1}

-- A NULL previous_year_tenders means there is no earlier year
-- available for that organization in the dataset, so a
-- year-over-year change cannot be calculated.

-- The result also shows that tender activity can change
-- considerably from one year to another for the same
-- organization. For example, AWEIL - Gun and Shell Factory
-- increased from 9 tenders in 2023 to 24 in 2024, and then
-- decreased to 20 in 2025 and 1 in 2026. :contentReference[oaicite:2]{index=2}

-- This analysis helps track how tender activity changes over
-- time for each organization rather than looking only at the
-- total number of tenders.