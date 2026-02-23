
    
    

with all_values as (

    select
        size_class as value_field,
        count(*) as n_records

    from `sally-pyne-2026`.`silver`.`stg_dog_breeds`
    group by size_class

)

select *
from all_values
where value_field not in (
    'Toy','Small','Medium','Large','Giant'
)


