# DTC data-engineering-zoomcamp HA2

## 1. Preparations

Run docker-compose files:

1. [this docker-compose file](../code/week2/docker-compose.yml) to launch Kestra.
2. [this file](../code/week2/postgres/docker-compose.yml) to launch pgadmin.

> Note that pgadmin's port 80 is forwarded to port 8088, so I checked the content on `localhost:8088`.

Following the lectures, I prepared two flows:

- [examples.postgres_taxi.yml](../code/week2/examples.postgres_taxi.yml) for manual selection of taxi/year/month (and a disabled `purge_files` task to keep the `.CSV` files in the outputs), and
- [examples.postgres_taxi_scheduled.yml](../code/week2/examples.postgres_taxi_scheduled.yml) for scheduled updates/backfill.


## 1. Quiz Questions

### 1.1 File size

1. Ran the `postgres_taxi` flow with `taxi: yellow`, `year: 2020`, and `month: 12` inputs.
2. In the `Outputs > extract > outputFiles` is `yellow_tripdata_2020-12.csv` file which shows the size of

`(128.3 MiB)`.

### 1.2 Rendered `file`

We simply substitute inputs variables in double curly brackets in the `file` expression and get

`green_tripdata_2020-04.csv`.

> Note, that other answers can be eliminated without subsituting:
>
> 1. can be eliminated because we are asked about the *rendered* value,
> 2. is the right answer,
> 3. can be eliminated because there is no dash, `-`,
> 4. can be eliminated because there is no month, `04`.

### 1.3 Yellow Taxi data rows in 2020

May be a clumsy solution, but what I did was:

1. truncate/drop all the tables from postgres
2. launch backfill for the `yellow_schedule` trigger for `examples.postgres_taxi_scheduled.yml` flow with starting timestamp `2020-01-01 00:00:00` and ending timestamp `2020-12-02 00:00:00` (because we care only about the first day of month in the schedule) and `taxi: yellow` parameter because I don't know why it's not working without pre-defined inputs..
3. in pgadmin (`localhost:8088`) I right-clicked on the `yellow_tripdata` table and selected `Count Rows` option, which gives me

`Table rows counted: 24648499`.

### 1.4 Green Taxi data rows in 2020

Similar to the point 1.3 above, I launch backfill for the `green_schedule` trigger for `examples.postgres_taxi_scheduled.yml` flow with the same time period as above and `taxi: green`, and check the number of rows in `green_tripdata` table, which gives me

`Table rows counted: 1734051`.

### 1.5 Yellow Taxi data rows for the March 2021 file

Back to `examples.postgres_taxi.yml`:

1. Ran it with `taxi: yellow`, `year: 2021`, and `month: 03` inputs.
2. Navigate to `Outputs > yellow_copy_into_staging_table` (don't even need to go to pgadmin), which gives

`rowCount   1925152`.

### 1.6 Set Schedule trigger to New York timezone

The [documentation](https://kestra.io/plugins/trigger/triggers/io.kestra.plugin.core.trigger.schedule) for `Schedule` says:

> "The [time zone identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) (i.e. the second column in [the Wikipedia table](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)) to use for evaluating the cron expression. Default value is the server default zone ID."

Second row in that table on a Wiki page states that TZ identifier comes in a form of `%COUNTRY/CITY%`, therefore, the answer is

- add a `timezone` property set to `America/New_York` in the `Schedule` trigger configuration.
