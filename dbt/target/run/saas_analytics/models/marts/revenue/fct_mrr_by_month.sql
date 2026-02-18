
  
    
    

    create  table
      "analytics"."main"."fct_mrr_by_month__dbt_tmp"
  
    as (
      

with subscriptions as (
    select * from "analytics"."main"."stg_subscriptions"
),

--generate a date spine for all months we have data
date_spine as (
    select distinct 
        date_trunc('month', subscription_started_at) as month_date
    from subscriptions 

    union 

    select distinct 
        date_trunc('month', subscription_ended_at) as month_date 
    from subscriptions 
    where subscription_ended_at is not null
),

--for each subscription, determine which months it was active
subscription_months as (
    select
        s.subscription_id,
        s.user_id,
        s.plan,
        s.monthly_revenue_usd,
        s.subscription_started_at,
        s.subscription_ended_at,
        d.month_date 
    from subscriptions s
    cross join date_spine d 
    where d.month_date >= date_trunc('month', s.subscription_started_at)
        and (
            s.subscription_ended_at is null 
            or d.month_date < date_trunc('month', s.subscription_ended_at)
        )
        and s.plan != 'free' --excluding free tier
),

final as (
    select 
        month_date,
        user_id,
        subscription_id,
        plan,
        monthly_revenue_usd as mrr,

        --subscription age in months
        datediff('month', date_trunc('month', subscription_started_at), month_date) as subscription_age_months,

        --flags
        date_trunc('month', subscription_started_at) = month_date as is_first_month,
        subscription_ended_at is null as is_active_subscription
    from subscription_months
)

select * from final
order by month_date, user_id
    );
  
  