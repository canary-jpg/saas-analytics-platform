
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month_date
from "analytics"."main"."fct_mrr_by_month"
where month_date is null



  
  
      
    ) dbt_internal_test