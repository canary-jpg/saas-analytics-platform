
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month_date
from "analytics"."main"."rpt_mrr_movements"
where month_date is null



  
  
      
    ) dbt_internal_test