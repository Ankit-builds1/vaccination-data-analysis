-- ============================================
-- VACCINATION DATA ANALYSIS - DATABASE SCHEMA
-- Normalized design with primary & foreign keys
-- MySQL 8.0
-- ============================================

DROP DATABASE IF EXISTS vaccination_db;
CREATE DATABASE vaccination_db;
USE vaccination_db;

-- ---------- DIMENSION TABLES ----------

CREATE TABLE countries (
    country_code   CHAR(3)      PRIMARY KEY,
    country_name   VARCHAR(150) NOT NULL,
    who_region     VARCHAR(10)
);

CREATE TABLE diseases (
    disease_code        VARCHAR(50)  PRIMARY KEY,
    disease_description VARCHAR(200) NOT NULL
);

CREATE TABLE antigens (
    antigen_code        VARCHAR(50)  PRIMARY KEY,
    antigen_description VARCHAR(250) NOT NULL
);

-- ---------- FACT TABLES ----------

CREATE TABLE coverage (
    coverage_id       INT AUTO_INCREMENT PRIMARY KEY,
    country_code      CHAR(3)     NOT NULL,
    year              SMALLINT    NOT NULL,
    antigen_code      VARCHAR(50) NOT NULL,
    coverage_category VARCHAR(50),
    target_number     BIGINT,
    doses             BIGINT,
    coverage_pct      DECIMAL(10,2),
    FOREIGN KEY (country_code) REFERENCES countries(country_code),
    FOREIGN KEY (antigen_code) REFERENCES antigens(antigen_code),
    INDEX idx_cov_country_year (country_code, year),
    INDEX idx_cov_antigen (antigen_code)
);

CREATE TABLE reported_cases (
    case_id       INT AUTO_INCREMENT PRIMARY KEY,
    country_code  CHAR(3)     NOT NULL,
    year          SMALLINT    NOT NULL,
    disease_code  VARCHAR(50) NOT NULL,
    cases         BIGINT,
    FOREIGN KEY (country_code) REFERENCES countries(country_code),
    FOREIGN KEY (disease_code) REFERENCES diseases(disease_code),
    INDEX idx_cases_country_year (country_code, year)
);

CREATE TABLE incidence_rate (
    incidence_id    INT AUTO_INCREMENT PRIMARY KEY,
    country_code    CHAR(3)     NOT NULL,
    year            SMALLINT    NOT NULL,
    disease_code    VARCHAR(50) NOT NULL,
    denominator     VARCHAR(100),
    incidence_rate  DECIMAL(14,2),
    FOREIGN KEY (country_code) REFERENCES countries(country_code),
    FOREIGN KEY (disease_code) REFERENCES diseases(disease_code),
    INDEX idx_inc_country_year (country_code, year)
);

CREATE TABLE vaccine_introduction (
    intro_id            INT AUTO_INCREMENT PRIMARY KEY,
    country_code        CHAR(3)      NOT NULL,
    year                SMALLINT     NOT NULL,
    vaccine_description VARCHAR(250),
    introduced          VARCHAR(30),
    FOREIGN KEY (country_code) REFERENCES countries(country_code),
    INDEX idx_intro_country_year (country_code, year)
);

CREATE TABLE vaccine_schedule (
    schedule_id            INT AUTO_INCREMENT PRIMARY KEY,
    country_code           CHAR(3)     NOT NULL,
    year                   SMALLINT    NOT NULL,
    vaccine_code           VARCHAR(50),
    vaccine_description    VARCHAR(250),
    schedule_rounds        SMALLINT,
    target_pop             VARCHAR(100),
    target_pop_description VARCHAR(200),
    geo_area               VARCHAR(50),
    age_administered       VARCHAR(50),
    FOREIGN KEY (country_code) REFERENCES countries(country_code),
    INDEX idx_sched_country_year (country_code, year)
);

SHOW TABLES;
