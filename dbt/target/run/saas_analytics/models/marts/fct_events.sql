
  
    
    

    create  table
      "analytics"."main"."fct_events__dbt_tmp"
  
    as (
      

with events as (
    select * from "analytics"."main"."stg_events"
),

users as (
    select * from "analytics"."main"."stg_users"
),

subscriptions as (
    select * from "analytics"."main"."stg_subscriptions"
),

-- join events to their user context
events_with_users as (
    select
        events.*,
        users.signed_up_at,
        users.acquisition_channel,
        users.country
    from events 
    left join users 
        on events.user_id = users.user_id 
),

--join events to subscriptions that are active at event time
-- this is a point-in-time join: which subscription was active when the event fired?
events_with_context as (
    select 
        e.*,
        s.subscription_id,
        s.plan as subscription_plan,
        s.subscription_status,
        s.subscription_started_at,
        s.subscription_ended_at,
        s.monthly_revenue_usd,
        datediff('day', e.signed_up_at, e.event_at) as days_since_signup
    from events_with_users e 
    left join subscriptions s 
        on e.user_id = s.user_id
        and e.event_at >= s.subscription_started_at
        and (e.event_at < s.subscription_ended_at or s.subscription_ended_at is null)
)

select * from events_with_context
    );
  
  