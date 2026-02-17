
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select user_activity_date
from "analytics"."main"."fct_user_activity_by_date"
where user_activity_date is null



  
  
      
    ) dbt_internal_test