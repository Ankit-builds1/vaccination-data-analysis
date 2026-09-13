# Vaccination Data Analysis and Visualization

Analysis of WHO global immunization data (1980–2023) covering vaccination coverage, disease incidence, and programme effectiveness across 214 countries and 13 vaccine-preventable diseases.

**Domain:** Public Health and Epidemiology
**Stack:** Python (pandas, matplotlib, seaborn) · MySQL · Power BI

---

## Project Structure

```
├── 01_Data/
│   ├── raw/                  5 WHO source datasets (.xlsx, not tracked)
│   └── cleaned/              Cleaned CSVs (not tracked - regenerate via notebook)
├── 02_Python_EDA/
│   ├── vaccination-project-labmentix.ipynb    EDA notebook (15 charts)
│   └── load_data.py                           CSV → MySQL loader
├── 03_SQL/
│   ├── 01_schema.sql                          Normalized schema (8 tables)
│   └── 02_analysis_queries.sql                10 analysis queries
├── 04_PowerBI/
│   └── VaccinationProjectLabmentix.pbix       2-page interactive dashboard
└── 05_Documentation/
```

---

## Data Sources

Five datasets from the WHO Immunization Data portal:

| File | Rows | Contents |
|---|---|---|
| coverage-data | ~400K | Coverage % by country / year / antigen |
| reported-cases-data | ~85K | Disease case counts |
| incidence-rate-data | ~85K | Population-normalized disease rates |
| vaccine-introduction-data | ~138K | Whether a vaccine is in the national programme |
| vaccine-schedule-data | ~8K | Recommended dosing schedules |

All join on `country_code` + `year`.

---

## Database Schema

Star schema, third normal form:

**Dimensions:** `countries` (214) · `diseases` (13) · `antigens` (68)
**Facts:** `coverage` (210,518) · `reported_cases` (62,655) · `incidence_rate` (58,909) · `vaccine_introduction` (138,320) · `vaccine_schedule` (8,052)

Total ~479K rows with primary and foreign key constraints enforced.

---

## Key Findings

**1. Vaccination measurably reduces disease.**
Mean incidence falls monotonically at every step up in coverage — from 499.5 below 50% coverage to 68.2 at 90–100%, an 86.4% reduction. For measles specifically, coverage and cases correlate at r = −0.93 (p = 2.1e−19).

**2. The 95% WHO target is essentially unmet.**
Only 3 of 214 countries reach it. Measles coverage peaked at 89.9% in 2012 and has fallen to 87.8%, leaving a 7.2 point gap that is widening rather than closing.

**3. Progress reversed after 2019.**
Global average coverage fell from a mid-2010s peak near 89% to 80.3% by 2023 — affecting all six WHO regions simultaneously. Measles cases in 2023 (626,857) are 85% above the 2016 low.

**4. Regional equity has improved dramatically.**
The gap between best and worst performing region narrowed from 53.1 points in 1980 to 5.8 in 2023 — an 89% reduction. AFRO remains lowest at 69.9%.

**5. Roughly 1 in 10 children never complete a multi-dose series.**
DTP loses 9.4 points between dose 1 and dose 3. These children are already reached once by the health system, making retention a cheaper problem to solve than first-contact access.

**6. WPRO is an anomaly worth investigating.**
Second-highest mean incidence (184.0) despite above-average coverage (80.4%), suggesting regional averages are masking under-vaccinated pockets.

---

## Setup

```bash
pip install pandas numpy matplotlib seaborn scipy sqlalchemy pymysql
```

1. Download the five source datasets from the WHO Immunization Data portal into `01_Data/raw/`
2. Run the notebook in `02_Python_EDA/` to clean the data and generate the CSVs
3. Execute `03_SQL/01_schema.sql` in MySQL Workbench
4. Set `PASSWORD` and `FOLDER` in `load_data.py`, then run it
5. Run `03_SQL/02_analysis_queries.sql` for the analysis queries
6. Open the `.pbix` file in Power BI Desktop

---

## Scope Limitations

Several questions in the project brief cannot be answered with these datasets, as the required fields are not collected by WHO: gender, education level, urban/rural classification, monthly seasonality, population density, socioeconomic status, and vaccination delivery method.

Rather than substituting unreliable proxies, these are documented as out of scope. This is itself a finding: WHO immunization data supports geographic and temporal analysis but not demographic or socioeconomic segmentation.

---

## Data Quality Notes

Cleaning removed 1,192 corrupt records, including coverage values above 100% (one country reported 32,000%) and negative dose counts (−220 million in one case). Aggregate rows — regional, global, and World Bank groupings — were mixed with country-level records in the source files and had to be filtered out to prevent double counting.

Two apparent trends are reporting artifacts rather than real changes: typhoid's sharp post-2016 rise reflects surveillance expansion, and the 2020 dip in measles cases reflects pandemic disruption to case reporting rather than genuine disease reduction.
