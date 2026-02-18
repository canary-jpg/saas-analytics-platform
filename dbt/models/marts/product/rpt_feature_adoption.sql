{{
    config(
        materialized='table'
    )
}}

with users as (
    select * from {{ ref('dim_users') }}
),

events as (
    select * from {{ ref('fct_events') }}
),

--define key feature events
feature_events as (
    select 
        user_id,
        event_name as feature,
        min(event_at) as first_used_at,
        max(event_at) as last_used_at,
        count(*) as total_uses,
        count(distinct event_at) as days_used
    from events 
    where event_name in ('feature_a_used', 'feature_b_used', 'onboarding_completed')
    group by user_id, event_name 
),

--join to users to get cohort info
feature_adoption as (
    select
        u.user_id,
        u.signed_up_at,
        date_trunc('month', u.signed_up_at) as cohort_month,
        u.acquisition_channel,
        u.user_lifecycle_stage,
        u.is_currently_subscription,
        fe.feature,
        fe.first_used_at,
        fe.last_used_at,
        fe.total_uses,
        fe.days_used,

        --time to adoption
        datediff('day', u.signed_up_at, fe.first_used_at) as days_to_first_use,
        datediff('hour', u.signed_up_at, fe.first_used_at) as hours_to_first_use,

        --adoption timeframe buckets
        case
            when datediff('day', u.signed_up_at, fe.first_used_at) = 0 then 'Day 0 - Signup Day'
            when datediff('day', u.signed_up_at, fe.first_used_at) <= 1 then 'Day 1'
            when datediff('day', u.signed_up_at, fe.first_used_at) <= 3 then 'Days 2-3'
            when datediff('day', u.signed_up_at, fe.first_used_at) <= 7 then 'Days 4-7'
            when datediff('day', u.signed_up_at, fe.first_used_at) <= 14 then 'Days 8-14'
            when datediff('day', u.signed_up_at, fe.first_used_at) <= 30 then 'Days 15-30'
            else '30+ Days'
        end as adoption_timeframe,

        --engagement level
        case
            when fe.days_used >= 10 then 'Power User'
            when fe.days_used >= 5 then 'Regular User'
            when fe.days_used >= 2 then 'Occassional User'
            else 'One-Time User'
        end as engagement_level,

        --recency
        datediff('day', fe.last_used_at, current_date) as days_since_last_use

    from users u 
    inner join feature_events fe 
        on u.user_id = fe.user_id 
)

select * from feature_adoption