
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select subscription_id
from "analytics"."main"."fct_mrr_by_month"
where subscription_id is null



  
  
      
    ) dbt_internal_test