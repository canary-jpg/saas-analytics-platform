
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        subscription_status as value_field,
        count(*) as n_records

    from "analytics"."main"."stg_subscriptions"
    group by subscription_status

)

select *
from all_values
where value_field not in (
    'active','canceled'
)



  
  
      
    ) dbt_internal_test