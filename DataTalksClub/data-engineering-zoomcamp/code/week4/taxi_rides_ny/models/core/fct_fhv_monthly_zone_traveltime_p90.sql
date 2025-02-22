with
data as (
    select
        *,
        timestamp_diff(dropoff_datetime, pickup_datetime, second) as trip_duration
    from {{ ref('dim_fhv_trips') }}
),
final as (
    select
        *,
        percentile_cont(trip_duration, .9) over (partition by year, month, pickup_locationid, dropoff_locationid) as pct90
    from data
)
select
    year,
    month,
    pickup_zone,
    dropoff_zone,
    any_value(pct90) as pct90
from final
group by year, month, pickup_zone, dropoff_zone
