# KPI Brief — Levant Tech Solutions
## HR & Project Management Key Performance Indicators

---

## KPI 1: Department Salary Efficiency (Salary per Employee)

**Definition:** Total salary expenditure divided by number of employees per department, calculated using Q2 (total salaries) and employee counts from the employees table.

**Current value:** Engineering is highest at $78,167 per employee; Customer Support is lowest at $46,400 per employee. Company-wide average is $63,200.

**Interpretation:** Engineering's high salary-per-employee reflects investment in senior technical talent, while Customer Support's lower figure may signal a compensation competitiveness risk and potential for higher turnover.

---

## KPI 2: Employee Project Utilization Rate

**Definition:** Percentage of employees assigned to at least one project, calculated as (total employees − unassigned employees) / total employees. Derived from Q7 (unassigned employees) and total headcount.

**Current value:** (60 − 18) / 60 = **70% utilization rate** — 18 employees are currently unassigned to any project.

**Interpretation:** With 30% of staff unassigned, the company has significant bench capacity that could be allocated to the two unstaffed projects (Blockchain Pilot and Quantum Computing Research).

---

## KPI 3: Project Staffing Ratio (Employees per Project)

**Definition:** Average number of employees assigned per project, calculated from Q4 as total assignments divided by number of projects with at least one assignment.

**Current value:** 80 total assignments across 13 staffed projects = **~6.2 employees per project on average**.

**Interpretation:** Projects are reasonably well-staffed on average, but 2 out of 15 projects have zero assignments, indicating stalled or not-yet-started initiatives that need management attention.

---

## KPI 4: Departments Paying Above Company Average

**Definition:** Count of departments where the average employee salary exceeds the company-wide average salary of $63,200, derived from Q5.

**Current value:** **4 out of 8 departments** pay above average — Engineering ($78,167), Research ($69,750), Finance ($68,833), and Marketing ($64,667).

**Interpretation:** Half the departments pay above the company average, which reflects healthy differentiation by function, though HR and Customer Support sitting well below average may warrant a compensation review.

---

## KPI 5: Monthly Hiring Velocity

**Definition:** Average number of new hires per month across the company's full hiring history, derived from Q8 (60 employees hired over 36 months).

**Current value:** 60 hires ÷ 36 months = **~1.7 hires per month on average**.

**Interpretation:** Hiring has been steady since 2022 with a peak of 4 hires in January 2022, and the most recent months (Jan–Feb 2025) show continued activity, suggesting the company is in a stable growth phase.




---

## Tier 3 — Production Migration Analysis

### How would you handle this migration in production with live data?

The safest approach is a **zero-downtime migration** using these steps:

1. **Create the new table first** — `salary_history` can be added without touching existing tables, so there is no risk to live data at this stage.
2. **Backfill in batches** — instead of one large `INSERT ... SELECT`, run the migration in batches (e.g., 500 employees at a time) to avoid locking the database or causing performance spikes during business hours.
3. **Run in a transaction** — wrap the migration in a transaction so if anything fails midway, it rolls back cleanly with no partial data.
4. **Deploy during low-traffic hours** — schedule the migration for off-peak hours (e.g., late night) to minimize impact on users.
5. **Verify before going live** — after backfilling, run a `COUNT(*)` check to confirm every employee has at least one record before switching application code to use the new table.

### What are the risks of adding a new table and backfilling?

| Risk | Explanation |
|------|-------------|
| **Data inconsistency** | If employees receive salary updates while the backfill is running, some records may capture stale salary values |
| **Lock contention** | A large INSERT can lock tables and slow down or block other queries running at the same time |
| **Partial migration failure** | If the script crashes midway without a transaction, you end up with incomplete data that's hard to detect |
| **Application breakage** | If application code is deployed expecting `salary_history` to exist before the migration runs, queries will fail |
| **Storage growth** | Salary history will grow continuously over time — indexes and storage costs need to be planned for upfront |

### Mitigation strategy
Use a **feature flag** to control when the application starts writing to `salary_history`. This way the table can exist and be backfilled safely before any live writes depend on it.