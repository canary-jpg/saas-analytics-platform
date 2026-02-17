
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select weeks_since_cohort
from "analytics"."main"."rpt_retention_curves"
where weeks_since_cohort is null



  
  
      
    ) dbt_internal_test