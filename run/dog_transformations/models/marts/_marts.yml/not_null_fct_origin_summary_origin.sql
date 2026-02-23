
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select origin
from `sally-pyne-2026`.`gold`.`fct_origin_summary`
where origin is null



  
  
      
    ) dbt_internal_test