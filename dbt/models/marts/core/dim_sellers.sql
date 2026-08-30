-- Seller dimension. Grain: seller_id. Type-1 attributes.
{{ config(materialized='table') }}

with sellers as (
    select * from {{ ref('stg_sellers') }}
),

geo as (
    select * from {{ ref('stg_geolocation') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['s.seller_id']) }} as seller_key,
    s.seller_id,
    s.seller_city,
    s.seller_state,
    {{ brazil_region('s.seller_state') }}                   as seller_region,
    s.seller_zip_code_prefix,
    g.latitude                                             as seller_latitude,
    g.longitude                                            as seller_longitude
from sellers s
left join geo g on s.seller_zip_code_prefix = g.zip_code_prefix
