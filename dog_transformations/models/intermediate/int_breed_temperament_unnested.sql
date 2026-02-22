select
    breed_id,
    breed_name,
    breed_group,
    size_class,
    is_family_friendly,
    lower(trim(tag))    as temperament_trait

from {{ ref('int_breed_base') }},
unnest(split(coalesce(temperament, ''), ',')) as tag

where lower(trim(tag)) != ''
