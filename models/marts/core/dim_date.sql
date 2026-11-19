/* dim_date: one row per day 2023-01-01 .. 2028-12-31 (no package needed: GENERATOR). */
with days as (
    select dateadd(day, seq4(), '2023-01-01'::date) as date_day
    from table(generator(rowcount => 2192))
)

select
    date_day,
    year(date_day)                                   as year_number,
    quarter(date_day)                                as quarter_number,
    year(date_day) || '-Q' || quarter(date_day)      as year_quarter,
    month(date_day)                                  as month_number,
    to_char(date_day, 'YYYY-MM')                     as year_month,
    date_trunc('month', date_day)                    as month_start,
    monthname(date_day)                              as month_name,
    weekofyear(date_day)                             as week_of_year,
    dayofweekiso(date_day)                           as day_of_week,
    dayname(date_day)                                as day_name,
    dayofweekiso(date_day) in (6, 7)                 as is_weekend
from days
