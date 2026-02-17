
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select cohort_week
from "analytics"."main"."fct_user_activity_by_date"
where cohort_week is null



  
  
      
    ) dbt_internal_test