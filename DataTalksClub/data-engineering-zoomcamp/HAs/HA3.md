# DTC data-engineering-zoomcamp HA3

## 0. Preparations

### 0.1 Add credentials for GCP to Kestra

I decided to upload the data using Kestra.

Following this [documentation](https://kestra.io/docs/how-to-guides/google-credentials#add-service-account-as-a-secret) Bruno shared in the thread to his [post](https://datatalks-club.slack.com/archives/C01FABYF2RG/p1738520204522619) about GCP credentials for Kestra.

Executed:

```bash
export SECRET_GCP_SERVICE_ACCOUNT='~/.gc/gcp-zoomcamp-service.json'
gcloud auth activate-service-account --key-file $SECRET_GCP_SERVICE_ACCOUNT

# navigate to the directory with you service-account json-file and run
echo SECRET_GCP_SERVICE_ACCOUNT=$(cat ./gcp-zoomcamp-service.json | base64 -w 0) >> .env_encoded
# this will create the `.env_encoded` file with secrets credential
```

Adjusted the `docker-compose.yml` file: added `env_file: ~/.gc/.env_encoded` line to use those credentials, and launched Kestra in GCP VM.


### 0.2 Setup GCS Bucket and BQ Dataset

Adjusted and ran [04_gcp_kv.yaml](../code/week3/04_gcp_kv.yaml) file using the values for my project ID and BQ bucket name (globally unique).

> If you already have those, go to the next step. Otherwise, run [05_gcp_setup.yaml](../code/week3/05_gcp_setup.yaml) to create.


### 0.3 Upload the `.parquet` files to GCS

I made a Kestra YAML file [ha3_yellow_taxi_data.yaml](../code/week3/ha3_yellow_taxi_data.yaml) for downloading the data from the [TLC Trip Record Data website](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) and putting them to GCS.

Ran the backfill from `'2024-01-01 00:00:00'` to `'2024-06-02 00:00:00'`.


### 0.4 BigQuery Setup
Create an external table using the Yellow Taxi Trip Records.

**Note:** need to use the PARQUET option files when creating an External Table.

Using the following SQL:

```sql
create or replace external table `zoomcamp.external_yellow_tripdata`
options (
  format = 'parquet',
  uris = ['gs://m1sk0_test_kestra/yellow_tripdata_2024-*.parquet']
);
```

Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table).

Using the following SQL:

```sql
create or replace table `zoomcamp.materialized_yellow_tripdata` as
select * from `zoomcamp.external_yellow_tripdata`;
```



## 1. Questions

### 1.1 Count of Records

```sql
select count(1)
from `zoomcamp.external_yellow_tripdata`;
```

gives

```
f0_
20332093
```


### 1.2 Count distinct number of PULocationIDs

```sql
select count(distinct PULocationID)
from `zoomcamp.external_yellow_tripdata`;
```

shows 'This query will process 0 B when run.'

```sql
select count(distinct PULocationID)
from `zoomcamp.materialized_yellow_tripdata`;
```

gives 'This query will process 155.12 MB when run.'


### 1.3 Estimated Number of Bytes

Querying only PULocationID estimates to process 155.12 MB while querying both PULocationID and DOLocationID shows the estimate of 310.24 MB.

This is happening becaues BigQuery is a columnar database and it scans the specific columns requested in the query. Selecting two columns instead of one doubles the estimated number of bytes being processed.


### 1.4 Zero Fare Amount

```sql
select count(1)
from `zoomcamp.materialized_yellow_tripdata`
where fare_amount = 0;
```

gives 

```
f0_
8333
```


### 1.5 

Partitioning is best used when we filter or aggregate on a singe column.
Clustering is best used when partitioning (alone) does not help much (more granularity, multiple columns filters and/or aggregations, large cardinality). Also, clustering can be thought of as ordering the records.

So, if we always filter based on `tpep_dropoff_datetime` (which is a `timestamp`) and order the results by `VendorID` (which is an `integer`), the best way to make an optimized table is to partition by the first, and cluster by the second column.

> P.S.: Note,  that storage size of the non-partitioned table is `2.72 GB`, so although partitioning and clustering make sense (no performance gains for tables `<1 GB`), the actual performance gain might not be that large compared to clustering alone. The reason is that due to the small amount of data per partition (less than 1 GB) we would prefer clustering over partitioning.

```sql
create or replace table `zoomcamp.yellow_tripdata_partitioned_clustered`
partition by date(tpep_pickup_datetime)
cluster by VendorID as
select * from `zoomcamp.external_yellow_tripdata`;
```


### 1.6 Estimated Bytes Processed After Partition

<details>
<summary>Query on a materialized table</summary>

```sql
select distinct VendorID
from `zoomcamp.materialized_yellow_tripdata`
where tpep_dropoff_datetime between '2024-03-01' and '2024-03-15';
```
</details>

gives 'This query will process 310.24 MB when run.'

<details>
<summary>Query on a partitioned and clustered table</summary>

```sql
select distinct VendorID
from `zoomcamp.yellow_tripdata_partitioned_clustered`
where tpep_dropoff_datetime between '2024-03-01' and '2024-03-15';
```
</details>

gives 'This query will process 26.86 MB when run.'


### 1.7 Where Is External Table Stored?

As the lecturer says at [11:14 of this video](https://youtu.be/jrHljAoD6nM?si=c-hRwHDXAoI0aXnx&t=674), an external table is stored in the Google Cloud Storage, not in BigQuery.
Google documentation on external tables says that you can use Cloud Storage, Bigtable or Google Drive.

> I could not find the bucket corresponding to my extenal table in GCS and my Bigtable service is not connected, so I was a bit confused with answer options..


### 1.8 Best Practice

As discussed by the lecturer in [this video](https://youtu.be/-CqXf7vhhDs?si=mvgSP1Kh8_wo0D6Y&t=360) and mentioned in 1.5 above, clustering might not add to performance of the table but also weaken the sort property of the table. The latter can happen if the newly inserted data is written to blocks that contain key ranges that overlap with the key ranges in previously written blocks.


### 1.9 Bonus Question

```sql
select count(*) from `zoomcamp.materialized_yellow_tripdata`;
```

shows 'This query will process 0 B when run.'