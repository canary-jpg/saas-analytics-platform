with source as (
    select * from {{ source('raw', 'raw_events') }}
),

renamed as (
    select
        event_id,
        user_id,
        event_timestamp as event_at,
        lower(trim(event_name)) as event_name,
        lower(trim(device_type)) as device_type,
        lower(trim(plan_type)) as plan_type,
        experiment_variant,
        event_properties
    from source 
)

select * from renamed