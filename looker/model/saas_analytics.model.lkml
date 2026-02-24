connection: "warehouse.analytics.duckdb"

# Include all views
include: "/views/*.view.lkml"

# Set default datagroup for caching
datagroup: saas_analytics_default_datagroup {
  sql_trigger: SELECT MAX(signed_up_at) FROM marts.dim_users ;;
  max_cache_age: "1 hour"
}

persist_with: saas_analytics_default_datagroup

#########################################
# CORE USER ANALYTICS
#########################################

explore: dim_users {
  label: "Users"
  description: "User dimension with lifecycle, subscription status, and engagement metrics"
  
  join: fct_events {
    type: left_outer
    sql_on: ${dim_users.user_id} = ${fct_events.user_id} ;;
    relationship: one_to_many
  }
}

#########################################
# EVENT ANALYTICS
#########################################

explore: fct_events {
  label: "Events"
  description: "All product events with user and subscription context"
  
  join: dim_users {
    type: left_outer
    sql_on: ${fct_events.user_id} = ${dim_users.user_id} ;;
    relationship: many_to_one
  }
}

#########################################
# REVENUE ANALYTICS
#########################################

explore: rpt_mrr_movements {
  label: "MRR Movements"
  description: "Monthly MRR growth accounting (new, expansion, contraction, churn)"
}

explore: rpt_customer_ltv {
  label: "Customer LTV"
  description: "Customer lifetime value by cohort and acquisition channel"
  
  sql_table_name: marts.rpt_customer_ltv ;;
  
  dimension: user_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.user_id ;;
  }
  
  dimension_group: signed_up {
    type: time
    timeframes: [date, week, month, quarter, year]
    sql: ${TABLE}.signed_up_at ;;
  }
  
  dimension_group: cohort {
    type: time
    timeframes: [month, quarter, year]
    sql: ${TABLE}.cohort_month ;;
  }
  
  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
  }
  
  dimension: country {
    type: string
    sql: ${TABLE}.country ;;
  }
  
  dimension: ltv {
    type: number
    sql: ${TABLE}.ltv ;;
    value_format_name: usd
  }
  
  dimension: arpu {
    type: number
    sql: ${TABLE}.arpu ;;
    value_format_name: usd
  }
  
  dimension: lifetime_months {
    type: number
    sql: ${TABLE}.lifetime_months ;;
  }
  
  dimension: is_currently_active {
    type: yesno
    sql: ${TABLE}.is_currently_active ;;
  }
  
  measure: count {
    type: count
  }
  
  measure: total_ltv {
    type: sum
    sql: ${ltv} ;;
    value_format_name: usd
  }
  
  measure: avg_ltv {
    type: average
    sql: ${ltv} ;;
    value_format_name: usd
  }
  
  measure: avg_arpu {
    type: average
    sql: ${arpu} ;;
    value_format_name: usd
  }
  
  measure: avg_lifetime_months {
    type: average
    sql: ${lifetime_months} ;;
    value_format_name: decimal_1
  }
}

#########################################
# RETENTION ANALYTICS
#########################################

explore: rpt_retention_cohorts {
  label: "Retention Cohorts"
  description: "Week-over-week retention by signup cohort"
}

explore: rpt_retention_curves {
  label: "Retention Curves"
  description: "Retention curves over time (long format for charting)"
  
  sql_table_name: marts.rpt_retention_curves ;;
  
  dimension: cohort_week {
    type: date
    sql: ${TABLE}.cohort_week ;;
  }
  
  dimension: weeks_since_cohort {
    type: number
    sql: ${TABLE}.weeks_since_cohort ;;
  }
  
  dimension: cohort_size {
    type: number
    sql: ${TABLE}.cohort_size ;;
  }
  
  dimension: active_users {
    type: number
    sql: ${TABLE}.active_users ;;
  }
  
  dimension: retention_rate {
    type: number
    sql: ${TABLE}.retention_rate ;;
    value_format_name: percent_2
  }
  
  dimension: retention_pct {
    type: number
    sql: ${TABLE}.retention_pct ;;
    value_format_name: percent_1
  }
  
  dimension: cohort_label {
    type: string
    sql: ${TABLE}.cohort_label ;;
  }
  
  measure: avg_retention {
    type: average
    sql: ${retention_pct} ;;
    value_format_name: percent_1
  }
}

#########################################
# EXPERIMENT ANALYTICS
#########################################

explore: rpt_experiment_results {
  label: "A/B Test Results"
  description: "Experiment results with statistical significance"
}

