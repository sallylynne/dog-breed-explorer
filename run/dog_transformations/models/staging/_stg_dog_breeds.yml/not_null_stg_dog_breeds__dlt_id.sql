
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select _dlt_id
from `sally-pyne-2026`.`silver`.`stg_dog_breeds`
where _dlt_id is null



  
  
      
    ) dbt_internal_test