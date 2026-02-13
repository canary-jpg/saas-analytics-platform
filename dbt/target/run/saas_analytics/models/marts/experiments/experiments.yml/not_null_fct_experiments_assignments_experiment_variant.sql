
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select experiment_variant
from "analytics"."main"."fct_experiments_assignments"
where experiment_variant is null



  
  
      
    ) dbt_internal_test