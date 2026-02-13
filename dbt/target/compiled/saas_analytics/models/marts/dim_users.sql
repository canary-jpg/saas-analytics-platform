

with users as (

    select * from "analytics"."main"."stg_users"

),

events as (

    select * from "analytics"."main"."stg_events"

),

subscriptions as (

    select * from "analytics"."main"."stg_subscriptions"

),

-- Aggregate event activity per user
user_events as (

    select
        events.user_id,
        min(events.event_at) as first_event_at,
        max(events.event_at) as last_event_at,
        count(*) as total_events,
        count(distinct events.event_name) as unique_event_types

    from events
    where events.event_at is not null  -- exclude events with null timestamps
    group by events.user_id

),

-- Get current subscription (most recent active or most recent ended)
user_current_subscription as (

    select
        user_id,
        subscription_id as current_subscription_id,
        plan as current_plan,
        subscription_status as current_subscription_status,
        subscription_started_at as current_subscription_started_at,
        subscription_ended_at as current_subscription_ended_at,
        monthly_revenue_usd as current_monthly_revenue_usd,
        is_active as is_currently_subscribed

    from (
        select
            *,
            row_number() over (
                partition by user_id 
                order by 
                    is_active desc,  -- active subscriptions first
                    subscription_started_at desc  -- then most recent
            ) as rn
        from subscriptions
    )
    where rn = 1

),

-- Calculate lifetime subscription metrics
user_subscription_metrics as (

    select
        user_id,
        count(*) as total_subscriptions,
        sum(monthly_revenue_usd) as lifetime_revenue_usd,
        max(case when is_churned then subscription_ended_at end) as last_churn_date,
        sum(case when is_churned then 1 else 0 end) as total_churns

    from subscriptions
    group by user_id

),

-- Bring it all together
final as (

    select
        -- user identity
        u.user_id,
        u.signed_up_at,
        u.acquisition_channel,
        u.country,

        -- event activity
        e.first_event_at,
        e.last_event_at,
        e.total_events,
        e.unique_event_types,

        -- current subscription
        cs.current_subscription_id,
        cs.current_plan,
        cs.current_subscription_status,
        cs.current_subscription_started_at,
        cs.current_subscription_ended_at,
        cs.current_monthly_revenue_usd,
        cs.is_currently_subscribed,

        -- lifetime subscription metrics
        coalesce(sm.total_subscriptions, 0) as total_subscriptions,
        coalesce(sm.lifetime_revenue_usd, 0) as lifetime_revenue_usd,
        sm.last_churn_date,
        coalesce(sm.total_churns, 0) as total_churns,

        -- derived: user lifecycle stage
        case
            when cs.is_currently_subscribed then 'active'
            when sm.total_churns > 0 then 'churned'
            when sm.total_subscriptions = 0 then 'never_subscribed'
            else 'other'
        end as user_lifecycle_stage,

        -- derived: days since signup
        datediff('day', u.signed_up_at, current_date) as days_since_signup,

        -- derived: recency (days since last event)
        case
            when e.last_event_at is null then null
            else datediff('day', e.last_event_at, current_date)
        end as days_since_last_event

    from users u
    left join user_events e
        on u.user_id = e.user_id
    left join user_current_subscription cs
        on u.user_id = cs.user_id
    left join user_subscription_metrics sm
        on u.user_id = sm.user_id

)

select * from final