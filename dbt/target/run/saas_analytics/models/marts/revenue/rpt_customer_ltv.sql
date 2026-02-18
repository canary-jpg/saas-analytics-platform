
  
    
    

    create  table
      "analytics"."main"."rpt_customer_ltv__dbt_tmp"
  
    as (
      

with users as (
    select * from "analytics"."main"."dim_users"
),

subscriptions as (
    select * from "analytics"."main"."stg_subscriptions"
),

--calculate lifetime metrics per user
user_lifetime_metrics as (
    select 
        s.user_id,
        min(s.subscription_started_at) as first_subscription_date,
        max(s.subscription_ended_at) as last_subscription_end_date,

        --lifetime in months (for currently active users, use current date)
        case 
            when max(s.is_active) = true then datediff('month', min(s.subscription_started_at), current_date)
            else datediff('month', min(s.subscription_started_at), max(s.subscription_ended_at))
        end as lifetime_months,
        count(distinct s.subscription_id) as total_subscriptions,

        --revenue metrics
        sum(s.monthly_revenue_usd) as total_revenue,
        avg(s.monthly_revenue_usd) as avg_monthly_revenue,

        --current status
        max(s.is_active) as is_currently_active,
        max(s.is_churned) as has_churned
    from subscriptions s 
    where s.plan != 'free'
    group by s.user_id 
),

--calculate LTV
user_ltv as (
    select
        ulm.*,

        --LTV = total revenue (this is simplified; could also be monthly_revenue  * lifetime_months)
        ulm.total_revenue as ltv,

        --average revenue per month
        case
            when ulm.lifetime_months > 0 then ulm.total_revenue / ulm.lifetime_months 
            else ulm.total_revenue 
        end as arpu --average revenue per user per month
    from user_lifetime_metrics ulm 

),

--join users to get cohort and channel info
final as (
    select
        u.user_id,
        u.signed_up_at,
        date_trunc('month', u.signed_up_at) as cohort_month,
        u.acquisition_channel,
        u.country,

        --lifetime metrics
        ltv.first_subscription_date,
        ltv.last_subscription_end_date,
        ltv.lifetime_months,
        ltv.total_subscriptions,
        ltv.total_revenue,
        ltv.avg_monthly_revenue,
        ltv.ltv,
        ltv.arpu,

        --status
        ltv.is_currently_active,
        ltv.has_churned,

        --time to first subscription 
        datediff('day', u.signed_up_at, ltv.first_subscription_date) as days_to_first_subscription
    from users u 
    inner join user_ltv ltv 
        on u.user_id = ltv.user_id 
)

select * from final
    );
  
  