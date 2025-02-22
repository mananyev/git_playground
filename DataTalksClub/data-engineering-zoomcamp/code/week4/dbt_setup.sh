# use adjusted `Docker` (added pytz) and `docker-compose.yml` (GCP credentials json) files
docker-compose build  # to build
# create ~/.dbt/profiles.yml empty file
docker-compose run dbt-bq-dtc init  # to initialize profiles
# you will be asked how to name things
# BUT also dataset and project ID - this is required to connect
# test connection with
docker-compose run --workdir="//usr/app/dbt/taxi_rides_ny" dbt-bq-dtc debug

# after adding a .csv file to the seeds folder run
docker-compose run --workdir="//usr/app/dbt/taxi_rides_ny" dbt-bq-dtc seed
# this will upload the .csv files from the folder to BQ
# finally, to build fact_trips and all the dependancies, run
docker-compose run --remove-orphans --workdir="//usr/app/dbt/taxi_rides_ny" dbt-bq-dtc build --select +fact_trips
