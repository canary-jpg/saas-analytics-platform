view: rpt_experiment_results {
  sql_table_name: marts.rpt_experiment_results ;;
  
  # Primary Key
  dimension: conversion_event {
    primary_key: yes
    type: string
    sql: ${TABLE}.conversion_event ;;
  }
  
  # Variant A Metrics
  dimension: a_total_users {
    type: number
    sql: ${TABLE}.a_total_users ;;
    group_label: "Variant A"
  }
  
  dimension: a_converted_users {
    type: number
    sql: ${TABLE}.a_converted_users ;;
    group_label: "Variant A"
  }
  
  dimension: a_conversion_rate {
    type: number
    sql: ${TABLE}.a_conversion_rate ;;
    value_format_name: percent_2
    group_label: "Variant A"
  }
  
  dimension: a_avg_days_to_conversion {
    type: number
    sql: ${TABLE}.a_avg_days_to_conversion ;;
    value_format_name: decimal_1
    group_label: "Variant A"
  }
  
  # Variant B Metrics
  dimension: b_total_users {
    type: number
    sql: ${TABLE}.b_total_users ;;
    group_label: "Variant B"
  }
  
  dimension: b_converted_users {
    type: number
    sql: ${TABLE}.b_converted_users ;;
    group_label: "Variant B"
  }
  
  dimension: b_conversion_rate {
    type: number
    sql: ${TABLE}.b_conversion_rate ;;
    value_format_name: percent_2
    group_label: "Variant B"
  }
  
  dimension: b_avg_days_to_conversion {
    type: number
    sql: ${TABLE}.b_avg_days_to_conversion ;;
    value_format_name: decimal_1
    group_label: "Variant B"
  }
  
  # Lift Metrics
  dimension: absolute_lift {
    type: number
    sql: ${TABLE}.absolute_lift ;;
    value_format_name: percent_2
    group_label: "Results"
  }
  
  dimension: relative_lift_pct {
    type: number
    sql: ${TABLE}.relative_lift_pct ;;
    value_format_name: percent_2
    group_label: "Results"
  }
  
  # Statistical Metrics
  dimension: z_score {
    type: number
    sql: ${TABLE}.z_score ;;
    value_format_name: decimal_2
    group_label: "Statistics"
  }
  
  dimension: ci_lower {
    type: number
    sql: ${TABLE}.ci_lower ;;
    value_format_name: percent_2
    group_label: "Statistics"
  }
  
  dimension: ci_upper {
    type: number
    sql: ${TABLE}.ci_upper ;;
    value_format_name: percent_2
    group_label: "Statistics"
  }
  
  dimension: is_statistically_significant {
    type: yesno
    sql: ${TABLE}.is_statistically_significant ;;
    group_label: "Results"
  }
  
  dimension: winner {
    type: string
    sql: ${TABLE}.winner ;;
    group_label: "Results"
  }
  
  # Measures
  measure: count_significant_results {
    type: count
    filters: [is_statistically_significant: "yes"]
  }
  
  measure: avg_lift {
    type: average
    sql: ${relative_lift_pct} ;;
    value_format_name: percent_2
  }
}
