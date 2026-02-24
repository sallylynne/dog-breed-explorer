
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- Fails if the raw bronze table has fewer than 100 rows.
-- The Dog API serves 169 breeds; a count below 100 indicates a partial or failed load.
select count(*) as row_count
from `sally-pyne-2026`.`bronze`.`dog_api_raw`
having count(*) < 100
  
  
      
    ) dbt_internal_test