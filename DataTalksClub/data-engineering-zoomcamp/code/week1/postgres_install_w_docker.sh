# docker
# navigate to the `green_taxi_data` folder and run
docker build -t taxi_ingest:v002 .
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz"
docker run -it \
    --network=week1_default \
    taxi_ingest:v002 \
        --user=root \
        --password=root \
        --host=pgdatabase \
        --port=5432 \
        --db=ny_taxi \
        --table_name=green_taxi_data \
        --url=${URL}

# finally, navigate to the `zones_data` folder
# (where my `ingest_zones.py`` file is located - it does not have that loop for loading data in chunks)
docker build -t taxi_ingest:v003 .
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv"
docker run -it \
    --network=week1_default \
    taxi_ingest:v003 \
        --user=root \
        --password=root \
        --host=pgdatabase \
        --port=5432 \
        --db=ny_taxi \
        --table_name=taxi_zone_lookup \
        --url=${URL}

# Terraform
# code skipped in this HA
