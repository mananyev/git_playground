FROM python:3.12.8

RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2

WORKDIR /app
COPY ingest_zones.py ingest_zones.py 

ENTRYPOINT [ "python", "ingest_zones.py" ]