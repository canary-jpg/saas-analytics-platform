
  
    
    

    create  table
      "analytics"."main"."rpt_user_engagement_score__dbt_tmp"
  
    as (
      

with users as (
    select * from "analytics"."main"."dim_users"
),

activity as (
    select * from "analytics"."main"."fct_user_activity_by_date"
),

events as (
    select * from "analytics"."main"."fct_events"
),

--get the latest date in the data to use as "today"
data_date_range as (
    select
        max(user_activity_date) as latest_date
    from activity
),

--calculate activity metrics per user
user_activity_metrics as (
    select 
        user_id,

        --overall activity
        count(distinct a.user_activity_date) as total_active_days,
        min(a.user_activity_date) as first_active_date,
        max(a.user_activity_date) as last_active_date,
        datediff('day', min(a.user_activity_date), max(a.user_activity_date)) + 1 as activity_span_days,

        --recent activity (last 30 days)
        count(distinct case
            when a.user_activity_date >= d.latest_date - interval '30 days'
            then a.user_activity_date
        end) as active_days_l30d,

        count(distinct case
            when a.user_activity_date >= d.latest_date - interval '7 days'
            then a.user_activity_date
        end) as active_days_l7d,

        --weekly activity rate
        count(distinct case
            when a.user_activity_date >= d.latest_date - interval '30 days'
            then a.user_activity_date
            end)::float / 30 * 7 as avg_days_per_week_l30d
    from activity a
    cross join data_date_range d 
    group by a.user_id, d.latest_date
),

--calculate event diversity (breadth of engagement)
user_event_diversity as (
    select 
        e.user_id,
        count(distinct e.event_name) as unique_events_all_time,
        count(*) as total_events_all_time,

        --last 30 days
        count(distinct case
            when e.event_at >= d.latest_date - interval '30 days'
            then e.event_name
        end) as unique_events_l30d,

        count(distinct case
            when e.event_at >= d.latest_date - interval '30 days'
            then 1
        end) as total_events_l30d
    from events e 
    cross join data_date_range d 
    where e.event_at is not null 
    group by e.user_id, d.latest_date
),

--combine metrics and calculate engagement score
user_engagement as (
    select 
        u.user_id,
        u.signed_up_at,
        u.acquisition_channel,
        u.is_currently_subscribed,
        u.user_lifecycle_stage,

        --activity metrics
        coalesce(am.total_active_days, 0) as total_active_days,
        coalesce(am.active_days_l30d, 0) as active_days_l30d,
        coalesce(am.active_days_l7d, 0) as active_days_l7d,
        coalesce(am.avg_days_per_week_l30d, 0) as avg_days_per_week_l30d,
        am.first_active_date,
        am.last_active_date,
        am.activity_span_days,

        --event metrics
        coalesce(ed.unique_events_all_time, 0) as unique_events_all_time,
        coalesce(ed.total_events_all_time, 0) as total_events_all_time,
        coalesce(ed.unique_events_l30d, 0) as unique_events_l30d,
        coalesce(ed.total_events_l30d, 0) as total_events_l30d,

        --DAU/WAU/MAU classification
        case 
            when coalesce(am.active_days_l7d, 0) >= 1 then 'WAU'
            when coalesce(am.active_days_l30d, 0) >= 1 then 'MAU'
            else 'Dormant'
        end as activity_status,

        --engagement score (0-100)
        --formula: (recency * 30) + (frequency * 40) + (breadth * 30)
        least(100, (
            --recency: active in the last 7 days = 30 pts, last 30 days = 15 pts
            case 
                when coalesce(am.active_days_l7d, 0) >= 1 then 30
                when coalesce(am.active_days_l30d, 0) >= 1 then 15
                else 0
            end +
            --frequency: days active in the last 30 days (max 40 pts)
            least(40, coalesce(am.active_days_l30d, 0) * 1.33) +
            --breadth: unique events in the last 30 days (max 30 pts)
            least(30, coalesce(ed.unique_events_l30d, 0) * 6)
        )) as engagement_score,

        --engagement tier
        case 
            when least(100, (
                case
                    when coalesce(am.active_days_l7d, 0) >= 1 then 30
                    when coalesce(am.active_days_l30d, 0) >= 1 then 15 
                    else 0
                end + 
                least(40, coalesce(am.active_days_l30d, 0) * 1.33) +
                least(30, coalesce(ed.unique_events_l30d, 0) * 6)
            )) >= 70 then 'High Engagement'
            when least(100, (
                case
                    when coalesce(am.active_days_l7d, 0) >= 1 then 30
                    when coalesce(am.active_days_l30d, 0) >= 1 then 15
                    else 0
                end +
                least(40, coalesce(am.active_days_l30d, 0) * 1.33) +
                least(30, coalesce(ed.unique_events_l30d, 0) * 6)
            )) >= 40 then 'Medium Engagement'
            when least(100, (
                case 
                    when coalesce(am.active_days_l7d, 0) >= 1 then 30
                    when coalesce(am.active_days_l30d, 0) >= 1 then 15
                    else 0
                end +
                least(40, coalesce(am.active_days_l30d, 0) * 1.33) +
                least(30, coalesce(ed.unique_events_l30d, 0) * 6)
            )) > 0 then 'Low Engagement'
            else 'Dormant'
        end as engagement_tier,

        --recency
        case
            when am.last_active_date is null then null 
            else datediff('day', am.last_active_date, current_date)
        end as days_since_last_active
    from users u 
    left join user_activity_metrics am 
        on u.user_id = am.user_id 
    left join user_event_diversity ed 
        on u.user_id = ed.user_id 
)

select * from user_engagement
    );
  
  