
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select cohort_week
from "analytics"."main"."rpt_retention_curves"
where cohort_week is null



  
  
      
    ) dbt_internal_test