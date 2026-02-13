
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select plan
from "analytics"."main"."stg_subscriptions"
where plan is null



  
  
      
    ) dbt_internal_test