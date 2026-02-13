
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select subscription_status
from "analytics"."main"."stg_subscriptions"
where subscription_status is null



  
  
      
    ) dbt_internal_test