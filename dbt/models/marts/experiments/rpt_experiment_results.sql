{{
    config(
        materialized='table'
    )
}}

with assignments as (

    select * from {{ ref('fct_experiments_assignments') }}

),

conversions as (

    select * from {{ ref('fct_experiment_conversions') }}

),

-- Count total users assigned to each variant
variant_totals as (

    select
        experiment_variant,
        count(distinct user_id) as total_users

    from assignments
    group by experiment_variant

),

-- Count conversions per variant per conversion event
variant_conversions as (

    select
        experiment_variant,
        conversion_event,
        count(distinct user_id) as converted_users,
        avg(days_to_conversion) as avg_days_to_conversion,
        median(days_to_conversion) as median_days_to_conversion

    from conversions
    group by experiment_variant, conversion_event

),

-- Calculate conversion rates
conversion_rates as (

    select
        vt.experiment_variant,
        vc.conversion_event,
        vt.total_users,
        coalesce(vc.converted_users, 0) as converted_users,
        coalesce(vc.converted_users, 0)::float / vt.total_users as conversion_rate,
        vc.avg_days_to_conversion,
        vc.median_days_to_conversion

    from variant_totals vt
    cross join (select distinct conversion_event from variant_conversions) events
    left join variant_conversions vc
        on vt.experiment_variant = vc.experiment_variant
        and events.conversion_event = vc.conversion_event

),

-- Pivot to get control vs treatment side-by-side for each metric
results_pivoted as (

    select
        conversion_event,

        -- Variant A (assuming this is control)
        max(case when experiment_variant = 'A' then total_users end) as a_total_users,
        max(case when experiment_variant = 'A' then converted_users end) as a_converted_users,
        max(case when experiment_variant = 'A' then conversion_rate end) as a_conversion_rate,
        max(case when experiment_variant = 'A' then avg_days_to_conversion end) as a_avg_days_to_conversion,

        -- Variant B (assuming this is treatment)
        max(case when experiment_variant = 'B' then total_users end) as b_total_users,
        max(case when experiment_variant = 'B' then converted_users end) as b_converted_users,
        max(case when experiment_variant = 'B' then conversion_rate end) as b_conversion_rate,
        max(case when experiment_variant = 'B' then avg_days_to_conversion end) as b_avg_days_to_conversion

    from conversion_rates
    group by conversion_event

),

-- Calculate statistical metrics
final as (

    select
        conversion_event,

        -- Variant A stats
        a_total_users,
        a_converted_users,
        a_conversion_rate,
        a_avg_days_to_conversion,

        -- Variant B stats
        b_total_users,
        b_converted_users,
        b_conversion_rate,
        b_avg_days_to_conversion,

        -- Lift calculation
        (b_conversion_rate - a_conversion_rate) as absolute_lift,
        case 
            when a_conversion_rate > 0 
            then ((b_conversion_rate - a_conversion_rate) / a_conversion_rate) * 100
            else null
        end as relative_lift_pct,

        -- Standard error for each variant (for confidence intervals)
        sqrt(a_conversion_rate * (1 - a_conversion_rate) / a_total_users) as a_standard_error,
        sqrt(b_conversion_rate * (1 - b_conversion_rate) / b_total_users) as b_standard_error,

        -- Pooled standard error (for z-test)
        sqrt(
            (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) +
            (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
        ) as pooled_standard_error,

        -- Z-score (test statistic)
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

        -- 95% confidence interval for B - A difference
        (b_conversion_rate - a_conversion_rate) - 1.96 * sqrt(
            (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) +
            (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
        ) as ci_lower,

        (b_conversion_rate - a_conversion_rate) + 1.96 * sqrt(
            (a_conversion_rate * (1 - a_conversion_rate) / a_total_users) +
            (b_conversion_rate * (1 - b_conversion_rate) / b_total_users)
        ) as ci_upper,

        -- Statistical significance (at 95% confidence level, z > 1.96)
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

        -- Which variant won
        case
            when b_conversion_rate > a_conversion_rate then 'B'
            when a_conversion_rate > b_conversion_rate then 'A'
            else 'Tie'
        end as winner

    from results_pivoted

)

select * from final