
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    conversion_event as unique_field,
    count(*) as n_records

from "analytics"."main"."rpt_experiment_results"
where conversion_event is not null
group by conversion_event
having count(*) > 1



  
  
      
    ) dbt_internal_test