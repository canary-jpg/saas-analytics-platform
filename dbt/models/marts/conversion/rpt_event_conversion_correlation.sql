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

--get all events in first 7 days after signup
early_events as (
    select 
        e.user_id,
        e.event_name,
        count(*) as event_count 
    from events e 
    inner join users u 
        on e.user_id = u.user_id 
    where datediff('day', u.signed_up_at, e.event_at) <= 7
    group by e.user_id, e.event_name 
),

--pivot events to wide format
events_wide as (
    select
        user_id,
        sum(case when event_name = 'onboarding_completed' then event_count else 0 end) > 0 as completed_onboarding,
        sum(case when event_name = 'feature_a_used' then event_count else 0 end) > 0 as used_feature_a,
        sum(case when event_name = 'feature_b_used' then event_count else 0 end) > 0 as used_feature_b,
        sum(case when event_name = 'upgrade' then event_count else 0 end) > 0 as upgraded_in_week_1
    from early_events 
    group by user_id 
),

--join to users to get conversion status
user_conversion_status as (
    select
        u.user_id,
        u.current_plan != 'free' as is_paid_user,
        coalesce(ew.completed_onboarding, false) as completed_onboarding,
        coalesce(ew.used_feature_a, false) as used_feature_a,
        coalesce(ew.used_feature_b, false) as used_feature_b,
        coalesce(ew.upgraded_in_week_1, false) as upgraded_in_week_1
    from users u 
    left join events_wide ew 
        on u.user_id = ew.user_id 
),

--calculate conversion rates by event completion
conversion_by_onboarding as (
    select
        'Onboarding Completed' as event_type,
        completed_onboarding as completed_event,
        count(*) as total_users,
        sum(case when is_paid_user then 1 else 0 end) as paid_users,
        sum(case when is_paid_user then 1 else 0 end)::float / count(*)  * 100 conversion_rate
    from user_conversion_status 
    group by completed_onboarding
),

conversion_by_feature_a as (
    select 
        'Feature A Used' as event_type,
        used_feature_a as completed_event,
        count(*) as total_users,
        sum(case when is_paid_user then 1 else 0 end) as paid_users,
        sum(case when is_paid_user then 1 else 0 end)::float / count(*) * 100 as conversion_rate
    from user_conversion_status
    group by used_feature_a
),

conversion_by_feature_b as (
    select
        'Feature B Used' as event_type,
        used_feature_b as completed_event,
        count(*) as total_users,
        sum(case when is_paid_user then 1 else 0 end) as paid_users,
        sum(case when is_paid_user then 1 else 0 end)::float / count(*) * 100 as conversion_rate 
    from user_conversion_status
    group by used_feature_b
),

-- combine all metrics
final as (
    select * from conversion_by_onboarding
    union all 
    select * from conversion_by_feature_a
    union all
    select * from conversion_by_feature_b
)

select * from final
order by event_type, completed_event