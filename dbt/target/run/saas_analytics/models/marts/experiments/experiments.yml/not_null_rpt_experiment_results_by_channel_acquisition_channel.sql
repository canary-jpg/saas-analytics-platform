
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select acquisition_channel
from "analytics"."main"."rpt_experiment_results_by_channel"
where acquisition_channel is null



  
  
      
    ) dbt_internal_test