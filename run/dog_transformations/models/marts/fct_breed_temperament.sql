
  
    

    create or replace table `sally-pyne-2026`.`gold`.`fct_breed_temperament`
      
    
    

    OPTIONS()
    as (
      

with __dbt__cte__int_breed_base as (
select
    breed_id,
    breed_name,
    breed_group,
    origin,
    temperament,
    size_class,
    life_span_min_years,
    life_span_max_years,
    life_span_avg_years,
    weight_lbs_min,
    weight_lbs_max,
    weight_lbs_avg,
    height_in_min,
    height_in_max,
    height_in_avg,
    image_url,
    reference_image_id,

    -- Derived metrics (moved here so all marts share one definition)
    round(weight_lbs_avg / nullif(height_in_avg, 0), 2)            as weight_per_inch_lbs,

    case
        when life_span_avg_years >= 14 then 'Long (14+ yrs)'
        when life_span_avg_years >= 11 then 'Average (11–13 yrs)'
        else 'Short (< 11 yrs)'
    end                                                             as life_span_category,

    regexp_contains(
        lower(coalesce(temperament, '')),
        r'gentle|friendly|affectionate|patient|good-natured'
    )                                                               as is_family_friendly,

    -- Top temperament trait flags (derived from the same temperament string)
    regexp_contains(lower(coalesce(temperament, '')), r'loyal')         as is_loyal,
    regexp_contains(lower(coalesce(temperament, '')), r'intelligent')   as is_intelligent,
    regexp_contains(lower(coalesce(temperament, '')), r'friendly')      as is_friendly,
    regexp_contains(lower(coalesce(temperament, '')), r'affectionate')  as is_affectionate,
    regexp_contains(lower(coalesce(temperament, '')), r'gentle')        as is_gentle,
    regexp_contains(lower(coalesce(temperament, '')), r'playful')       as is_playful,
    regexp_contains(lower(coalesce(temperament, '')), r'energetic')     as is_energetic,
    regexp_contains(lower(coalesce(temperament, '')), r'protective')    as is_protective,
    regexp_contains(lower(coalesce(temperament, '')), r'calm')          as is_calm,
    regexp_contains(lower(coalesce(temperament, '')), r'independent')   as is_independent

from `sally-pyne-2026`.`silver`.`stg_dog_breeds`
),  __dbt__cte__int_breed_temperament_unnested as (
select
    breed_id,
    breed_name,
    breed_group,
    size_class,
    is_family_friendly,
    lower(trim(tag))    as temperament_trait

from __dbt__cte__int_breed_base,
unnest(split(coalesce(temperament, ''), ',')) as tag

where lower(trim(tag)) != ''
) select * from __dbt__cte__int_breed_temperament_unnested
    );
  