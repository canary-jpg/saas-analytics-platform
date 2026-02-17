{{
    config(
        materialized='table'
    )
}}

with activity as (
    select * from {{ ref('fct_user_activity_by_date') }}
),

--count cohort sizes
cohort_sizes as (
    select 
        cohort_week,
        count(distinct user_id) as cohort_size 
    from activity 
    where weeks_since_cohort = 0
    group by cohort_week
),

--count active users by cohort and week
cohort_activity as (
    select 
        cohort_week,
        weeks_since_cohort,
        count(distinct user_id) as active_users 
    from activity
    group by cohort_week, weeks_since_cohort
),

--calculate retention rates
final as (
    select 
        cs.cohort_week,
        ca.weeks_since_cohort,
        cs.cohort_size,
        ca.active_users,
        ca.active_users::float / cs.cohort_size as retention_rate,
        ca.active_users::float / cs.cohort_size * 100 as retention_pct,

        --label for charting
        cs.cohort_week::varchar || ' Cohort' as cohort_label
    from cohort_sizes cs 
    inner join cohort_activity ca 
        on cs.cohort_week =  ca.cohort_week
)

select * from final
order by cohort_week desc, weeks_since_cohort