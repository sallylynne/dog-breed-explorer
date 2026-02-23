
    
    

with dbt_test__target as (

  select origin as unique_field
  from `sally-pyne-2026`.`gold`.`fct_origin_summary`
  where origin is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


