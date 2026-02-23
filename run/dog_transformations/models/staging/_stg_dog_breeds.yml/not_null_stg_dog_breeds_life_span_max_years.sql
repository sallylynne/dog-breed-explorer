
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select life_span_max_years
from `sally-pyne-2026`.`silver`.`stg_dog_breeds`
where life_span_max_years is null



  
  
      
    ) dbt_internal_test