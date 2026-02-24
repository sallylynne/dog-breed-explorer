
    
    

with dbt_test__target as (

  select breed_id as unique_field
  from `sally-pyne-2026`.`gold`.`fct_weight_life_span`
  where breed_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


