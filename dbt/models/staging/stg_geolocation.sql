-- The raw geolocation table has ~1M rows: many lat/long points per zip-code
-- prefix. Collapse to one representative row per prefix (centroid + modal
-- city/state) so it can be joined 1:1 downstream without fanout.
with source as (
    select * from {{ source('olist', 'geolocation') }}
),

cleaned as (
    select
        lpad(cast(geolocation_zip_code_prefix as varchar), 5, '0') as zip_code_prefix,
        cast(geolocation_lat as double)                            as latitude,
        cast(geolocation_lng as double)                            as longitude,
        lower(trim(geolocation_city))                             as city,
        upper(trim(geolocation_state))                             as state
    from source
    -- a handful of rows carry lat/long outside Brazil's bounding box
    where geolocation_lat between -34 and 6
      and geolocation_lng between -74 and -33
),

ranked as (
    select
        *,
        row_number() over (
            partition by zip_code_prefix
            order by city, state
        ) as rn,
        count(*)   over (partition by zip_code_prefix) as points_in_prefix
    from cleaned
),

centroid as (
    select
        zip_code_prefix,
        avg(latitude)  as latitude,
        avg(longitude) as longitude
    from cleaned
    group by 1
)

select
    r.zip_code_prefix,
    c.latitude,
    c.longitude,
    r.city,
    r.state,
    r.points_in_prefix
from ranked r
join centroid c using (zip_code_prefix)
where r.rn = 1
