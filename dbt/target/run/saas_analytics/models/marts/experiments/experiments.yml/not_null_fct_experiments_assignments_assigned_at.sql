
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select assigned_at
from "analytics"."main"."fct_experiments_assignments"
where assigned_at is null



  
  
      
    ) dbt_internal_test