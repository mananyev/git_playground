with
cleared_rides as (
    select
        *,
        extract(year FROM cast(pickup_datetime as timestamp)) as year,
        extract(month FROM cast(pickup_datetime as timestamp)) as month
    from {{ ref('fact_trips') }}
    where fare_amount > 0
        and trip_distance > 0
        and payment_type_description in ('Cash', 'Credit card')
)
, pctiles as (
    select
        service_type,
        year,
        month,
        percentile_cont(fare_amount, 0.9) over (partition by service_type, year, month) as pct90,
        percentile_cont(fare_amount, 0.95) over (partition by service_type, year, month) as pct95,
        percentile_cont(fare_amount, 0.97) over (partition by service_type, year, month) as pct97
    from cleared_rides
)
select
    service_type,
    year,
    month,
    any_value(pct90) as pct90,
    any_value(pct95) as pct95,
    any_value(pct97) as pct97
from pctiles
group by service_type, year, month
