
    
    

with dbt_test__target as (

  select breed_name as unique_field
  from `sally-pyne-2026`.`silver`.`stg_dog_breeds`
  where breed_name is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


