
    
    

select
    cohort_week as unique_field,
    count(*) as n_records

from "analytics"."main"."rpt_retention_cohorts"
where cohort_week is not null
group by cohort_week
having count(*) > 1


