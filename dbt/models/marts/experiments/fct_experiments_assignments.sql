{{
    config(
        materialized='table')
}}

with events as (
    select * from {{ ref('stg_events') }}
),

users as (
    select * from {{ ref('dim_users') }}
),

--get the first time each user was assigned to an experiment variant
--we use the earliest event with a non-null experiment_variant
first_assignment as (
    select
        user_id,
        experiment_variant,
        min(event_at) as assigned_at
    from events
    where experiment_variant is not null
        and event_at is not null
    group by user_id, experiment_variant
),

--in a case where a user was assigned to multiple variants (shouldn't happen but lets be safe),
--take the earliest assignment
deduplicated_assignments as (
    select
        user_id,
        experiment_variant,
        assigned_at,
        row_number() over (partition by user_id order by assigned_at) as rn 
    from first_assignment
),

final as (
    select
        a.user_id,
        a.experiment_variant,
        a.assigned_at,

        --user attributes for segmentation
        u.signed_up_at,
        u.acquisition_channel,
        u.country,
        u.user_lifecycle_stage,

        --was the user assigned on their signup day?
        a.assigned_at = u.signed_up_at as assigned_at_signup
    from deduplicated_assignments a 
    left join users u on a.user_id = u.user_id 
    where a.rn = 1
)

select * from final