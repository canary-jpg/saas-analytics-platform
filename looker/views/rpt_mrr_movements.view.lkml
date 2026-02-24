view: rpt_mrr_movements {
  sql_table_name: marts.rpt_mrr_movements ;;
  
  # Primary Key
  dimension: month_date {
    primary_key: yes
    type: date
    sql: ${TABLE}.month_date ;;
  }
  
  dimension_group: month {
    type: time
    timeframes: [month, quarter, year]
    sql: ${TABLE}.month_date ;;
  }
  
  # Customer Counts
  dimension: new_customers {
    type: number
    sql: ${TABLE}.new_customers ;;
  }
  
  dimension: expansion_customers {
    type: number
    sql: ${TABLE}.expansion_customers ;;
  }
  
  dimension: contraction_customers {
    type: number
    sql: ${TABLE}.contraction_customers ;;
  }
  
  dimension: churned_customers {
    type: number
    sql: ${TABLE}.churned_customers ;;
  }
  
  dimension: retained_customers {
    type: number
    sql: ${TABLE}.retained_customers ;;
  }
  
  dimension: reactivated_customers {
    type: number
    sql: ${TABLE}.reactivated_customers ;;
  }
  
  dimension: total_customers {
    type: number
    sql: ${TABLE}.total_customers ;;
  }
  
  # MRR Amounts
  dimension: new_mrr {
    type: number
    sql: ${TABLE}.new_mrr ;;
    value_format_name: usd
  }
  
  dimension: expansion_mrr {
    type: number
    sql: ${TABLE}.expansion_mrr ;;
    value_format_name: usd
  }
  
  dimension: contraction_mrr {
    type: number
    sql: ${TABLE}.contraction_mrr ;;
    value_format_name: usd
  }
  
  dimension: churned_mrr {
    type: number
    sql: ${TABLE}.churned_mrr ;;
    value_format_name: usd
  }
  
  dimension: retained_mrr {
    type: number
    sql: ${TABLE}.retained_mrr ;;
    value_format_name: usd
  }
  
  dimension: total_mrr {
    type: number
    sql: ${TABLE}.total_mrr ;;
    value_format_name: usd
  }
  
  dimension: prior_month_mrr {
    type: number
    sql: ${TABLE}.prior_month_mrr ;;
    value_format_name: usd
  }
  
  dimension: net_mrr_change {
    type: number
    sql: ${TABLE}.net_mrr_change ;;
    value_format_name: usd
  }
  
  # Rates
  dimension: mrr_growth_rate {
    type: number
    sql: ${TABLE}.mrr_growth_rate ;;
    value_format_name: percent_2
  }
  
  dimension: churn_rate {
    type: number
    sql: ${TABLE}.churn_rate ;;
    value_format_name: percent_2
  }
  
  # Measures (for aggregation across multiple months)
  measure: total_new_customers {
    type: sum
    sql: ${new_customers} ;;
  }
  
  measure: total_churned_customers {
    type: sum
    sql: ${churned_customers} ;;
  }
  
  measure: sum_new_mrr {
    type: sum
    sql: ${new_mrr} ;;
    value_format_name: usd
    drill_fields: [month_date, new_mrr, new_customers]
  }
  
  measure: sum_churned_mrr {
    type: sum
    sql: ${churned_mrr} ;;
    value_format_name: usd
    drill_fields: [month_date, churned_mrr, churned_customers]
  }
  
  measure: sum_expansion_mrr {
    type: sum
    sql: ${expansion_mrr} ;;
    value_format_name: usd
  }
  
  measure: sum_contraction_mrr {
    type: sum
    sql: ${contraction_mrr} ;;
    value_format_name: usd
  }
  
  measure: avg_mrr_growth_rate {
    type: average
    sql: ${mrr_growth_rate} ;;
    value_format_name: percent_2
  }
  
  measure: avg_churn_rate {
    type: average
    sql: ${churn_rate} ;;
    value_format_name: percent_2
  }
  
  measure: latest_mrr {
    type: max
    sql: ${total_mrr} ;;
    value_format_name: usd
  }
}
