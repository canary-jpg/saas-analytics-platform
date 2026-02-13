
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select conversion_event
from "analytics"."main"."rpt_experiment_results_by_channel"
where conversion_event is null



  
  
      
    ) dbt_internal_test