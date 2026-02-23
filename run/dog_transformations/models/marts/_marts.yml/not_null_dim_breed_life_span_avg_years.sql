
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select life_span_avg_years
from `sally-pyne-2026`.`gold`.`dim_breed`
where life_span_avg_years is null



  
  
      
    ) dbt_internal_test