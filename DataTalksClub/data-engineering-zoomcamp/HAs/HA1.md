# DTC data-engineering-zoomcamp HA1

## 1. Understanding docker first run

I run in terminal
```sh
docker run -it --entrypoint=bash python:3.12.8
```
and then
```bash
python -m pip --version
```
which gives me `pip 24.3.1`.


## 2. Understanding docker-compose

Given this part of the code
```yaml
services:
  db:
	...
	image: postgres:17-alpine
	...
    ports:
      - '5433:5432'

  pgadmin:
    ...
    image: dpage/pgadmin4:latest
	...
```
of the YAML file, we can see that there is a service called `db` that uses Postgres 17. `db` has host port 5433 and local port 5432.

As Alexey explained in [this video](https://youtu.be/tOr4hTsHOzU?si=9NgbLnCB6TJqZK3o&t=945), both servises are created with one docker-compose file share the same network, therefore port-forwarding does not apply.
Therefore, the other service, `pgadmin`, should use `db:5432` to connect to the postgres database since it operates in the same network.


## 3. Trip segmentation count

I used
<details>
<summary>the following query</summary>

```sql
select
	sum(case when green_taxi_data.trip_distance <= 1 then 1 else 0 end) as up_to_1_mile
	, sum(case when green_taxi_data.trip_distance > 1 and green_taxi_data.trip_distance <= 3 then 1 else 0 end) as from_1_to_3_miles
	, sum(case when green_taxi_data.trip_distance > 3 and green_taxi_data.trip_distance <= 7 then 1 else 0 end) as from_1_to_3_miles
	, sum(case when green_taxi_data.trip_distance > 7 and green_taxi_data.trip_distance <= 10 then 1 else 0 end) as from_1_to_3_miles
	, sum(case when green_taxi_data.trip_distance > 10 then 1 else 0 end) as from_1_to_3_miles
from green_taxi_data
where
    green_taxi_data.lpep_dropoff_datetime::date
        between '2019-10-01'::date and '2019-10-31'::date
    and green_taxi_data.lpep_pickup_datetime::date
	    between '2019-10-01'::date and '2019-10-31'::date;
```
</details>

and got the following output:

```
104802	198924	109603	27678	35189
```

without restricting the pick-up and drop-off dates one gets a different answer:

```
104838	199013	109645	27688	35202
```

I think the question formulation is tricky and both answers should be accepted. ^_^

___

**PS**

We can see 
<details>
<summary>with these queries</summary>

```sql
select
	min(green_taxi_data.lpep_pickup_datetime)
	, max(green_taxi_data.lpep_pickup_datetime)
	, min(green_taxi_data.lpep_dropoff_datetime)
	, max(green_taxi_data.lpep_dropoff_datetime)
from green_taxi_data;
```
and
```sql
select
	date_trunc('month', green_taxi_data.lpep_pickup_datetime)::date as _month
	, count(1) as records
from green_taxi_data
group by _month;
```
</details>

that that both pick-up and drop-off dates in October file actually go beyond the stated month (and year), but only few records.

<details>

```
"min"	"max"	"min-2"	"max-2"
"2008-10-21 15:52:05"	"2019-11-13 08:46:52"	"2008-10-21 15:54:26"	"2019-11-13 08:58:26"
```

```
"_month"	"records"
"2009-01-01"	5
"2010-09-01"	3
"2019-11-01"	17
"2019-09-01"	3
"2008-10-01"	1
"2019-10-01"	476354
"2008-12-01"	3
```
</details>

___


## 4. Longest trip

<details>
<summary>With this query</summary>

```sql
select
	green_taxi_data.lpep_pickup_datetime::date
	, green_taxi_data.trip_distance
from green_taxi_data
order by green_taxi_data.trip_distance desc
limit 1;
```
</details>

we can see that it happened on October 31st, 2019:

```
"lpep_pickup_datetime"	"trip_distance"
"2019-10-31"	515.89
```


## 5. Three biggest pickup zones

<details>
<summary>This query</summary>

```sql
select
	taxi_zone_lookup."Zone"
	, sum(green_taxi_data.total_amount) as total_total_amount
from green_taxi_data
	left join taxi_zone_lookup
		on taxi_zone_lookup."LocationID" = green_taxi_data."PULocationID"
where green_taxi_data.lpep_pickup_datetime::date = '2019-10-18'::date
group by taxi_zone_lookup."Zone"
having sum(green_taxi_data.total_amount) > 13000;
```
</details>

gives us East Harlems North&South and Morningside Heights:

```
"Zone"	"total_total_amount"
"East Harlem North"	18686.680000000088
"East Harlem South"	16797.260000000068
"Morningside Heights"	13029.79000000003
```


## 6. Largest tip

<details>
<summary>This query</summary>

```sql
select
	picks."Zone" as pickup_zone
	, green_taxi_data.tip_amount as largest_tip_not_trip
	, drops."Zone" as dropout_zone
from green_taxi_data
	left join taxi_zone_lookup picks
		on picks."LocationID" = green_taxi_data."PULocationID"
	left join taxi_zone_lookup drops
		on drops."LocationID" = green_taxi_data."DOLocationID"
where picks."Zone" = 'East Harlem North'
	and date_trunc('month', green_taxi_data.lpep_pickup_datetime)::date = '2019-10-01'::date
order by green_taxi_data.tip_amount desc
limit 1;
```
</details>

shows that ride to JFK Airport was the ride with the biggest tip:

```
"pickup_zone"	"largest_tip_not_trip"	"dropout_zone"
"East Harlem North"	87.3	"JFK Airport"
```


## 7. Terraform workflow

As Michael Shoemaker explains in [this video at 9:55](https://youtu.be/s2bOYDCKl_M?si=tAkkSMQrfvzSY434&t=595) the commands to execute the following set of actions:

1. Downloading the provider plugins and setting up backend
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform

are

```sh
terraform init
terraform apply
terrraform destroy
```

To make it execute the plan without confirmation, we add the `-auto-approve` argument to the `terraform apply` command.
