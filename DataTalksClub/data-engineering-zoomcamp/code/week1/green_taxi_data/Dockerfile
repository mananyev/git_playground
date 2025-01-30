FROM python:3.12.8

RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2

WORKDIR /app
COPY ingest_data_green.py ingest_data_green.py 

ENTRYPOINT [ "python", "ingest_data_green.py" ]