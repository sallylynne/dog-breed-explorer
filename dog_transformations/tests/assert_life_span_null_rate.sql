-- Fails if more than 15% of breeds are missing life span data.
-- The current null rate is ~11% (19 of 169 breeds). A spike above 15% suggests
-- an API schema change or a degraded load.
select
    countif(life_span_avg_years is null) / count(*)  as null_rate
from {{ ref('stg_dog_breeds') }}
having countif(life_span_avg_years is null) / count(*) > 0.15
