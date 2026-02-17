
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select cohort_month
from "analytics"."main"."fct_user_activity_by_date"
where cohort_month is null



  
  
      
    ) dbt_internal_test