USE vaccination_db;

-- ============================================================
-- Q1 (Medium 4): What percentage of the target population has
--                been covered by each vaccine?
-- ============================================================
SELECT 
    a.antigen_code,
    a.antigen_description,
    ROUND(AVG(c.coverage_pct), 2)  AS avg_coverage_pct,
    COUNT(*)                       AS records,
    COUNT(DISTINCT c.country_code) AS countries
FROM coverage c
JOIN antigens a ON c.antigen_code = a.antigen_code
WHERE c.coverage_pct IS NOT NULL
GROUP BY a.antigen_code, a.antigen_description
HAVING records > 100
ORDER BY avg_coverage_pct DESC;


-- ============================================================
-- Q2 (Scenario 1): Identify regions/countries with LOW coverage
--                  for resource allocation
-- ============================================================
SELECT 
    co.who_region,
    co.country_name,
    ROUND(AVG(c.coverage_pct), 2) AS avg_coverage,
    ROUND(95 - AVG(c.coverage_pct), 2) AS gap_to_target
FROM coverage c
JOIN countries co ON c.country_code = co.country_code
WHERE c.coverage_pct IS NOT NULL
GROUP BY co.who_region, co.country_name
HAVING avg_coverage < 60
ORDER BY avg_coverage ASC;


-- ============================================================
-- Q3 (Easy 1/9): Correlation - coverage vs disease incidence
--                by coverage band
-- ============================================================
SELECT 
    CASE 
        WHEN t.avg_cov < 50 THEN '1. Below 50%'
        WHEN t.avg_cov < 60 THEN '2. 50-60%'
        WHEN t.avg_cov < 70 THEN '3. 60-70%'
        WHEN t.avg_cov < 80 THEN '4. 70-80%'
        WHEN t.avg_cov < 90 THEN '5. 80-90%'
        ELSE '6. 90-100%'
    END AS coverage_band,
    COUNT(*)                 AS country_years,
    ROUND(AVG(t.avg_inc), 2) AS mean_incidence,
    ROUND(AVG(t.avg_cov), 2) AS mean_coverage
FROM (
    SELECT c.country_code, c.year,
           AVG(c.coverage_pct) AS avg_cov,
           (SELECT AVG(i.incidence_rate) 
            FROM incidence_rate i 
            WHERE i.country_code = c.country_code AND i.year = c.year) AS avg_inc
    FROM coverage c
    WHERE c.coverage_pct IS NOT NULL
    GROUP BY c.country_code, c.year
) t
WHERE t.avg_inc IS NOT NULL
GROUP BY coverage_band
ORDER BY coverage_band;


-- ============================================================
-- Q4 (Medium 3): Which diseases show the biggest reduction?
--                (1980s average vs 2015-2023 average)
-- ============================================================
SELECT 
    d.disease_description,
    ROUND(AVG(CASE WHEN r.year BETWEEN 1980 AND 1989 THEN r.cases END), 0) AS avg_1980s,
    ROUND(AVG(CASE WHEN r.year BETWEEN 2015 AND 2023 THEN r.cases END), 0) AS avg_recent,
    ROUND(
        (AVG(CASE WHEN r.year BETWEEN 2015 AND 2023 THEN r.cases END) -
         AVG(CASE WHEN r.year BETWEEN 1980 AND 1989 THEN r.cases END))
        / NULLIF(AVG(CASE WHEN r.year BETWEEN 1980 AND 1989 THEN r.cases END), 0) * 100
    , 2) AS pct_change
FROM reported_cases r
JOIN diseases d ON r.disease_code = d.disease_code
GROUP BY d.disease_description
ORDER BY pct_change ASC;


-- ============================================================
-- Q5 (Medium 6): Disparities in vaccine introduction across
--                WHO regions
-- ============================================================
SELECT 
    co.who_region,
    COUNT(*)                                              AS total_records,
    SUM(CASE WHEN v.introduced = 'Yes' THEN 1 ELSE 0 END) AS introduced,
    ROUND(SUM(CASE WHEN v.introduced = 'Yes' THEN 1 ELSE 0 END) 
          / COUNT(*) * 100, 2)                            AS pct_introduced
FROM vaccine_introduction v
JOIN countries co ON v.country_code = co.country_code
WHERE v.year = 2023 AND co.who_region IS NOT NULL
GROUP BY co.who_region
ORDER BY pct_introduced DESC;


