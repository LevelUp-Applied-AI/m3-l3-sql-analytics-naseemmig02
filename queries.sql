-- queries.sql — SQL Analytics Lab
-- Module 3: SQL & Relational Data
--
-- Instructions:
--   Write your SQL query beneath each comment block.
--   Do NOT modify the comment markers (-- Q1, -- Q2, etc.) — the autograder uses them.
--   Test each query locally: psql -h localhost -U postgres -d testdb -f queries.sql
--
-- ============================================================

-- Q1: Employee Directory with Departments
-- List all employees with their department name, sorted by department (asc) then salary (desc).
-- Expected columns: first_name, last_name, title, salary, department_name
-- SQL concepts: JOIN, ORDER BY

SELECT
    e.first_name,
    e.last_name,
    e.title,
    e.salary,
    d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name ASC, e.salary DESC;


-- Q2: Department Salary Analysis
-- Total salary expenditure by department. Only departments with total > 150,000.
-- Expected columns: department_name, total_salary
-- SQL concepts: GROUP BY, HAVING, SUM

SELECT
    d.name AS department_name,
    SUM(e.salary) AS total_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.name
HAVING SUM(e.salary) > 150000
ORDER BY total_salary DESC;


-- Q3: Highest-Paid Employee per Department
-- For each department, find the employee with the highest salary.
-- Expected columns: department_name, first_name, last_name, salary
-- SQL concepts: Window function (ROW_NUMBER or RANK), CTE

WITH ranked AS (
    SELECT
        e.first_name,
        e.last_name,
        e.salary,
        d.name AS department_name,
        ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS rn
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
)
SELECT department_name, first_name, last_name, salary
FROM ranked
WHERE rn = 1
ORDER BY department_name;


-- Q4: Project Staffing Overview
-- All projects with employee count and total hours. Include projects with 0 assignments.
-- Expected columns: project_name, employee_count, total_hours
-- SQL concepts: LEFT JOIN, GROUP BY, COALESCE

