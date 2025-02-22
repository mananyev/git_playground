# DTC data-engineering-zoomcamp HA3

## 0. Preparations

Setup dbt-core in GCP using [this dbt with BigQuery on Docker guide](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/e95362c73fe28cc19444e9d613ce7f4226f54f35/04-analytics-engineering/docker_setup/README.md).

I updated [Dockerfile](../code/week4/Dockerfile) to run dbt 1.7 for Python 12 (had problems with `dbt_utils.generate_surrogate_key`) and put the path to my credentials file into [docker-compose.yml](../code/week4/docker-compose.yaml).

Used Kestra to upload `.CSV` files for FHV data to GCS bucket (with the [ha4_fhv_data.yaml](../code/week4/ha4_fhv_data.yaml) script).

```sql
create or replace external table `zoomcamp.external_fhv_tripdata`
options (
  format = 'csv',
  uris = ['gs://m1sk0_test_kestra/fhv_tripdata_2019-*.csv']
);
```

Partition the table (because why not?)

```sql
create or replace table `zoomcamp.fhv_tripdata`
partition by date(pickup_datetime) as
select * from `zoomcamp.external_fhv_tripdata`;
```



## 1. Questions

### 1.1 Understanding dbt Model Resolution

Env variables set up to be `DBT_BIGQUERY_PROJECT` and `DBT_BIGQUERY_DATASET` while we are using `DBT_BIGQUERY_PROJECT` and `DBT_BIGQUERY_SOURCE_DATASET` in our macros. Therefore, the latter variable in macros is not defined and is set to default `'raw_nyc_tripdata'`.

Thus, `select * from {{ source('raw_nyc_tripdata', 'ext_green_taxi' ) }}` compiles into `select * from myproject.raw_nyc_tripdata.ext_green_taxi`.


### 1.2 dbt Variables & Dynamic Models

We need the variables being picked in the following order:

1. command line arguments
2. ENV_VARs
3. DEFAULT

The only option that satisfies this order (and has all three options) is

- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", env_var("DAYS_BACK", "30")) }}' DAY`.

If `days_back` command line variable is not set, it defaults to `env_var("DAYS_BACK", "30")`.


### 1.3 dbt Data Lineage and Execution

The only option that does not materialize `fct_taxi_monthly_zone_revenue` is

- `dbt run --select +models/core/`.


### 1.4 dbt Macros and Jinja

1. setting `DBT_BIGQUERY_TARGET_DATASET` because it is used for `core` model type with no alternatives.
2. setting `DBT_BIGQUERY_STAGING_DATASET` is not required, because the code defaults to another env variable (`env_var(stging_env_var, env_var(target_env_var))`).
3. when using `core` the `if` condition in the macros sets `env_var(target_env_var)` which is set to equal `DBT_BIGQUERY_TARGET_DATASET`.
4. when using `stg` the `if` condition in the macros switches to `else` case, therefore uses the dataset defined in `DBT_BIGQUERY_STAGING_DATASET`, and if the latter is missing, defaults to `DBT_BIGQUERY_TARGET_DATASET`, as we have seen in p.2 above.
5. same applies when using `staging`.

> **Note:** The answers above assume that we pass `core`, `stg` or `staging` as an argument to the function `resolve_schema`. The actual materialization depends on the models defined by the project structure in `dbt_project.yml` file.
> For example, with the models in my [dbt_project.yml](../code/week4/taxi_rides_ny/dbt_project.yml), passing `stg` would fail the build since there is no folder called `stg`.


## 1.5 Taxi Quarterly Revenue Growth

> For this exercise and the following ones, I made the corresponding files in [taxi_rides_ny](../code/week4/taxi_rides_ny/) folder.

After a new model [fct_taxi_trips_quarterly_revenue.sql](../code/week4/taxi_rides_ny/models/core/fct_taxi_trips_quarterly_revenue.sql) is built, I ran the following sql

```sql
select *
from `peaceful-tome-448411-p7.zoomcamp.fct_taxi_trips_quarterly_revenue`
where year in (2019, 2020)
order by service_type, year, quarter
```

and got

```cs
year	quarter	service_type	quarterly_revenue	yoy_growth
2019	1	Green	26438276.59		
2019	2	Green	21570110.95		
2019	3	Green	17706583.71		
2019	4	Green	15729300.34	1533029.979726305
2020	1	Green	11526108.62	-56.403706646 +
2020	2	Green	1547929.93	-92.823727548 -
2020	3	Green	2369501.61	-86.61796285
2020	4	Green	2449525.32	-84.426991239
2019	1	Yellow	188083480.56		
2019	2	Yellow	210192086.07		
2019	3	Yellow	195993303.46		
2019	4	Yellow	199461705.39	3008344.952081882
2020	1	Yellow	151024426.9	-19.703513328 +
2020	2	Yellow	15671668.92	-92.544120374 -
2020	3	Yellow	41845219.15	-78.649668937
2020	4	Yellow	56866378.58	-71.490077021
```


### 1.6 P97/P95/P98 Taxi Monthly Fare

Created and ran [fct_taxi_trips_monthly_fare_p95.sql](../code/week4/taxi_rides_ny/models/core/fct_taxi_trips_monthly_fare_p95.sql).

The following sql

```sql
select service_type, pct90, pct95, pct97
from `peaceful-tome-448411-p7.zoomcamp.fct_taxi_trips_monthly_fare_p95`
where year = 2020
  and month = 4
```

produces

```cs
service_type	pct90	pct95	pct97
Green	26.5	45.0	55.0
Yellow	19.0	26.0	32.0
```

> I am half a point off from the percentiles in the answers.. Could not figure why.


### 1.7 Top #Nth Longest P90 Travel Time Location for FHV

Prerequisites:

* [stg_fhv_tripdata.sql](../code/week4/taxi_rides_ny/models/staging/stg_fhv_tripdata.sql)
* [dim_fhv_trips.sql](../code/week4/taxi_rides_ny/models/core/dim_fhv_trips.sql)
* [fct_fhv_monthly_zone_traveltime_p90.sql](../code/week4/taxi_rides_ny/models/core/fct_fhv_monthly_zone_traveltime_p90.sql)

Running in BigQuery

```sql
with
nov19_rides as (
  select
    pickup_zone
    , dropoff_zone
    , pct90
    , row_number() over (
        partition by pickup_zone, year, month
        order by pct90 desc
      ) as rn
  from `peaceful-tome-448411-p7.zoomcamp.fct_fhv_monthly_zone_traveltime_p90`
  where pickup_zone in ('Newark Airport', 'SoHo', 'Yorkville East')
    and year = 2019
    and month = 11
)
select *
from nov19_rides
where rn = 2
```

gives me

```cs
pickup_zone	dropoff_zone	pct90	rn
Newark Airport	LaGuardia Airport	7028.8000000000011	2
SoHo	Chinatown	19496.0	2
Yorkville East	Garment District	13846.0	2
```


P.S. I did not have time to make the models clean and nice.. :/
