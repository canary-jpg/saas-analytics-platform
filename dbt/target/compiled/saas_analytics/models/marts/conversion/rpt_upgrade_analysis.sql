

with users as (
    select * from "analytics"."main"."dim_users"
),

subscriptions as (
    select * from "analytics"."main"."stg_subscriptions"
),

events as (
    select * from "analytics"."main"."fct_events"
),

--get the first paid subscription for each user
first_paid_subscription as (
    select 
        user_id,
        min(subscription_started_at) as first_paid_at,
        min(plan) as first_plan 
    from subscriptions 
    where plan != 'free'
    group by user_id 
),

--join to users to get signup date and calculate time-to-upgrade
upgrade_timing as (
    select 
        u.user_id,
        u.signed_up_at,
        u.acquisition_channel,
        u.country,
        fps.first_paid_at,
        fps.first_plan,

        --time to upgrade
        datediff('day', u.signed_up_at, fps.first_paid_at) as days_to_upgrade,
        datediff('hour', u.signed_up_at, fps.first_paid_at) as hours_to_upgrade,

        --bucketed time to upgrade
        case
            when datediff('day', u.signed_up_at, fps.first_paid_at) = 0 then '0 - Same Day'
            when datediff('day', u.signed_up_at, fps.first_paid_at) <= 1 then '1 - Day 1'
            when datediff('day', u.signed_up_at, fps.first_paid_at) <= 3  then '2 - Days 2-3'
            when datediff('day', u.signed_up_at, fps.first_paid_at) <= 7 then '3 - Days 4-7'
            when datediff('day', u.signed_up_at, fps.first_paid_at) <= 14 then '4 - Day 8-14'
            when datediff('day', u.signed_up_at, fps.first_paid_at) <= 30 then '5 - Day 15-30'
            else '6 - 30+ Days'
        end as upgrade_timeframe
    from users u 
    inner join first_paid_subscription fps 
        on u.user_id = fps.user_id 

),

--count events BEFORE upgrade to see what predicts conversion
events_before_upgrade as (
    select
        e.user_id,
        e.event_name,
        count(*) as event_count
    from events e 
    inner join upgrade_timing ut 
        on e.user_id = ut.user_id 
    where e.event_at < ut.first_paid_at --only events before they upgraded
    group by e.user_id, e.event_name
),

--pivot event counts to wide format
events_pivoted as (
    select 
        user_id,
        max(case when event_name = 'signup' then event_count else 0 end) as signup_events,
        max(case when event_name = 'onboarding_completed' then event_count else 0 end) as onboarding_completed_events,
        max(case when event_name = 'feature_a_used' then event_count else 0 end) as feature_a_used_events,
        max(case when event_name = 'feature_b_used' then event_count else 0 end) as feature_b_used_events,
        max(case when event_name = 'upgrade' then event_count else 0 end) as upgrade_events,
        max(case when event_name = 'cancel' then event_count else 0 end) as cancel_events
    from events_before_upgrade
    group by user_id 
),

--combine everything
final as (
    select 
        ut.*,

        --event counts before upgrade
        coalesce(ep.onboarding_completed_events, 0) as onboarding_completed_before_upgrade,
        coalesce(ep.feature_a_used_events, 0) as feature_a_used_before_upgrade,
        coalesce(ep.feature_b_used_events, 0)  as feature_b_used_before_upgrade,

        --flags for key behaviors
        coalesce(ep.onboarding_completed_events, 0) > 0 as completed_onboarding_before_upgrade,
        coalesce(ep.feature_a_used_events, 0) > 0 as used_feature_a_before_upgrade,
        coalesce(ep.feature_b_used_events, 0) > 0 as used_feature_b_before_upgrade

    from upgrade_timing ut 
    left join events_pivoted ep 
        on ut.user_id = ep.user_id 


)

select * from final