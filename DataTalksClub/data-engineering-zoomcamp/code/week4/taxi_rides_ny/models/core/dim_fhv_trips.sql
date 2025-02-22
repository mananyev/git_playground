with fhv_tripdata as (
    select
        *, 
        'FHV' as service_type
    from {{ ref('stg_fhv_tripdata') }}
), 
dim_zones as (
    select * from {{ ref('dim_zones') }}
    where borough != 'Unknown'
)
select
    pickup_locationid,
    pickup_zone.borough as pickup_borough, 
    pickup_zone.zone as pickup_zone, 
    dropoff_locationid,
    dropoff_zone.borough as dropoff_borough, 
    dropoff_zone.zone as dropoff_zone,  
    pickup_datetime,
    dropoff_datetime,
    sr_flag,
    dispatching_base_num,
    affiliated_base_number,
    service_type,
    extract(year FROM cast(pickup_datetime as timestamp)) as year,
    extract(month FROM cast(pickup_datetime as timestamp)) as month
from fhv_tripdata
    inner join dim_zones as pickup_zone
        on fhv_tripdata.pickup_locationid = pickup_zone.locationid
    inner join dim_zones as dropoff_zone
        on fhv_tripdata.dropoff_locationid = dropoff_zone.locationid
