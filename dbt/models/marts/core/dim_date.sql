-- Conformed calendar dimension. One row per calendar day across the configured
-- span (see `date_start` / `date_end` vars). Joined from every date/timestamp
-- foreign key in fact_order_items via a YYYYMMDD integer key.
--
-- Written with only portable constructs (extract / date_trunc / CASE) so the
-- same SQL compiles on DuckDB and Snowflake.
{{ config(materialized='table') }}

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('date_start') ~ "' as date)",
        end_date="cast('" ~ var('date_end') ~ "' as date)"
    ) }}
),

calendar as (
    select cast(date_day as date) as date
    from spine
),

parts as (
    select
        date,
        cast(extract(year    from date) as integer) as year,
        cast(extract(quarter from date) as integer) as quarter,
        cast(extract(month   from date) as integer) as month,
        cast(extract(week    from date) as integer) as week_of_year,
        cast(extract(day     from date) as integer) as day_of_month,
        cast(extract(dayofweek from date) as integer) as day_of_week  -- 0=Sun .. 6=Sat
    from calendar
)

select
    year * 10000 + month * 100 + day_of_month            as date_key,
    date,
    year,
    quarter,
    'Q' || cast(quarter as varchar)                      as quarter_name,
    month,
    year * 100 + month                                   as year_month,
    case month
        when 1 then 'January'  when 2 then 'February' when 3 then 'March'
        when 4 then 'April'    when 5 then 'May'      when 6 then 'June'
        when 7 then 'July'     when 8 then 'August'   when 9 then 'September'
        when 10 then 'October' when 11 then 'November' else 'December'
    end                                                  as month_name,
    week_of_year,
    day_of_month,
    day_of_week,
    case day_of_week
        when 0 then 'Sunday'    when 1 then 'Monday'   when 2 then 'Tuesday'
        when 3 then 'Wednesday' when 4 then 'Thursday' when 5 then 'Friday'
        else 'Saturday'
    end                                                  as day_name,
    case when day_of_week in (0, 6) then true else false end as is_weekend,
    case when date = date_trunc('month', date) then true else false end as is_first_day_of_month
from parts
