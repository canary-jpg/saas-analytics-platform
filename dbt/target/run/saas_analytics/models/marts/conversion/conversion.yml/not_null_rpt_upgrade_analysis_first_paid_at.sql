
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select first_paid_at
from "analytics"."main"."rpt_upgrade_analysis"
where first_paid_at is null



  
  
      
    ) dbt_internal_test