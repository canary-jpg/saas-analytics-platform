
  
    
    

    create  table
      "analytics"."main"."rpt_experiment_results_by_channel__dbt_tmp"
  
    as (
      

with assignments as (
    select * from "analytics"."main"."fct_experiments_assignments"
),

conversions as (
    select * from "analytics"."main"."fct_experiment_conversions"
),

--count total users assigned to each variant by channel
variant_totals_by_channel as (
    select 
        acquisition_channel,
        experiment_variant,
        count(distinct user_id) as total_users 
    from assignments
    where acquisition_channel is not null --exclude users with unknown channel
    group by acquisition_channel, experiment_variant 
),

--count conversions per variant per channel per conversion event
variant_conversions_by_channel as (
    select 
        a.acquisition_channel,
        c.experiment_variant,
        c.conversion_event,
        count(distinct c.user_id) as converted_users,
        avg(c.days_to_conversion) as avg_days_to_conversion 
    from conversions c 
    inner join assignments a 
        on c.user_id = a.user_id 
    where a.acquisition_channel is not null 
    group by a.acquisition_channel, c.experiment_variant, c.conversion_event 
),

--calculate conversion rates by channel
conversion_rates_by_channel as (
    select
        vt.acquisition_channel,
        vt.experiment_variant,
        vc.conversion_event,
        vt.total_users,
        coalesce(vc.converted_users, 0) as converted_users,
        coalesce(vc.converted_users, 0)::float / vt.total_users as conversion_rate,
        vc.avg_days_to_conversion
    from variant_totals_by_channel vt 
    cross join (
        select distinct conversion_event 
        from variant_conversions_by_channel
    ) events
    left join variant_conversions_by_channel vc 
        on vt.acquisition_channel = vc.acquisition_channel
        and vt.experiment_variant = vc.experiment_variant
        and events.conversion_event = vc.conversion_event 
),

--pivot to get A vs. B side-by-side for each channel-metric combo
results_pivoted as (
    select
        acquisition_channel,
        conversion_event,

        --variant A
        max(case when experiment_variant = 'A' then total_users end) as a_total_users,
        max(case when experiment_variant = 'A' then converted_users end) as a_converted_users,
        max(case when experiment_variant = 'A' then conversion_rate end) as a_conversion_rate,

        --variant B
        max(case when experiment_variant = 'B' then total_users end) as b_total_users,
        max(case when experiment_variant = 'B' then converted_users end) as b_converted_users,
        max(case when experiment_variant = 'B' then conversion_rate end) as b_conversion_rate
    from conversion_rates_by_channel 
    group by acquisition_channel, conversion_event 
),

--calculate statistical metrics
final as (
    select 
        acquisition_channel,
        conversion_event,

        --sample sizes
        a_total_users,
        b_total_users,
        a_total_users + b_total_users as total_users,

        --conversion rates
        a_conversion_rate,
        b_conversion_rate,

        --lift
        (b_conversion_rate - a_conversion_rate) as absolute_lift,
        case
            when a_conversion_rate > 0
            then ((b_conversion_rate - a_conversion_rate) / a_conversion_rate) * 100
            else null 
        end as relative_lift_pct,

        --z-score
        case
            when sqrt(
                (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) + 
                (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
            ) > 0 
            then (b_conversion_rate - a_conversion_rate) / sqrt(
                (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) +
                (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
            )
            else null
        end as z_score,

        --95% confidence interval
        (b_conversion_rate - a_conversion_rate) - 1.96 * sqrt(
            (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) +
            (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
        ) as ci_lower,

        (b_conversion_rate - a_conversion_rate) + 1.96 * sqrt(
            (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) +
            (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
        ) as ci_upper,

        --statistical significance
        case 
            when abs(
                (b_conversion_rate - a_conversion_rate) / sqrt(
                    (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) +
                    (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
                ) 
            ) > 1.96
            then true
            else false
        end as is_statistically_significant,

        --winner
        case 
            when b_conversion_rate > a_conversion_rate then 'B'
            when a_conversion_rate > b_conversion_rate then 'A'
            else 'Tie'
        end as winner
    from results_pivoted
    where a_total_users >= 30 and b_total_users >= 30
)

select * from final
order by acquisition_channel, conversion_event
    );
  
  