
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select converted_at
from "analytics"."main"."fct_experiment_conversions"
where converted_at is null



  
  
      
    ) dbt_internal_test