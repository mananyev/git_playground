
Setup dbt-core in GCP using [this dbt with BigQuery on Docker guide](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/e95362c73fe28cc19444e9d613ce7f4226f54f35/04-analytics-engineering/docker_setup/README.md).

Use Kestra to upload `.CSV` files for FHV data to GCS bucket (with the [ha4_fhv_data.yaml](../code/week4/ha4_fhv_data.yaml) script).

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