{{
  config(materialized = 'table')
}}

with summary as (

    select
        origin,
        count(*)                                                    as breed_count,
        round(avg(life_span_avg_years), 1)                         as avg_life_span_years,
        round(avg(weight_lbs_avg), 1)                              as avg_weight_lbs,
        countif(is_family_friendly)                                as family_friendly_count,
        round(countif(is_family_friendly) / count(*) * 100, 1)     as pct_family_friendly

    from {{ ref('int_breed_base') }}
    where origin is not null
    group by origin
    having count(*) >= 2

),

size_counts as (

    select
        origin,
        size_class,
        count(*)    as n

    from {{ ref('int_breed_base') }}
    where origin is not null
    group by origin, size_class

),

size_ranked as (

    select
        origin,
        size_class,
        row_number() over (partition by origin order by n desc)     as rn

    from size_counts

)

select
    s.origin,
    s.breed_count,
    s.avg_life_span_years,
    s.avg_weight_lbs,
    s.family_friendly_count,
    s.pct_family_friendly,
    r.size_class                                                    as most_common_size_class

from summary s
left join size_ranked r on s.origin = r.origin and r.rn = 1

order by s.breed_count desc
