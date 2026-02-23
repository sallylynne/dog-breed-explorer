
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select temperament_trait
from `sally-pyne-2026`.`gold`.`fct_breed_temperament`
where temperament_trait is null



  
  
      
    ) dbt_internal_test