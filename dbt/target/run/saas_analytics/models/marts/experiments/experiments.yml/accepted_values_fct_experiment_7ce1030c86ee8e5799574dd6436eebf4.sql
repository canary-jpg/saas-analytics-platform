
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        experiment_variant as value_field,
        count(*) as n_records

    from "analytics"."main"."fct_experiments_assignments"
    group by experiment_variant

)

select *
from all_values
where value_field not in (
    'A','B'
)



  
  
      
    ) dbt_internal_test