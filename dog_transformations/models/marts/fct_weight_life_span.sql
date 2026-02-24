{{
  config(materialized = 'table')
}}

select
    breed_id,
    breed_name,
    breed_group,
    size_class,
    weight_lbs_min,
    weight_lbs_max,
    weight_lbs_avg,
    height_in_min,
    height_in_max,
    height_in_avg,
    life_span_min_years,
    life_span_max_years,
    life_span_avg_years,
    weight_per_inch_lbs,
    life_span_category,
    is_family_friendly

from {{ ref('int_breed_base') }}
