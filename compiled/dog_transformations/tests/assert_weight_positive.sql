-- Fails if any non-null minimum weight is zero or negative.
-- A non-positive value indicates the imperial weight string failed to parse correctly.
select breed_id, weight_lbs_min
from `sally-pyne-2026`.`silver`.`stg_dog_breeds`
where weight_lbs_min is not null
  and weight_lbs_min <= 0