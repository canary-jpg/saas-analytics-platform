
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select signed_up_at
from "analytics"."main"."stg_users"
where signed_up_at is null



  
  
      
    ) dbt_internal_test