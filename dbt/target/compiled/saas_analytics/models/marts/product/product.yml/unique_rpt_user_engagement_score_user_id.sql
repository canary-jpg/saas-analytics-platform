
    
    

select
    user_id as unique_field,
    count(*) as n_records

from "analytics"."main"."rpt_user_engagement_score"
where user_id is not null
group by user_id
having count(*) > 1


