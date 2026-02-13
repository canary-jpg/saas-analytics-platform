
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        conversion_event as value_field,
        count(*) as n_records

    from "analytics"."main"."fct_experiment_conversions"
    group by conversion_event

)

select *
from all_values
where value_field not in (
    'onboarding_completed','feature_a_used','feature_b_used','upgrade','cancel'
)



  
  
      
    ) dbt_internal_test