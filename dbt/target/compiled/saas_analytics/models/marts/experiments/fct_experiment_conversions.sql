

with assignments as (
    select * from "analytics"."main"."fct_experiments_assignments"
),

events as (
    select * from "analytics"."main"."stg_events"
),

--defining conversion events we care about
conversion_events as (
    select 
        user_id,
        event_name,
        event_at 
    from events 
    where event_name in (
        'onboarding_completed',
        'feature_a_used',
        'feature_b_used',
        'upgrade',
        'cancel'
    )
),

--join conversion to assignments
--only count conversions that happened AFTER assignment
conversions_post_assignments as (
    select
        a.user_id,
        a.experiment_variant,
        a.assigned_at,
        c.event_name as conversion_event,
        c.event_at as converted_at,
        datediff('day', a.assigned_at, c.event_at) as days_to_conversion,
        datediff('hour', a.assigned_at, c.event_at) as hours_to_conversion

    from assignments a 
    inner join conversion_events c 
        on a.user_id = c.user_id 
        and c.event_at >= a.assigned_at --conversion must happen after assignment

),

--for each user-variant-conversion_event combo, take the FIRST conversion
first_conversions as (
    select 
        user_id,
        experiment_variant,
        assigned_at,
        conversion_event,
        converted_at,
        days_to_conversion,
        hours_to_conversion,
        row_number() over(
            partition by user_id, experiment_variant, conversion_event
            order by converted_at 
        ) as conversion_rn 
    from conversions_post_assignments
),

final as (
    select
        user_id,
        experiment_variant,
        assigned_at,
        conversion_event,
        converted_at,
        days_to_conversion,
        hours_to_conversion
    from first_conversions
    where conversion_rn = 1
)

select * from final