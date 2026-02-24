view: fct_events {
  sql_table_name: marts.fct_events ;;
  
  # Primary Key
  dimension: event_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.event_id ;;
  }
  
  # Foreign Keys
  dimension: user_id {
    type: string
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }
  
  dimension: subscription_id {
    type: string
    hidden: yes
    sql: ${TABLE}.subscription_id ;;
  }
  
  # Timestamps
  dimension_group: event {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year, hour_of_day, day_of_week]
    sql: ${TABLE}.event_at ;;
  }
  
  dimension_group: signed_up {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.signed_up_at ;;
  }
  
  # Event Dimensions
  dimension: event_name {
    type: string
    sql: ${TABLE}.event_name ;;
  }
  
  dimension: device_type {
    type: string
    sql: ${TABLE}.device_type ;;
  }
  
  dimension: plan_type {
    type: string
    sql: ${TABLE}.plan_type ;;
  }
  
  dimension: experiment_variant {
    type: string
    sql: ${TABLE}.experiment_variant ;;
  }
  
  # User Context
  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
  }
  
  dimension: country {
    type: string
    sql: ${TABLE}.country ;;
    map_layer_name: countries
  }
  
  # Subscription Context
  dimension: subscription_plan {
    type: string
    sql: ${TABLE}.subscription_plan ;;
  }
  
  dimension: subscription_status {
    type: string
    sql: ${TABLE}.subscription_status ;;
  }
  
  dimension: monthly_revenue_usd {
    type: number
    sql: ${TABLE}.monthly_revenue_usd ;;
    value_format_name: usd
  }
  
  # Derived Dimensions
  dimension: days_since_signup {
    type: number
    sql: ${TABLE}.days_since_signup ;;
  }
  
  dimension: days_since_signup_tier {
    type: tier
    tiers: [0, 1, 3, 7, 14, 30, 60]
    style: integer
    sql: ${days_since_signup} ;;
  }
  
  # Boolean flags for key events
  dimension: is_signup {
    type: yesno
    sql: ${event_name} = 'signup' ;;
  }
  
  dimension: is_onboarding_completed {
    type: yesno
    sql: ${event_name} = 'onboarding_completed' ;;
  }
  
  dimension: is_feature_a_used {
    type: yesno
    sql: ${event_name} = 'feature_a_used' ;;
  }
  
  dimension: is_feature_b_used {
    type: yesno
    sql: ${event_name} = 'feature_b_used' ;;
  }
  
  dimension: is_upgrade {
    type: yesno
    sql: ${event_name} = 'upgrade' ;;
  }
  
  dimension: is_cancel {
    type: yesno
    sql: ${event_name} = 'cancel' ;;
  }
  
  # Measures
  measure: count {
    type: count
    drill_fields: [event_date, event_name, user_id, device_type]
  }
  
  measure: unique_users {
    type: count_distinct
    sql: ${user_id} ;;
    drill_fields: [user_id, acquisition_channel, count]
  }
  
  measure: unique_event_types {
    type: count_distinct
    sql: ${event_name} ;;
  }
  
  measure: signups {
    type: count
    filters: [is_signup: "yes"]
  }
  
  measure: onboarding_completions {
    type: count
    filters: [is_onboarding_completed: "yes"]
  }
  
  measure: feature_a_uses {
    type: count
    filters: [is_feature_a_used: "yes"]
  }
  
  measure: feature_b_uses {
    type: count
    filters: [is_feature_b_used: "yes"]
  }
  
  measure: upgrades {
    type: count
    filters: [is_upgrade: "yes"]
  }
  
  measure: cancellations {
    type: count
    filters: [is_cancel: "yes"]
  }
  
  measure: avg_days_since_signup {
    type: average
    sql: ${days_since_signup} ;;
    value_format_name: decimal_1
  }
}
