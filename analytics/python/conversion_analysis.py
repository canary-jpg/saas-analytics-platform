import pandas as pd
import duckdb

pd.set_option('display.max_colwidth', None)
query = """
    WITH user_activity AS (
    SELECT 
        user_id,
        MAX(CASE WHEN datediff('day', signed_up_at, user_activity_date) > 14 THEN 1 ELSE 0 END) as active_past_day_14,
        COUNT(DISTINCT user_activity_date) as total_active_days,
        COUNT(DISTINCT CASE WHEN datediff('day', signed_up_at, user_activity_date) <= 14 THEN user_activity_date END) as active_days_first_14
    FROM fct_user_activity_by_date
    GROUP BY user_id
),
user_events AS (
    SELECT 
        e.user_id,
        SUM(CASE WHEN e.event_name = 'feature_a_used' THEN 1 ELSE 0 END) as feature_a_count,
        SUM(CASE WHEN e.event_name = 'feature_b_used' THEN 1 ELSE 0 END) as feature_b_count
    FROM fct_events e
    INNER JOIN dim_users u ON e.user_id = u.user_id
    WHERE datediff('day', u.signed_up_at, e.event_at) <= 14
    GROUP BY e.user_id
)
SELECT 
    ua.active_past_day_14,
    COUNT(*) as users,
    AVG(ua.active_days_first_14) as avg_active_days_first_14,
    AVG(ue.feature_a_count) as avg_feature_a_uses,
    AVG(ue.feature_b_count) as avg_feature_b_uses,
    SUM(CASE WHEN u.is_currently_subscribed THEN 1 ELSE 0 END)::float / COUNT(*) * 100 as pct_paid
FROM user_activity ua
LEFT JOIN user_events ue ON ua.user_id = ue.user_id
LEFT JOIN dim_users u ON ua.user_id = u.user_id
GROUP BY ua.active_past_day_14
ORDER BY ua.active_past_day_14 DESC;
 """

df = duckdb.sql(query).df()
print(df)