-- ============================================================
-- Q6 (Easy 10): Regions with HIGH incidence despite HIGH coverage
-- ============================================================
SELECT 
    co.who_region,
    ROUND(AVG(c.coverage_pct), 2)   AS avg_coverage,
    ROUND(AVG(i.incidence_rate), 2) AS avg_incidence
FROM countries co
JOIN coverage c       ON co.country_code = c.country_code
JOIN incidence_rate i ON co.country_code = i.country_code AND c.year = i.year
WHERE co.who_region IS NOT NULL
GROUP BY co.who_region
ORDER BY avg_incidence DESC;


-- ============================================================
-- Q7 (Easy 2): Dose drop-off between 1st and final dose
-- ============================================================
SELECT 
    'DTP (1 to 3)' AS vaccine_series,
    ROUND(AVG(CASE WHEN antigen_code = 'DTPCV1' THEN coverage_pct END), 2) AS dose1,
    ROUND(AVG(CASE WHEN antigen_code = 'DTPCV3' THEN coverage_pct END), 2) AS final_dose,
    ROUND(AVG(CASE WHEN antigen_code = 'DTPCV1' THEN coverage_pct END) -
          AVG(CASE WHEN antigen_code = 'DTPCV3' THEN coverage_pct END), 2) AS dropoff_pp
FROM coverage WHERE antigen_code IN ('DTPCV1','DTPCV3')
UNION ALL
SELECT 
    'PCV (1 to 3)',
    ROUND(AVG(CASE WHEN antigen_code = 'PCV1' THEN coverage_pct END), 2),
    ROUND(AVG(CASE WHEN antigen_code = 'PCV3' THEN coverage_pct END), 2),
    ROUND(AVG(CASE WHEN antigen_code = 'PCV1' THEN coverage_pct END) -
          AVG(CASE WHEN antigen_code = 'PCV3' THEN coverage_pct END), 2)
FROM coverage WHERE antigen_code IN ('PCV1','PCV3');


-- ============================================================
-- Q8 (Scenario 6): Global progress towards 95% measles coverage
-- ============================================================
SELECT 
    c.year,
    ROUND(AVG(c.coverage_pct), 2)      AS mcv1_coverage,
    ROUND(95 - AVG(c.coverage_pct), 2) AS gap_to_target,
    (SELECT SUM(r.cases) 
     FROM reported_cases r 
     WHERE r.disease_code = 'MEASLES' AND r.year = c.year) AS measles_cases
FROM coverage c
WHERE c.antigen_code = 'MCV1' AND c.coverage_pct IS NOT NULL
GROUP BY c.year
ORDER BY c.year DESC
LIMIT 15;


-- ============================================================
-- Q9 (Medium 9): Coverage gaps for high-priority diseases
--                (TB / Hepatitis B / Polio)
-- ============================================================
SELECT 
    co.who_region,
    ROUND(AVG(CASE WHEN c.antigen_code = 'BCG'   THEN c.coverage_pct END), 2) AS tb_bcg,
    ROUND(AVG(CASE WHEN c.antigen_code = 'HEPB3' THEN c.coverage_pct END), 2) AS hepb3,
    ROUND(AVG(CASE WHEN c.antigen_code = 'POL3'  THEN c.coverage_pct END), 2) AS polio3
FROM coverage c
JOIN countries co ON c.country_code = co.country_code
WHERE c.antigen_code IN ('BCG','HEPB3','POL3')
  AND co.who_region IS NOT NULL
GROUP BY co.who_region
ORDER BY tb_bcg DESC;


-- ============================================================
-- Q10 (Medium 10): Which diseases are most prevalent in which
--                  geographic regions?
-- ============================================================
SELECT 
    co.who_region,
    d.disease_description,
    SUM(r.cases) AS total_cases,
    RANK() OVER (PARTITION BY co.who_region ORDER BY SUM(r.cases) DESC) AS rank_in_region
FROM reported_cases r
JOIN countries co ON r.country_code = co.country_code
JOIN diseases  d  ON r.disease_code = d.disease_code
WHERE co.who_region IS NOT NULL
GROUP BY co.who_region, d.disease_description
ORDER BY co.who_region, total_cases DESC;
