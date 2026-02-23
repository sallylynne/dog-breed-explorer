
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select size_class
from `sally-pyne-2026`.`gold`.`dim_breed`
where size_class is null



  
  
      
    ) dbt_internal_test