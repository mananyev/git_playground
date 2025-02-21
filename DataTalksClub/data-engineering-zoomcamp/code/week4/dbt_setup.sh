# use adjusted `Docker` (added pytz) and `docker-compose.yml` (GCP credentials json) files
docker-compose build  # to build
# create ~/.dbt/profiles.yml empty file
docker-compose run dbt-bq-dtc init  # to initialize profiles
# you will be asked how to name things
# BUT also dataset and project ID - this is required to connect
# test connection with
docker-compose run --workdir="//usr/app/dbt/taxi_rides_ny" dbt-bq-dtc debug
