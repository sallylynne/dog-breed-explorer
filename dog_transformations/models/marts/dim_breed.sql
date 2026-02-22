{{
  config(materialized = 'table')
}}

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

    -- Top temperament trait flags (for easy BI filtering)
    is_loyal,
    is_intelligent,
    is_friendly,
    is_affectionate,
    is_gentle,
    is_playful,
    is_energetic,
    is_protective,
    is_calm,
    is_independent

from {{ ref('int_breed_base') }}
