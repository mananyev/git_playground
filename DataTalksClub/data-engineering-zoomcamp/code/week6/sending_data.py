import json
from time import time
from kafka import KafkaProducer
import pandas as pd

def json_serializer(data):
    return json.dumps(data).encode('utf-8')

server = 'localhost:9092'
topic_name = 'green-taxi'

producer = KafkaProducer(
    bootstrap_servers=[server],
    value_serializer=json_serializer
)

t0 = time()
data = pd.read_csv(
    (
        "~/data-engineering-zoomcamp/"
        +"06-streaming/pyflink/tmp/"
        +"green_tripdata_2019-10.csv.gz"
    ),
    low_memory=False
)
data = data[[
    'lpep_pickup_datetime',
    'lpep_dropoff_datetime',
    'PULocationID',
    'DOLocationID',
    'passenger_count',
    'trip_distance',
    'tip_amount'
]]
for index, message in data.iterrows():
    # print(index, message.to_json())
    producer.send(topic_name, value=message.to_json())
    # print(f"Sent: {message.to_json()}")

producer.flush()

t1 = time()
print(f'took {(t1 - t0):.2f} seconds')
