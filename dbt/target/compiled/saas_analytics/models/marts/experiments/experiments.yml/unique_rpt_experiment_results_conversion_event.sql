
    
    

select
    conversion_event as unique_field,
    count(*) as n_records

from "analytics"."main"."rpt_experiment_results"
where conversion_event is not null
group by conversion_event
having count(*) > 1


