
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select breed_group
from `sally-pyne-2026`.`gold`.`fct_breed_group_summary`
where breed_group is null



  
  
      
    ) dbt_internal_test