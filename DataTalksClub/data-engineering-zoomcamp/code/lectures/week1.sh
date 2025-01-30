# Docker

# there were some steps for installing Docker Desktop for Windows
# and setting up WSL.
# I got confused at first because I tried to use git-bash (MINGW64),
# similar to Alexey,
# but I learned that some things should be done in WSL differently from what
# Alexey showed in lectures (he used git-bash as well).
# In the end I set up Terminal for Windows with both git-bash and WSL.

docker run hello-world

docker run --entrypoint=bash -it python:3.12.8
pip install pandas

# setting up the postgres db

docker run -it \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v "$(pwd)/data-engineering-zoomcamp/week_1_basics_n_setup/2_docker_sql/ny_taxi_postgres_data:/var/lib/postgresql/data" \
    -p 5432:5432 \
    postgres:13

# check the content with pgcli

pgcli -h localhost -p 5432 -u root -d ny_taxi
# honestly, can skip..
# there is more confusion with pgcli than real help with understanding what's going on

# pgadmin

docker run -it \
    -e PGADMIN_DEFAULT_EMAIL=’admin@admin.com’ \
    -e PGADMIN_DEFAULT_PASSWORD=’root’ \
    -p 8080:80 \
    dpage/pgadmin4

# in order to get access from pgadmin to postgres, make them run in the same network

docker network create pg-network

docker run -it \
    -e POSTGRES_USER=”root” \
    -e POSTGRES_PASSWORD=”root” \
    -e POSTGRES_DB=”ny_taxi” \
    -v "$(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data:z" \
    -p 5432:5432 \
    --network=pg-network \
    --name=pg-database \
    postgres:13

docker run -it \
    -e PGADMIN_DEFAULT_EMAIL='admin@admin.com' \
    -e PGADMIN_DEFAULT_PASSWORD='root' \
    -p 8080:80 \
    --network=pg-network \
    --name=pgadmin \
    dpage/pgadmin4

# if need to remove the container: docker container rm pg-database
# to list all the containers running: docker ps

# ingest data using a Python script
# first, need to create the .py script and describe in Dockerfile
docker build -t taxi_ingest:v001 .

URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"
docker run -it \
    --network=2_docker_sql_default \
    taxi_ingest:v001 \
        --user=root \
        --password=root \
        --host=pgdatabase \
        --port=5432 \
        --db=ny_taxi \
        --table_name=yellow_taxi_data \
        --url=${URL}

# same for green trip data and zones (I made separate files)
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz"
docker run -it \
    --network=2_docker_sql_default \
    taxi_ingest:v002 \
        --user=root \
        --password=root \
        --host=pgdatabase \
        --port=5432 \
        --db=ny_taxi \
        --table_name=green_taxi_data \
        --url=${URL}

URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv"
docker run -it \
    --network=2_docker_sql_default \
    taxi_ingest:v003 \
        --user=root \
        --password=root \
        --host=pgdatabase \
        --port=5432 \
        --db=ny_taxi \
        --table_name=taxi_zone_lookup \
        --url=${URL}



# GCP setup

ssh-keygen -t rsa -f PATH_TO_FILE -C YOUR_USER -b 2048
# I have the file stored in `~/gcp`
# add public key to instance keys

# create/update config file
Host de-zoomcamp
  HostName VM_EXTERNAL_IP  # this IP has to be updated every time you launch VM
  User m1sk0
  IdentityFile ~/.ssh/gcp

# ssh into the instance
wget https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh
bash Anaconda3-2024.10-1-Linux-x86_64.sh
# select "yes" to activate base environment
# or
cd YOUR_PATH_ANACONDA/bin  # most likely `~/anaconda3/bin`
./conda init bash

sudo apt-get update
sudo apt-get install docker.io

# make docker run without sudo
sudo groupadd docker
sudo gpasswd -a $USER docker

# LOG OUT AND LOG BACK IN!
sudo service docker restart

# test
docker run hello-world

# download docker-compose
mkdir ~/bin
cd ~/bin
wget https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-x86_64 -O docker-compose
chmod +x docker-compose

# test
./docker-compose version

# add path to docker-compose
nano .bashrc
# go to the end
export PATH="${HOME}/bin:{$PATH}"

# clone zoomcamp repo
# navigate to the week 1 folder (where `docker-compose.yaml` file is located)
docker-compose up -d
# can use pgcli
pgcli -h localhost -U root -d ny_taxi

# to avoid errors, install with conda
pip uninstall pgcli  # if installed with pip
conda install -c conda-forge pgcli
pip install -U mycli

# using terraform on GCP
# terraform is already installed but we need our service account credentials
# creds are stored in a `.json` file in `~/.gc/` folder.
# Navigate to that folder
cd ~/.gc
# and copy that file to VM using:
sftp de-zoomcamp
# this will ssh you to the VM
# navigate to the folder `~/.gc` (create if needed with mkdir `~/.gc`)
put YOUR_SERVICE_FILE



# Terraform

terraform fmt  # to auto-format your .tf files
# to use browser to authenticate your account use `gcloud default auth-login`
# to use your credentials file from service account, use
export GOOGLE_CREDENTIALS='/home/gary/terrademo/keys/my-creds.json'  # this is the file name Michael used
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS

# navigate to the folder with your `main.tf` file
# NOTE: don't forget to put project name where needed
terraform init  # to initialize the planner
terraform plan  # to see what is to be created
terraform apply  # to create resources
terraform destroy  # to kill the resources
