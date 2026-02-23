
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select is_family_friendly
from `sally-pyne-2026`.`gold`.`fact_weight_life_span`
where is_family_friendly is null



  
  
      
    ) dbt_internal_test