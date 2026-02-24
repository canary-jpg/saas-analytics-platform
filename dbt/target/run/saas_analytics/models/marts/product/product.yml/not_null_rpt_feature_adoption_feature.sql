
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select feature
from "analytics"."main"."rpt_feature_adoption"
where feature is null



  
  
      
    ) dbt_internal_test