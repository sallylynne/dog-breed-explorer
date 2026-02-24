-- Fails if the raw bronze table has fewer than 100 rows.
-- The Dog API serves 169 breeds; a count below 100 indicates a partial or failed load.
select count(*) as row_count
from {{ source('bronze', 'dog_api_raw') }}
having count(*) < 100
