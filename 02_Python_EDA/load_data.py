"""
Load cleaned vaccination CSVs into the normalized MySQL database.

Prerequisites:
    1. Run 03_SQL/01_schema.sql in MySQL Workbench first
    2. pip install pandas sqlalchemy pymysql
    3. Set PASSWORD and FOLDER below
"""

import pandas as pd
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus

# ============ CONFIG ============
PASSWORD = "YOUR_MYSQL_PASSWORD"        # never commit a real password
FOLDER = r"PATH_TO_CLEANED_CSV_FOLDER"
# ================================

# quote_plus handles special characters (@ # : /) that would otherwise break the URL
engine = create_engine(
    f"mysql+pymysql://root:{quote_plus(PASSWORD)}@localhost:3306/vaccination_db"
)

# ---------- Load CSVs ----------
cov = pd.read_csv(f"{FOLDER}/clean_coverage.csv")
cases = pd.read_csv(f"{FOLDER}/clean_cases.csv")
inc = pd.read_csv(f"{FOLDER}/clean_incidence.csv")
intro = pd.read_csv(f"{FOLDER}/clean_intro.csv")
sched = pd.read_csv(f"{FOLDER}/clean_schedule.csv")
print("CSVs loaded.")

# ---------- 1. COUNTRIES (dimension) ----------
c1 = cov[['COUNTRY_CODE', 'COUNTRY_NAME']]
c2 = cases[['COUNTRY_CODE', 'COUNTRY_NAME']]
c3 = inc[['COUNTRY_CODE', 'COUNTRY_NAME']]
c4 = intro[['COUNTRY_CODE', 'COUNTRY_NAME']]
c5 = sched[['COUNTRY_CODE', 'COUNTRY_NAME']]

countries = pd.concat([c1, c2, c3, c4, c5]).drop_duplicates('COUNTRY_CODE')
regions = intro[['COUNTRY_CODE', 'WHO_REGION']].drop_duplicates('COUNTRY_CODE')
countries = countries.merge(regions, on='COUNTRY_CODE', how='left')
countries.columns = ['country_code', 'country_name', 'who_region']
countries = countries.dropna(subset=['country_code'])
countries.to_sql('countries', engine, if_exists='append', index=False)
print(f"countries: {len(countries)} rows")

# ---------- 2. DISEASES (dimension) ----------
d1 = cases[['DISEASE', 'DISEASE_DESCRIPTION']]
d2 = inc[['DISEASE', 'DISEASE_DESCRIPTION']]
diseases = pd.concat([d1, d2]).drop_duplicates('DISEASE')
diseases.columns = ['disease_code', 'disease_description']
diseases.to_sql('diseases', engine, if_exists='append', index=False)
print(f"diseases: {len(diseases)} rows")

# ---------- 3. ANTIGENS (dimension) ----------
antigens = cov[['ANTIGEN', 'ANTIGEN_DESCRIPTION']].drop_duplicates('ANTIGEN')
antigens.columns = ['antigen_code', 'antigen_description']
antigens.to_sql('antigens', engine, if_exists='append', index=False)
print(f"antigens: {len(antigens)} rows")

# ---------- 4. COVERAGE (fact) ----------
coverage = cov[['COUNTRY_CODE', 'YEAR', 'ANTIGEN', 'COVERAGE_CATEGORY',
                'TARGET_NUMBER', 'DOSES', 'COVERAGE']].copy()
coverage.columns = ['country_code', 'year', 'antigen_code', 'coverage_category',
                    'target_number', 'doses', 'coverage_pct']

# Remove corrupt WHO entries: coverage cannot exceed ~100%, doses cannot be negative
before = len(coverage)
coverage = coverage[(coverage['coverage_pct'].isna()) | (coverage['coverage_pct'] <= 110)]
coverage = coverage[(coverage['doses'].isna()) | (coverage['doses'] >= 0)]
print(f"coverage: removed {before - len(coverage)} corrupt rows")

coverage.to_sql('coverage', engine, if_exists='append', index=False, chunksize=5000)
print(f"coverage: {len(coverage)} rows")

# ---------- 5. REPORTED CASES (fact) ----------
rc = cases[['COUNTRY_CODE', 'YEAR', 'DISEASE', 'CASES']].copy()
rc.columns = ['country_code', 'year', 'disease_code', 'cases']
rc.to_sql('reported_cases', engine, if_exists='append', index=False, chunksize=5000)
print(f"reported_cases: {len(rc)} rows")

# ---------- 6. INCIDENCE RATE (fact) ----------
ir = inc[['COUNTRY_CODE', 'YEAR', 'DISEASE', 'DENOMINATOR', 'INCIDENCE_RATE']].copy()
ir.columns = ['country_code', 'year', 'disease_code', 'denominator', 'incidence_rate']
ir.to_sql('incidence_rate', engine, if_exists='append', index=False, chunksize=5000)
print(f"incidence_rate: {len(ir)} rows")

# ---------- 7. VACCINE INTRODUCTION (fact) ----------
vi = intro[['COUNTRY_CODE', 'YEAR', 'DESCRIPTION', 'INTRO']].copy()
vi.columns = ['country_code', 'year', 'vaccine_description', 'introduced']
vi = vi[vi['country_code'].isin(countries['country_code'])]
vi.to_sql('vaccine_introduction', engine, if_exists='append', index=False, chunksize=5000)
print(f"vaccine_introduction: {len(vi)} rows")

# ---------- 8. VACCINE SCHEDULE (fact) ----------
vs = sched[['COUNTRY_CODE', 'YEAR', 'VACCINECODE', 'VACCINE_DESCRIPTION',
            'SCHEDULEROUNDS', 'TARGETPOP', 'TARGETPOP_DESCRIPTION',
            'GEOAREA', 'AGEADMINISTERED']].copy()
vs.columns = ['country_code', 'year', 'vaccine_code', 'vaccine_description',
              'schedule_rounds', 'target_pop', 'target_pop_description',
              'geo_area', 'age_administered']
vs = vs[vs['country_code'].isin(countries['country_code'])]
vs.to_sql('vaccine_schedule', engine, if_exists='append', index=False, chunksize=5000)
print(f"vaccine_schedule: {len(vs)} rows")

# ---------- VERIFY ----------
print("\n=== ROW COUNTS IN DATABASE ===")
with engine.connect() as conn:
    for t in ['countries', 'diseases', 'antigens', 'coverage',
              'reported_cases', 'incidence_rate',
              'vaccine_introduction', 'vaccine_schedule']:
        n = conn.execute(text(f"SELECT COUNT(*) FROM {t}")).scalar()
        print(f"{t:25s}: {n:>8,}")