explore: rpt_experiment_results_by_channel {
  label: "A/B Test Results by Channel"
  description: "Experiment results segmented by acquisition channel"
  
  sql_table_name: marts.rpt_experiment_results_by_channel ;;
  
  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
  }
  
  dimension: conversion_event {
    type: string
    sql: ${TABLE}.conversion_event ;;
  }
  
  dimension: relative_lift_pct {
    type: number
    sql: ${TABLE}.relative_lift_pct ;;
    value_format_name: percent_2
  }
  
  dimension: is_statistically_significant {
    type: yesno
    sql: ${TABLE}.is_statistically_significant ;;
  }
  
  dimension: winner {
    type: string
    sql: ${TABLE}.winner ;;
  }
  
  measure: count {
    type: count
  }
}

#########################################
# PRODUCT ANALYTICS
#########################################

explore: rpt_feature_adoption {
  label: "Feature Adoption"
  description: "Feature usage, adoption timing, and engagement levels"
  
  sql_table_name: marts.rpt_feature_adoption ;;
  
  dimension: user_id {
    type: string
    sql: ${TABLE}.user_id ;;
  }
  
  dimension: feature {
    type: string
    sql: ${TABLE}.feature ;;
  }
  
  dimension: adoption_timeframe {
    type: string
    sql: ${TABLE}.adoption_timeframe ;;
  }
  
  dimension: engagement_level {
    type: string
    sql: ${TABLE}.engagement_level ;;
  }
  
  dimension: days_to_first_use {
    type: number
    sql: ${TABLE}.days_to_first_use ;;
  }
  
  dimension: total_uses {
    type: number
    sql: ${TABLE}.total_uses ;;
  }
  
  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
  }
  
  measure: count {
    type: count
  }
  
  measure: avg_days_to_first_use {
    type: average
    sql: ${days_to_first_use} ;;
    value_format_name: decimal_1
  }
  
  measure: avg_total_uses {
    type: average
    sql: ${total_uses} ;;
    value_format_name: decimal_1
  }
}

explore: rpt_activation_funnel {
  label: "Activation Funnel"
  description: "User progression through activation milestones"
  
  sql_table_name: marts.rpt_activation_funnel ;;
  
  dimension: user_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.user_id ;;
  }
  
  dimension_group: signed_up {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.signed_up_at ;;
  }
  
  dimension: acquisition_channel {
    type: string
    sql: ${TABLE}.acquisition_channel ;;
  }
  
  dimension: activation_level {
    type: string
    sql: ${TABLE}.activation_level ;;
  }
  
  dimension: activation_score {
    type: number
    sql: ${TABLE}.activation_score ;;
  }
  
  dimension: completed_onboarding {
    type: yesno
    sql: ${TABLE}.completed_onboarding ;;
  }
  
  dimension: used_feature_a {
    type: yesno
    sql: ${TABLE}.used_feature_a ;;
  }
  
  dimension: used_feature_b {
    type: yesno
    sql: ${TABLE}.used_feature_b ;;
  }
  
  dimension: upgraded {
    type: yesno
    sql: ${TABLE}.upgraded ;;
  }
  
  dimension: days_to_onboarding {
    type: number
    sql: ${TABLE}.days_to_onboarding ;;
  }
  
  dimension: days_to_upgrade {
    type: number
    sql: ${TABLE}.days_to_upgrade ;;
  }
  
  measure: count {
    type: count
  }
  
  measure: onboarding_completion_rate {
    type: number
    sql: SUM(CASE WHEN ${completed_onboarding} THEN 1 ELSE 0 END)::float / NULLIF(${count}, 0) ;;
    value_format_name: percent_2
  }
  
  measure: conversion_rate {
    type: number
    sql: SUM(CASE WHEN ${upgraded} THEN 1 ELSE 0 END)::float / NULLIF(${count}, 0) ;;
    value_format_name: percent_2
  }
  
  measure: avg_days_to_upgrade {
    type: average
    sql: ${days_to_upgrade} ;;
    value_format_name: decimal_1
  }
}

explore: rpt_user_engagement_score {
  label: "User Engagement"
  description: "User engagement scores and activity metrics"
  
  sql_table_name: marts.rpt_user_engagement_score ;;
  
  dimension: user_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.user_id ;;
  }
  
  dimension: engagement_tier {
    type: string
    sql: ${TABLE}.engagement_tier ;;
  }
  
  dimension: engagement_score {
    type: number
    sql: ${TABLE}.engagement_score ;;
  }
  
  dimension: activity_status {
    type: string
    sql: ${TABLE}.activity_status ;;
  }
  
  dimension: active_days_l30d {
    type: number
    sql: ${TABLE}.active_days_l30d ;;
  }
  
  dimension: unique_events_l30d {
    type: number
    sql: ${TABLE}.unique_events_l30d ;;
  }
  
  dimension: is_currently_subscribed {
    type: yesno
    sql: ${TABLE}.is_currently_subscribed ;;
  }
  
  measure: count {
    type: count
  }
  
  measure: avg_engagement_score {
    type: average
    sql: ${engagement_score} ;;
    value_format_name: decimal_1
  }
}
