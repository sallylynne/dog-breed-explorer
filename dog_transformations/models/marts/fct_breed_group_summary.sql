{{
  config(materialized = 'table')
}}

select
    breed_group,
    count(*)                                                        as breed_count,
    round(avg(life_span_avg_years), 1)                             as avg_life_span_years,
    round(min(life_span_avg_years), 1)                             as min_life_span_years,
    round(max(life_span_avg_years), 1)                             as max_life_span_years,
    round(avg(weight_lbs_avg), 1)                                  as avg_weight_lbs,
    round(avg(height_in_avg), 1)                                   as avg_height_in,
    countif(is_family_friendly)                                    as family_friendly_count,
    round(countif(is_family_friendly) / count(*) * 100, 1)         as pct_family_friendly

from {{ ref('int_breed_base') }}
where breed_group is not null
group by breed_group
having count(*) >= 3
order by avg_life_span_years desc nulls last
