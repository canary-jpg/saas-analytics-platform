
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select subscription_started_at
from "analytics"."main"."stg_subscriptions"
where subscription_started_at is null



  
  
      
    ) dbt_internal_test