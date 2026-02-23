
    
    

with all_values as (

    select
        life_span_category as value_field,
        count(*) as n_records

    from `sally-pyne-2026`.`gold`.`fact_weight_life_span`
    group by life_span_category

)

select *
from all_values
where value_field not in (
    'Long (14+ yrs)','Average (11–13 yrs)','Short (< 11 yrs)'
)


