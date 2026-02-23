
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select breed_id
from `sally-pyne-2026`.`gold`.`dim_breed`
where breed_id is null



  
  
      
    ) dbt_internal_test