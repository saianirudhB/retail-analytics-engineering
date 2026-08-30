-- One row per product. Joins the PT->EN category translation so downstream
-- models never have to know about the Portuguese category names.
with products as (
    select * from {{ source('olist', 'products') }}
),

translation as (
    select * from {{ source('olist', 'product_category_name_translation') }}
),

renamed as (
    select
        p.product_id,
        p.product_category_name                              as product_category_name_pt,
        coalesce(t.product_category_name_english,
                 p.product_category_name,
                 'unknown')                                  as product_category,
        cast(p.product_name_lenght        as integer)        as product_name_length,
        cast(p.product_description_lenght as integer)        as product_description_length,
        cast(p.product_photos_qty         as integer)        as product_photos_qty,
        cast(p.product_weight_g           as integer)        as product_weight_g,
        cast(p.product_length_cm          as integer)        as product_length_cm,
        cast(p.product_height_cm          as integer)        as product_height_cm,
        cast(p.product_width_cm           as integer)        as product_width_cm
    from products p
    left join translation t
        on p.product_category_name = t.product_category_name
)

select * from renamed
