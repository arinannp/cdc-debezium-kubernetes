import os
import json
import logging

from kafka import KafkaConsumer
from datetime import datetime
from sqlalchemy import create_engine, table, column
from sqlalchemy.dialects.postgresql import insert


logging.getLogger().setLevel(logging.INFO)
logging.basicConfig(format='%(asctime)s,%(msecs)d %(levelname)-8s [%(filename)s:%(lineno)d] %(message)s',
                    datefmt='%Y-%m-%d:%H:%M:%S',
                    level=logging.INFO)

logging.info('Starting...')


BOOTSTRAP_SERVER = os.getenv('BOOTSTRAP_SERVER')
TOPIC_NAME = os.getenv('TOPIC_NAME')

POSTGRES_USER = os.getenv('POSTGRES_USER')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD')
POSTGRES_DB = os.getenv('POSTGRES_DB')
POSTGRES_HOST = os.getenv('POSTGRES_HOST')
TABLE_DEST = os.getenv('TABLE_DEST')
CONNECTION_STRING = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}/{POSTGRES_DB}"
logging.info("Connection string: " + CONNECTION_STRING)


TABLE_NAME_WITH_ATTR = table(TABLE_DEST, 
          column("id"), column("login_date"), column("first_name"),
          column("last_name"), column("address"), column("active"),
          column("previous_data"), column("operation"), column("ts_ms"),
          )


    

consumer = KafkaConsumer(TOPIC_NAME, bootstrap_servers=BOOTSTRAP_SERVER, 
                                value_deserializer=lambda m: json.loads(m.decode('utf-8')), 
                                api_version=(0,10,2)
                        )

def write_changes_data(element, table_name, connection_engine):
    insert_stmt = insert(table_name).values(element)
    connection_engine.execute(insert_stmt)
    logging.info(f"Data Success Inserted: {str(element)} --- Type: {type(element)}")



kafka_message = []
try:
    engine = create_engine(CONNECTION_STRING)
    conn = engine.connect()
    connect_status = True
    logging.info("Success connect to postgres database...")
except Exception as e:
    connect_status = False
    logging.info("Cant connect to postgres database --- Error: " + str(e))


with open("output/out_kafka_cdc.txt", "a") as file:
    for message in consumer:
        logging.info(f"Data Raw: {str(message.value)} --- Type: {type(message.value)}")
        kafka_message.append(message.value)
        file.write(f"{message.value}\n")

        clean_data = {}
        raw_data = message.value

        clean_data['id'] = raw_data['payload']['after']['id']
        login_date = raw_data['payload']['after']['login_date'] * (3600 * 24) #hour * day
        clean_data['login_date'] = datetime.utcfromtimestamp(login_date).strftime('%Y-%m-%d')
        clean_data['first_name'] = raw_data['payload']['after']['first_name']
        clean_data['last_name'] = raw_data['payload']['after']['last_name']
        clean_data['address'] = raw_data['payload']['after']['address']
        clean_data['active'] = raw_data['payload']['after']['active']
        clean_data['previous_data'] = json.dumps(raw_data['payload']['before']) if raw_data['payload']['before'] != None else None
        clean_data['operation'] = raw_data['payload']['op']
        clean_data['ts_ms'] = raw_data['payload']['ts_ms']
        logging.info(f"Data Clean: {str(clean_data)} --- Type: {type(clean_data)}")
        
        if connect_status:
            write_changes_data(element=clean_data, table_name=TABLE_NAME_WITH_ATTR, connection_engine=conn)


if connect_status:
    conn.close()
    connect_status = False