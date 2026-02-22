{{
  config(materialized = 'table')
}}

select * from {{ ref('int_breed_temperament_unnested') }}