SELECT
    p.name AS project_name,
    COUNT(pa.employee_id) AS employee_count,
    COALESCE(SUM(pa.hours_allocated), 0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name
ORDER BY employee_count DESC;


-- Q5: Above-Average Departments
-- Departments where average salary exceeds the company-wide average salary.
-- Expected columns: department_name, avg_salary
-- SQL concepts: CTE

WITH company_avg AS (
    SELECT AVG(salary) AS avg_salary
    FROM employees
),
dept_avg AS (
    SELECT
        d.name AS department_name,
        AVG(e.salary) AS avg_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    GROUP BY d.name
)
SELECT
    da.department_name,
    ROUND(da.avg_salary, 2) AS avg_salary,
    ROUND(ca.avg_salary, 2) AS company_avg_salary
FROM dept_avg da
CROSS JOIN company_avg ca
WHERE da.avg_salary > ca.avg_salary
ORDER BY da.avg_salary DESC;


-- Q6: Running Salary Total
-- Each employee's salary and running total within their department, ordered by hire date.
-- Expected columns: department_name, first_name, last_name, hire_date, salary, running_total
-- SQL concepts: Window function (SUM OVER)

SELECT
    d.name AS department_name,
    e.first_name,
    e.last_name,
    e.hire_date,
    e.salary,
    SUM(e.salary) OVER (
        PARTITION BY e.department_id
        ORDER BY e.hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name, e.hire_date;


-- Q7: Unassigned Employees
-- Employees not assigned to any project.
-- Expected columns: first_name, last_name, department_name
-- SQL concepts: LEFT JOIN + NULL check (or NOT EXISTS)

SELECT
    e.first_name,
    e.last_name,
    d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
LEFT JOIN project_assignments pa ON e.employee_id = pa.employee_id
WHERE pa.assignment_id IS NULL
ORDER BY e.last_name;


-- Q8: Hiring Trends
-- Month-over-month hire count.
-- Expected columns: hire_year, hire_month, hires
-- SQL concepts: EXTRACT, GROUP BY, ORDER BY

WITH hire_counts AS (
    SELECT
        EXTRACT(YEAR FROM hire_date)::INT AS hire_year,
        EXTRACT(MONTH FROM hire_date)::INT AS hire_month,
        COUNT(*) AS hires
    FROM employees
    GROUP BY hire_year, hire_month
)
SELECT hire_year, hire_month, hires
FROM hire_counts
ORDER BY hire_year, hire_month;


-- Q9: Schema Design — Employee Certifications
-- Design and implement a certifications tracking system.
--
-- Tasks:
-- 1. CREATE TABLE certifications (certification_id SERIAL PK, name VARCHAR NOT NULL, issuing_org VARCHAR, level VARCHAR)
-- 2. CREATE TABLE employee_certifications (id SERIAL PK, employee_id FK->employees, certification_id FK->certifications, certification_date DATE NOT NULL)
-- 3. INSERT at least 3 certifications and 5 employee_certification records
-- 4. Write a query listing employees with their certifications (JOIN across 3 tables)
--    Expected columns: first_name, last_name, certification_name, issuing_org, certification_date

CREATE TABLE IF NOT EXISTS certifications (
    certification_id SERIAL PRIMARY KEY,
    name             VARCHAR(150) NOT NULL,
    issuing_org      VARCHAR(150),
    level            VARCHAR(50) CHECK (level IN ('Beginner', 'Intermediate', 'Advanced'))
);

CREATE TABLE IF NOT EXISTS employee_certifications (
    id                  SERIAL PRIMARY KEY,
    employee_id         INTEGER NOT NULL REFERENCES employees(employee_id),
    certification_id    INTEGER NOT NULL REFERENCES certifications(certification_id),
    certification_date  DATE NOT NULL
);

INSERT INTO certifications (name, issuing_org, level) VALUES
    ('AWS Certified Solutions Architect', 'Amazon Web Services', 'Advanced'),
    ('Project Management Professional',   'PMI',                 'Advanced'),
    ('Google Data Analytics Certificate', 'Google',              'Intermediate'),
    ('Certified ScrumMaster',             'Scrum Alliance',      'Beginner'),
    ('Microsoft Azure Fundamentals',      'Microsoft',           'Beginner');

INSERT INTO employee_certifications (employee_id, certification_id, certification_date) VALUES
    (1,  1, '2023-03-15'),
    (2,  2, '2022-11-20'),
    (3,  3, '2024-01-10'),
    (4,  4, '2023-07-05'),
    (5,  5, '2023-09-18'),
    (6,  1, '2024-02-28'),
    (7,  3, '2023-12-01');

SELECT
    e.first_name,
    e.last_name,
    c.name           AS certification_name,
    c.issuing_org,
    ec.certification_date
FROM employees e
JOIN employee_certifications ec ON e.employee_id = ec.employee_id
JOIN certifications c           ON ec.certification_id = c.certification_id
ORDER BY e.last_name, ec.certification_date;


-- Challenge Tier 1: At-Risk Projects
SELECT
    p.name AS project_name,
    p.budget AS available_hours_budget,
    COALESCE(SUM(pa.hours_allocated), 0) AS total_hours_allocated,
    ROUND(p.budget * 0.8, 2) AS eighty_percent_threshold,
    ROUND(COALESCE(SUM(pa.hours_allocated), 0) / p.budget * 100, 2) AS pct_budget_used
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget
HAVING COALESCE(SUM(pa.hours_allocated), 0) > p.budget * 0.8
ORDER BY pct_budget_used DESC;


-- Challenge 2: Cross-Department Analysis
-- Employees assigned to projects where the majority of team members
-- come from a different department than their own.

WITH project_home_dept AS (
    SELECT
        pa.project_id,
        e.department_id,
        COUNT(*) AS member_count,
        RANK() OVER (PARTITION BY pa.project_id ORDER BY COUNT(*) DESC) AS rn
    FROM project_assignments pa
    JOIN employees e ON pa.employee_id = e.employee_id
    GROUP BY pa.project_id, e.department_id
)
SELECT
    e.first_name,
    e.last_name,
    ed.name  AS employee_department,
    p.name   AS project_name,
    hd.name  AS project_home_department,
    pa.role
FROM employees e
JOIN departments ed         ON e.department_id = ed.department_id
JOIN project_assignments pa ON e.employee_id = pa.employee_id
JOIN projects p             ON pa.project_id = p.project_id
JOIN project_home_dept phd  ON p.project_id = phd.project_id AND phd.rn = 1
JOIN departments hd         ON phd.department_id = hd.department_id
WHERE e.department_id != phd.department_id
ORDER BY p.name, e.last_name;


-- ============================================================
-- CHALLENGE EXTENSIONS — Tier 3
-- ============================================================

-- Tier 3, Part 1: salary_history table DDL + seed data

CREATE TABLE IF NOT EXISTS salary_history (
    history_id      SERIAL PRIMARY KEY,
    employee_id     INTEGER NOT NULL REFERENCES employees(employee_id),
    salary          NUMERIC(10,2) NOT NULL CHECK (salary > 0),
    effective_date  DATE NOT NULL,
    change_reason   VARCHAR(100)
);

-- Tier 3, Part 2: Migration script — one initial record per employee

INSERT INTO salary_history (employee_id, salary, effective_date, change_reason)
SELECT employee_id, salary, hire_date, 'Initial salary at hire'
FROM employees;