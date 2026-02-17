{{
    config(
        materialized='table'
    )
}}

with mrr_by_month as (
    select * from {{ ref('fct_mrr_by_month') }}
),

--get current and prior month MRR for each user
user_mrr_current_and_prior as (
    select 
        month_date,
        user_id,
        sum(mrr) as mrr_this_month,
        lag(sum(mrr)) over (partition by user_id order by month_date) as mrr_last_month,
        lag(month_date) over (partition by user_id order by month_date) as last_month_date
    from mrr_by_month 
    group by month_date, user_id 
),

--classify MRR movement type for each user, each month
mrr_changes as (
    select
        month_date,
        user_id,
        mrr_this_month,
        mrr_last_month,

        --change amount
        mrr_this_month - coalesce(mrr_last_month, 0) as mrr_change,

        --movement type
        case 
            when mrr_last_month is null or mrr_last_month = 0 then 'new' --new customer (no MRR last month)
            when mrr_this_month = 0 then 'churn' --churned (had MRR last, none this month)
            when mrr_this_month > mrr_last_month then 'expansion' --expansion (increased MRR)
            when mrr_this_month < mrr_last_month then 'contraction' -- contraction (descreased MRR)
            else 'retained' --no change
        end as movement_type,

        --check for reactivation (churned before, now back)
        case 
            when mrr_last_month is not null 
                and mrr_last_month = 0 
                and last_month_date = add_months(month_date, -1)
            then true
            else false
        end is_reactivation
    from user_mrr_current_and_prior 
    where mrr_this_month > 0 or mrr_last_month > 0 --only keep rows where there was MRR at some point
),

--aggregate movements by month
monthly_movements as (
    select 
        month_date,
        count(distinct case when movement_type = 'new' then user_id end) as new_customers,
        count(distinct case when movement_type = 'expansion' then user_id end) as expansion_customers,
        count(distinct case when movement_type = 'contraction' then user_id end) as contraction_customers,
        count(distinct case when movement_type = 'churn' then user_id end) as churned_customers,
        count(distinct case when movement_type = 'retained' then user_id end) as retained_customers,
        count(distinct case when is_reactivation then user_id end) as reactivated_customers,

        --MRR amounts
        sum(case when movement_type = 'new' then mrr_this_month else 0 end) as new_mrr,
        sum(case when movement_type = 'expansion' then mrr_change else 0 end) as expansion_mrr,
        sum(case when movement_type = 'contraction' then abs(mrr_change) else 0 end) as contraction_mrr,
        sum(case when movement_type = 'churn' then mrr_last_month else 0 end) as churned_mrr,
        sum(case when movement_type = 'retained' then mrr_this_month else 0 end) as retained_mrr,

        --total MRR
        sum(mrr_this_month) as total_mrr,
        sum(mrr_last_month) as prior_month_mrr

    from mrr_changes
    group by month_date
),

--calculate growth rates and net change
final as (
    select 
        month_date,

        --customer counts
        new_customers,
        expansion_customers,
        contraction_customers,
        churned_customers,
        retained_customers,
        reactivated_customers,
        new_customers + expansion_customers + contraction_customers + churned_customers + retained_customers as total_customers,

        --MRR amounts
        new_mrr,
        expansion_mrr,
        contraction_mrr,
        churned_mrr,
        retained_mrr,
        total_mrr,
        prior_month_mrr,

        --net change
        new_mrr + expansion_mrr - contraction_mrr - churned_mrr as net_mrr_change,

        --growth rates
        case
            when prior_month_mrr > 0 
            then (new_mrr + expansion_mrr - contraction_mrr - churned_mrr) / prior_month_mrr * 100
            else null 
        end as mrr_growth_rate,

        case
            when prior_month_mrr > 0
            then churned_mrr / prior_month_mrr * 100
            else null
        end churn_rate 
    from monthly_movements

)

select * from final 
order by month_date 