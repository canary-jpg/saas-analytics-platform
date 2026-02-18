
    
    

select
    month_date as unique_field,
    count(*) as n_records

from "analytics"."main"."rpt_mrr_movements"
where month_date is not null
group by month_date
having count(*) > 1


