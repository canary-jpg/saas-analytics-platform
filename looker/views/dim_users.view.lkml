view: dim_users {
  sql_table_name: marts.dim_users ;;
  
  # Primary Key
  dimension: user_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.user_id ;;
  }
  
  # Timestamps
  dimension_group: signed_up {
    type: time
    timeframes: [date, week, month, quarter, year]
    sql: ${TABLE}.signed_up_at ;;
  }
  
  dimension_group: first_event {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.first_event_at ;;
  }
  
  dimension_group: last_event {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.last_event_at ;;
  }
  
  # Dimensions
  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
  }
  
  dimension: country {
    type: string
    sql: ${TABLE}.country ;;
    map_layer_name: countries
  }
  
  dimension: user_lifecycle_stage {
    type: string
    sql: ${TABLE}.user_lifecycle_stage ;;
  }
  
  dimension: current_plan {
    type: string
    sql: ${TABLE}.current_plan ;;
  }
  
  dimension: current_subscription_status {
    type: string
    sql: ${TABLE}.current_subscription_status ;;
  }
  
  # Numeric Dimensions
  dimension: total_events {
    type: number
    sql: ${TABLE}.total_events ;;
  }
  
  dimension: unique_event_types {
    type: number
    sql: ${TABLE}.unique_event_types ;;
  }
  
  dimension: days_since_signup {
    type: number
    sql: ${TABLE}.days_since_signup ;;
  }
  
  dimension: days_since_last_event {
    type: number
    sql: ${TABLE}.days_since_last_event ;;
  }
  
  dimension: total_subscriptions {
    type: number
    sql: ${TABLE}.total_subscriptions ;;
  }
  
  dimension: total_churns {
    type: number
    sql: ${TABLE}.total_churns ;;
  }
  
  # Revenue Dimensions
  dimension: current_monthly_revenue_usd {
    type: number
    sql: ${TABLE}.current_monthly_revenue_usd ;;
    value_format_name: usd
  }
  
  dimension: lifetime_revenue_usd {
    type: number
    sql: ${TABLE}.lifetime_revenue_usd ;;
    value_format_name: usd
  }
  
  # Boolean Dimensions
  dimension: is_currently_subscribed {
    type: yesno
    sql: ${TABLE}.is_currently_subscribed ;;
  }
  
  # Tiered Dimensions
  dimension: events_tier {
    type: tier
    tiers: [0, 5, 10, 25, 50, 100]
    style: integer
    sql: ${total_events} ;;
  }
  
  dimension: days_since_signup_tier {
    type: tier
    tiers: [0, 7, 14, 30, 60, 90]
    style: integer
    sql: ${days_since_signup} ;;
  }
  
  # Measures
  measure: count {
    type: count
    drill_fields: [user_id, signed_up_date, acquisition_channel, user_lifecycle_stage]
  }
  
  measure: count_active {
    type: count
    filters: [user_lifecycle_stage: "active"]
  }
  
  measure: count_churned {
    type: count
    filters: [user_lifecycle_stage: "churned"]
  }
  
  measure: count_never_subscribed {
    type: count
    filters: [user_lifecycle_stage: "never_subscribed"]
  }
  
  measure: total_mrr {
    type: sum
    sql: ${current_monthly_revenue_usd} ;;
    value_format_name: usd
    drill_fields: [user_id, current_plan, current_monthly_revenue_usd]
  }
  
  measure: average_mrr_per_user {
    type: average
    sql: ${current_monthly_revenue_usd} ;;
    value_format_name: usd
  }
  
  measure: total_lifetime_revenue {
    type: sum
    sql: ${lifetime_revenue_usd} ;;
    value_format_name: usd
  }
  
  measure: avg_lifetime_revenue {
    type: average
    sql: ${lifetime_revenue_usd} ;;
    value_format_name: usd
  }
  
  measure: conversion_rate {
    type: number
    sql: ${count_active}::float / NULLIF(${count}, 0) ;;
    value_format_name: percent_2
  }
}
