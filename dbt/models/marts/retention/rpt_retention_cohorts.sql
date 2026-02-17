{{
    config(
        materialized='table'
    )
}}

with activity as (
    select * from {{ ref('fct_user_activity_by_date') }}
),

--count cohort sizes (total users who signed up in each cohort week)
cohort_sizes as (
    select 
        cohort_week,
        count(distinct user_id) as cohort_size 
    from activity 
    where weeks_since_cohort = 0
    group by cohort_week 
),

--count how many users from each cohort were active in each subsequent week
cohort_activity as (
    select 
        cohort_week,
        weeks_since_cohort,
        count(distinct user_id) as active_users
    from activity 
    group by cohort_week, weeks_since_cohort
),

--calculate retention rates
retention_rates as (
    select
        cs.cohort_week,
        cs.cohort_size,
        ca.weeks_since_cohort,
        ca.active_users,
        ca.active_users::float / cs.cohort_size as retention_rate,
        ca.active_users::float / cs.cohort_size * 100 as retention_pct 
    from cohort_sizes cs
    inner join cohort_activity ca 
        on cs.cohort_week = ca.cohort_week
),

--pivot to wide format for classic cohort table
-- show week 0 through week 12 (adjust as needed)
pivoted as (
    select
        cohort_week,
        cohort_size,
        max(case when weeks_since_cohort = 0 then retention_pct end) as week_0_pct,
        max(case when weeks_since_cohort = 1 then retention_pct end) as week_1_pct,
        max(case when weeks_since_cohort = 2 then retention_pct end) as week_2_pct,
        max(case when weeks_since_cohort = 3 then retention_pct end) as week_3_pct,
        max(case when weeks_since_cohort = 4 then retention_pct end) as week_4_pct,
        max(case when weeks_since_cohort = 5 then retention_pct end) as week_5_pct,
        max(case when weeks_since_cohort = 6 then retention_pct end) as week_6_pct,
        max(case when weeks_since_cohort = 7 then retention_pct end) as week_7_pct,
        max(case when weeks_since_cohort = 8 then retention_pct end) as week_8_pct,
        max(case when weeks_since_cohort = 9 then retention_pct end) as week_9_pct,
        max(case when weeks_since_cohort = 10 then retention_pct end) as week_10_pct,
        max(case when weeks_since_cohort = 11 then retention_pct end) as week_11_pct,
        max(case when weeks_since_cohort = 12 then retention_pct end) as week_12_pct
    from retention_rates 
    group by cohort_week, cohort_size 

)

select * from pivoted 
order by cohort_week desc 