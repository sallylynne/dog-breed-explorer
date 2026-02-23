
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select breed_id
from `sally-pyne-2026`.`gold`.`fact_weight_life_span`
where breed_id is null



  
  
      
    ) dbt_internal_test