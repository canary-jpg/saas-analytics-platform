with source as (
    select * from {{ source('raw', 'raw_users') }}
),

renamed as (
    select
        user_id,
        signup_timestamp as signed_up_at,
        lower(trim(acquisition_channel)) as acquisition_channel,
        lower(trim(country)) as country
    from source 
)

select * from renamed