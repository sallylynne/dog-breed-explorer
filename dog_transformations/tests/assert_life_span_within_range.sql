-- Fails if any non-null parsed life span falls outside the plausible 1–30 year range.
-- Values outside this window indicate a regex parsing error in stg_dog_breeds.
select breed_id, life_span_avg_years
from {{ ref('stg_dog_breeds') }}
where life_span_avg_years is not null
  and (life_span_avg_years < 1 or life_span_avg_years > 30)
