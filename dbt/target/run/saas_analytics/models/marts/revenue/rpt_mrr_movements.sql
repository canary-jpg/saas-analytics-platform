
  
    
    

    create  table
      "analytics"."main"."rpt_mrr_movements__dbt_tmp"
  
    as (
      

with mrr_by_month as (

    select * from "analytics"."main"."fct_mrr_by_month"

),

-- Get all months and all users who ever had MRR
all_months as (
    select distinct month_date from mrr_by_month
),

all_users as (
    select distinct user_id from mrr_by_month
),

-- Create a complete spine of month-user combinations
month_user_spine as (
    select 
        m.month_date,
        u.user_id
    from all_months m
    cross join all_users u
),

-- Get MRR for each month-user, filling in 0 for missing combinations
user_mrr_complete as (
    select
        s.month_date,
        s.user_id,
        coalesce(sum(m.mrr), 0) as mrr_this_month
    from month_user_spine s
    left join mrr_by_month m
        on s.month_date = m.month_date
        and s.user_id = m.user_id
    group by s.month_date, s.user_id
),

-- Get current and prior month MRR for each user
user_mrr_current_and_prior as (

    select
        month_date,
        user_id,
        mrr_this_month,
        lag(mrr_this_month) over (partition by user_id order by month_date) as mrr_last_month,
        lag(month_date) over (partition by user_id order by month_date) as last_month_date

    from user_mrr_complete

),

-- Classify MRR movement type for each user each month
mrr_changes as (

    select
        month_date,
        user_id,
        mrr_this_month,
        mrr_last_month,

        -- change amount
        mrr_this_month - coalesce(mrr_last_month, 0) as mrr_change,

        -- movement type
        case
            -- new customer (no MRR last month, has MRR this month)
            when (mrr_last_month is null or mrr_last_month = 0) and mrr_this_month > 0 then 'new'
            
            -- churned (had MRR last month, none this month)
            when mrr_last_month > 0 and mrr_this_month = 0 then 'churn'
            
            -- expansion (increased MRR)
            when mrr_last_month > 0 and mrr_this_month > mrr_last_month then 'expansion'
            
            -- contraction (decreased MRR)
            when mrr_last_month > 0 and mrr_this_month > 0 and mrr_this_month < mrr_last_month then 'contraction'
            
            -- retained (same MRR)
            when mrr_last_month > 0 and mrr_this_month = mrr_last_month then 'retained'
            
            -- no MRR in either month - skip these
            else 'inactive'
        end as movement_type,

        -- check for reactivation (churned before, now back)
        case
            when mrr_last_month is not null 
                and mrr_last_month = 0 
                and last_month_date = month_date - interval '1 month'
                and mrr_this_month > 0
            then true
            else false
        end as is_reactivation

    from user_mrr_current_and_prior
    where mrr_last_month is not null  -- skip first month for each user

),

-- Aggregate movements by month
monthly_movements as (

    select
        month_date,

        -- customer counts (exclude 'inactive' users)
        count(distinct case when movement_type = 'new' then user_id end) as new_customers,
        count(distinct case when movement_type = 'expansion' then user_id end) as expansion_customers,
        count(distinct case when movement_type = 'contraction' then user_id end) as contraction_customers,
        count(distinct case when movement_type = 'churn' then user_id end) as churned_customers,
        count(distinct case when movement_type = 'retained' then user_id end) as retained_customers,
        count(distinct case when is_reactivation then user_id end) as reactivated_customers,

        -- MRR amounts
        sum(case when movement_type = 'new' then mrr_this_month else 0 end) as new_mrr,
        sum(case when movement_type = 'expansion' then mrr_change else 0 end) as expansion_mrr,
        sum(case when movement_type = 'contraction' then abs(mrr_change) else 0 end) as contraction_mrr,
        sum(case when movement_type = 'churn' then mrr_last_month else 0 end) as churned_mrr,
        sum(case when movement_type = 'retained' then mrr_this_month else 0 end) as retained_mrr,

        -- total MRR (sum of all users with MRR > 0 this month)
        sum(case when mrr_this_month > 0 then mrr_this_month else 0 end) as total_mrr,
        sum(case when mrr_last_month > 0 then mrr_last_month else 0 end) as prior_month_mrr

    from mrr_changes
    where movement_type != 'inactive'  -- exclude users with no MRR in both months
    group by month_date

),

-- Calculate growth rates and net change
final as (

    select
        month_date,

        -- customer counts
        new_customers,
        expansion_customers,
        contraction_customers,
        churned_customers,
        retained_customers,
        reactivated_customers,
        new_customers + expansion_customers + contraction_customers + churned_customers + retained_customers as total_customers,

        -- MRR amounts
        new_mrr,
        expansion_mrr,
        contraction_mrr,
        churned_mrr,
        retained_mrr,
        total_mrr,
        prior_month_mrr,

        -- net change
        new_mrr + expansion_mrr - contraction_mrr - churned_mrr as net_mrr_change,

        -- growth rates
        case 
            when prior_month_mrr > 0 
            then (new_mrr + expansion_mrr - contraction_mrr - churned_mrr) / prior_month_mrr * 100
            else null
        end as mrr_growth_rate,

        case
            when prior_month_mrr > 0
            then churned_mrr / prior_month_mrr * 100
            else null
        end as churn_rate

    from monthly_movements

)

select * from final
order by month_date
    );
  
  