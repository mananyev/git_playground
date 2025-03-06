# DTC data-engineering-zoomcamp HA5

## 0. Preparations

Setup Spark using the steps in [spark_setup.sh](../code/week5/spark_setup.sh).

```
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 3.3.2
      /_/
         
Using Scala version 2.12.15 (OpenJDK 64-Bit Server VM, Java 11.0.2)
```



# 1. Questions

All my code is in the [`HA.ipynb` Jupyter Notebook](../code/week5/HA5.ipynb).


## 1.1 Installed Spark Version

After imports, run `spark.version` to get `'3.3.2'`.


## 1.2 Partitions Yellow October 2024

After writing the parquet to `yellow/2024/10/`, and running `ls -lh yellow/2024/10` I get:

```sh
total 97M
-rw-r--r-- 1 m1sk0 m1sk0   0 Mar  6 22:54 _SUCCESS
-rw-r--r-- 1 m1sk0 m1sk0 25M Mar  6 22:54 part-00000-75625f18-74be-4097-8fbb-54fc2b665a47-c000.snappy.parquet
-rw-r--r-- 1 m1sk0 m1sk0 25M Mar  6 22:54 part-00001-75625f18-74be-4097-8fbb-54fc2b665a47-c000.snappy.parquet
-rw-r--r-- 1 m1sk0 m1sk0 25M Mar  6 22:54 part-00002-75625f18-74be-4097-8fbb-54fc2b665a47-c000.snappy.parquet
-rw-r--r-- 1 m1sk0 m1sk0 25M Mar  6 22:54 part-00003-75625f18-74be-4097-8fbb-54fc2b665a47-c000.snappy.parquet
```

Therefore, average file size is approximately `25M`.


## 1.3 Count Records

I first created `pickup_date` and `dropoff_date` columns using `spark.sql.functions`.
Also, created a TempView with `createOrReplaceTempView('df')` method.
After that, with

```python
spark.sql("""
select count(1)
from df
where pickup_date = date('2024-10-15')
""").head()
```

I get 

```
Row(count(1)=128893)
```

> Note, that when limiting the dropoff date to be October 15, 2024, I get 127993 records - does not match the answers exactly...


## 1.4 Longest Trip

With

```python
spark.sql("""
select (
    extract(day from tpep_dropoff_datetime - tpep_pickup_datetime) * 24
    + extract(hour from tpep_dropoff_datetime - tpep_pickup_datetime)
) as longest_trip_hours
from df
order by tpep_dropoff_datetime - tpep_pickup_datetime desc
limit 1
""").head()
```

I get

```
Row(longest_trip_hours=162)
```


## 1.5 User Interface

As Alexey explained with port forwarding in [this video](https://youtu.be/hqUbB9c8sKg?si=XhjcCDEy4iz2ptMB&t=758), the Spark runs on port 4040.

> This port can be also seen if running `spark` command and checking `Spark UI` link in its output.


## 1.6 Least Frequent Pickup Location Zone

Downloaded `taxi_zone_lookup.csv` file. Read the file as a Spark DataFrame
and created a TempView `df_zones` with `createOrReplaceTempView('df_zones')`.
After that, with 

```python
spark.sql("""
select
    df_zones.Zone
    , count(1)  as rides
from df
    left join df_zones on df_zones.LocationID = df.PULocationID
group by df_zones.Zone
order by rides
limit 1
""").head()
```

I get

```
Row(Zone="Governor's Island/Ellis Island/Liberty Island", rides=1)
```
