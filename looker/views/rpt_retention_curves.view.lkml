view: rpt_retention_cohorts {
  sql_table_name: marts.rpt_retention_cohorts ;;
  
  # Primary Key
  dimension: cohort_week {
    primary_key: yes
    type: date
    sql: ${TABLE}.cohort_week ;;
  }
  
  dimension_group: cohort {
    type: time
    timeframes: [week, month, quarter, year]
    sql: ${TABLE}.cohort_week ;;
  }
  
  # Cohort Size
  dimension: cohort_size {
    type: number
    sql: ${TABLE}.cohort_size ;;
  }
  
  # Retention Percentages by Week
  dimension: week_0_pct {
    type: number
    sql: ${TABLE}.week_0_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_1_pct {
    type: number
    sql: ${TABLE}.week_1_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_2_pct {
    type: number
    sql: ${TABLE}.week_2_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_3_pct {
    type: number
    sql: ${TABLE}.week_3_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_4_pct {
    type: number
    sql: ${TABLE}.week_4_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_5_pct {
    type: number
    sql: ${TABLE}.week_5_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_6_pct {
    type: number
    sql: ${TABLE}.week_6_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_7_pct {
    type: number
    sql: ${TABLE}.week_7_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_8_pct {
    type: number
    sql: ${TABLE}.week_8_pct ;;
    value_format_name: percent_1
  }
  
  dimension: week_12_pct {
    type: number
    sql: ${TABLE}.week_12_pct ;;
    value_format_name: percent_1
  }
  
  # Measures
  measure: total_cohort_users {
    type: sum
    sql: ${cohort_size} ;;
  }
  
  measure: avg_week_1_retention {
    type: average
    sql: ${week_1_pct} ;;
    value_format_name: percent_1
  }
  
  measure: avg_week_4_retention {
    type: average
    sql: ${week_4_pct} ;;
    value_format_name: percent_1
  }
  
  measure: avg_week_8_retention {
    type: average
    sql: ${week_8_pct} ;;
    value_format_name: percent_1
  }
  
  measure: avg_week_12_retention {
    type: average
    sql: ${week_12_pct} ;;
    value_format_name: percent_1
  }
}
