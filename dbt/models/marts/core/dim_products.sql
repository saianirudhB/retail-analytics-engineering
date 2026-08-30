-- Product dimension. Grain: product_id. Type-1 attributes.
{{ config(materialized='table') }}

with products as (
    select * from {{ ref('stg_products') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_key,
    product_id,
    product_category,
    product_category_name_pt,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    -- volumetric size in litres, handy for freight analysis
    round(
        (product_length_cm * product_height_cm * product_width_cm) / 1000.0, 2
    )                                                     as product_volume_litres,
    product_photos_qty,
    product_name_length,
    product_description_length,
    case
        when product_weight_g is null then 'unknown'
        when product_weight_g < 500      then 'light (<0.5kg)'
        when product_weight_g < 2000     then 'medium (0.5-2kg)'
        when product_weight_g < 10000    then 'heavy (2-10kg)'
        else 'bulky (>10kg)'
    end                                                   as weight_band
from products
