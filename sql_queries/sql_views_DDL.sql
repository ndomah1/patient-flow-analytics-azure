-- KPI 1: Beds occupied total
CREATE OR ALTER VIEW vw_bed_occupancy AS
SELECT 
    p.sex,
    CAST(SUM(CASE WHEN f.is_currently_admitted = 1 THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(DISTINCT f.bed_id), 0) * 100 AS bed_occupancy_percent
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key
WHERE p.is_current = 1
GROUP BY p.sex;
GO

-- KPI 2: Total bed turnover
CREATE OR ALTER VIEW vw_bed_turnover_rate AS
SELECT 
    p.sex,
    COUNT(DISTINCT f.fact_id) * 1.0 / NULLIF(COUNT(DISTINCT f.bed_id), 0) AS bed_turnover_rate
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key
WHERE p.is_current = 1
GROUP BY p.sex;
GO

-- KPI 3: Total active patients currently admitted
CREATE OR ALTER VIEW vw_patient_demographics AS
SELECT 
    p.sex,
    COUNT(CASE WHEN f.is_currently_admitted = 1 THEN f.fact_id END) AS total_patients
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key
WHERE p.is_current = 1
GROUP BY p.sex;
GO

-- KPI 4: Avg treatment duration
CREATE OR ALTER VIEW vw_avg_treatment_duration AS
SELECT 
    d.department,
    p.sex,
    AVG(f.length_of_stay_hours) AS avg_treatment_duration
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key
JOIN dbo.dim_department d ON f.department_sk = d.surrogate_key
WHERE p.is_current = 1
GROUP BY d.department, p.sex;
GO

-- Chart 1: Total patients count over time
CREATE OR ALTER VIEW vw_patient_volume_trend AS
SELECT 
    f.admission_date,
    p.sex,
    COUNT(DISTINCT f.fact_id) AS patient_count
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key
WHERE p.is_current = 1
GROUP BY f.admission_date, p.sex;
GO

-- Chart 2: Total patients over department
CREATE OR ALTER VIEW vw_department_inflow AS
SELECT 
    d.department,
    p.sex,
    COUNT(CASE WHEN f.is_currently_admitted = 1 THEN f.fact_id END) AS patient_count
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key
JOIN dbo.dim_department d ON f.department_sk = d.surrogate_key
WHERE p.is_current = 1
GROUP BY d.department, p.sex;
GO

-- Chart 3: Total overstay patients count (> 50 hours)
CREATE OR ALTER VIEW vw_overstay_patients AS
SELECT 
    d.department,
    p.sex,
    COUNT(f.fact_id) AS overstay_count
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key
JOIN dbo.dim_department d ON f.department_sk = d.surrogate_key
WHERE f.length_of_stay_hours > 50 AND p.is_current = 1
GROUP BY d.department, p.sex;

-- 4. AVG treatment duration
CREATE OR ALTER VIEW vw_avg_treatment_duration AS 
SELECT 
    d.department,
    p.sex,
    AVG(f.length_of_stay_hours) AS avg_treatment_duration
FROM dbo.fact_patient_flow f
JOIN dbo.dim_patient p ON f.patient_sk = p.surrogate_key 
JOIN dbo.dim_department d ON f.department_sk = d.surrogate_key 
GROUP BY d.department, p.sex;
