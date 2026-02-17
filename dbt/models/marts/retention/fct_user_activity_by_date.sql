{{
    config(
        materialized='table')
}}

with users as (
    select * from {{ ref('dim_users') }}
),

events as (
    select * from {{ ref('fct_events') }}
),

--getting all dates a user was active (meaning they fired an event)
user_activity_dates as (
    select distinct 
        user_id,
        event_at as user_activity_date 
    from events 
    where event_at is not null 
),

--join to user dimension to get cohort info
final as (
    select 
        a.user_id,
        a.user_activity_date,

        --cohort definition: week user signed up
        date_trunc('week', u.signed_up_at) as cohort_week,

        --cohort definition: month user signed up 
        date_trunc('month', u.signed_up_at) as cohort_month,

        --user attributes for segmentation
        u.acquisition_channel,
        u.country,
        u.signed_up_at,

        --time since signup
        datediff('day', u.signed_up_at, a.user_activity_date) as days_since_signup,

        --which week since signup (0 = signup week, 1 = 1 week, etc.)
        floor(datediff('day', date_trunc('week', u.signed_up_at), date_trunc('week', a.user_activity_date)) /7) as weeks_since_cohort,

        --which month since signup
        datediff('month', date_trunc('month', u.signed_up_at), date_trunc('month', a.user_activity_date)) as months_since_cohort
    from user_activity_dates a 
    inner join users u 
        on a.user_id = u.user_id 

)

select * from final