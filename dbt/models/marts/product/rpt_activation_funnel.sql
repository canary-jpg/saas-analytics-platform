{{
    config(
        materialized='table'
    )
}}

with users as (
    select * from {{ ref('dim_users') }}
),

events as (
    select * from {{ ref('fct_events') }}
),

--define activation milestones
user_milestones as (
    select 
        user_id,

        --step 1: signed up (everyone should have this)
        true as completed_signup,

        --step 2: completed onboarding
        max(case when event_name = 'onboarding_completed' then 1 else 0 end) = 1 as completed_onboarding,
        min(case when event_name = 'onboarding_completed' then event_at end) as onboarding_completed_at,

        --step 3: used feature A
        max(case when event_name = 'feature_a_used' then 1 else 0 end) = 1 as used_feature_a,
        min(case when event_name = 'feature_a_used' then event_at end) as feature_a_first_used_at,

        --step 4: used feature B
        max(case when event_name = 'feature_b_used' then 1 else 0 end) = 1 as used_feature_b,
        min(case when event_name = 'feature_b_used' then event_at end) as feature_b_first_used_at,

        --step 5: upgraded to paid
        max(case when event_name = 'upgrade' then 1 else 0 end) = 1 as upgraded,
        min(case when event_name = 'upgrade' then event_at end) as upgrade_at

    from events 
    group by user_id   
),

--combine with user data
user_activation as (
    select 
        u.user_id,
        u.signed_up_at,
        date_trunc('month', u.signed_up_at) as cohort_month,
        u.acquisition_channel,
        u.is_currently_subscribed,

        --milestone completion
        um.completed_signup,
        coalesce(um.completed_onboarding, false) as completed_onboarding,
        coalesce(um.used_feature_a, false) as used_feature_a,
        coalesce(um.used_feature_b, false) as used_feature_b,
        coalesce(um.upgraded, false) as upgraded,

        --milestone timestamps
        um.onboarding_completed_at,
        um.feature_a_first_used_at,
        um.feature_b_first_used_at,
        um.upgrade_at,

        --time to milestone
        datediff('day', u.signed_up_at, um.onboarding_completed_at) as days_to_onboarding,
        datediff('day', u.signed_up_at, um.feature_a_first_used_at) as days_to_feature_a,
        datediff('day', u.signed_up_at, um.feature_b_first_used_at) as days_to_feature_b,
        datediff('day', u.signed_up_at, um.upgrade_at) as days_to_upgrade,

        --activation level (how many steps completed?)
        case 
            when coalesce(um.upgrade_at, false) as 'Full Activated (Paid)'
            when coalesce(um.used_feature_a, false) or coalesce(um.used_feature_b, false) as 'Feature User'
            when coalesce(um.completed_onboarding, false) as 'Onboarded'
            else 'Signed Up Only'
        end as activation_level,

        --activation score (0-5 based on steps completed)
        (case when um.completed_signup then 1 else 0 end) +
        (case when coalesce(um.completed_onboarding, false) then 1 else 0 end) + 
        (case when coalesce(um.used_feature_a, false) then 1 else 0 end) +
        (case when coalesce(um.used_feature_b, false) then 1 else 0 end) +
        (case when coalesce(u.upgraded, false) then 1 else 0 end) as activation_score
    from users u 
    left join user_milestones um 
        on u.user_id = um.user_id  
)

select * from user_activation