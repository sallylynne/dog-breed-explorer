with source as (

    select * from `sally-pyne-2026`.`bronze`.`dog_api_raw`

),

parsed as (

    select
        cast(id as int64)                                                       as breed_id,
        name                                                                    as breed_name,
        nullif(trim(breed_group), '')                                           as breed_group,
        nullif(trim(origin), '')                                                as origin,
        nullif(trim(temperament), '')                                           as temperament,

        -- Life span: parse "8 - 13 years" or "8-13" → min / max integers
        cast(regexp_extract(life_span, r'(\d+)') as int64)                     as life_span_min_years,
        cast(regexp_extract(life_span, r'\d+\s*-\s*(\d+)') as int64)           as life_span_max_years,

        -- Weight (imperial lbs): handles both "35-50" and "Male: 65-120; Female: 55-100"
        -- Extract all numbers then take the overall min/max across male/female ranges
        (
            select min(cast(n as int64))
            from unnest(regexp_extract_all(weight__imperial, r'\d+')) as n
        )                                                                       as weight_lbs_min,
        (
            select max(cast(n as int64))
            from unnest(regexp_extract_all(weight__imperial, r'\d+')) as n
        )                                                                       as weight_lbs_max,

        -- Height (imperial inches): same parsing strategy
        (
            select min(cast(n as int64))
            from unnest(regexp_extract_all(height__imperial, r'\d+')) as n
        )                                                                       as height_in_min,
        (
            select max(cast(n as int64))
            from unnest(regexp_extract_all(height__imperial, r'\d+')) as n
        )                                                                       as height_in_max,

        reference_image_id,
        image__url                                                              as image_url,
        _dlt_load_id,
        _dlt_id

    from source

),

final as (

    select
        breed_id,
        breed_name,
        breed_group,
        origin,
        temperament,

        life_span_min_years,
        life_span_max_years,
        round((life_span_min_years + life_span_max_years) / 2.0, 1)            as life_span_avg_years,

        weight_lbs_min,
        weight_lbs_max,
        round((weight_lbs_min + weight_lbs_max) / 2.0, 1)                     as weight_lbs_avg,

        height_in_min,
        height_in_max,
        round((height_in_min + height_in_max) / 2.0, 1)                       as height_in_avg,

        -- Size classification based on average imperial weight (lbs)
        case
            when round((weight_lbs_min + weight_lbs_max) / 2.0, 1) < 12  then 'Toy'
            when round((weight_lbs_min + weight_lbs_max) / 2.0, 1) < 25  then 'Small'
            when round((weight_lbs_min + weight_lbs_max) / 2.0, 1) < 55  then 'Medium'
            when round((weight_lbs_min + weight_lbs_max) / 2.0, 1) < 100 then 'Large'
            else 'Giant'
        end                                                                     as size_class,

        reference_image_id,
        image_url,
        _dlt_load_id,
        _dlt_id

    from parsed

)

select * from final