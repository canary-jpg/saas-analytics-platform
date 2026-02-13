with source as (
    select * from {{ source('raw', 'raw_subscriptions') }}
),

renamed as (
    select
        subscription_id,
        user_id,
        start_date as subscription_started_at,
        end_date as subscription_ended_at,
        lower(trim(plan)) as plan,
        lower(trim(status)) as subscription_status,
        monthly_revenue as monthly_revenue_usd,
        end_date is null as is_active,
        end_date is not null as is_churned
    from source
)

select * from renamed