import os
import json
import logging

from kafka import KafkaConsumer

import apache_beam as beam
from apache_beam.io import WriteToText
import apache_beam.transforms.window as window
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.io.external.kafka import ReadFromKafka, WriteToKafka



BOOTSTRAP_SERVER = os.getenv('BOOTSTRAP_SERVER')
TOPIC_NAME = os.getenv('TOPIC_NAME')



def kafka_consumer(unused_element, topic_name, bootstrap_server):
  consumer = KafkaConsumer(topic_name, bootstrap_servers=bootstrap_server, value_deserializer=lambda m: json.loads(m.decode('utf-8')), api_version=(0,10,2))

  for message in consumer:
      logging.info(f"Data: {str(message.value)} --- Type: {type(message.value)}")
      return message.value




def run():
  p = beam.Pipeline(options=PipelineOptions(streaming=True)) #local

  # read_and_clean_cdc_data = (p
  #       | 'Read from Kafka' >> ReadFromKafka(consumer_config={'bootstrap.servers': BOOTSTRAP_SERVER,
  #                                                          'auto.offset.reset': 'latest'},
  #                                           topics=[TOPIC_NAME])
  #       | 'Print out 1' >> beam.Map(print)
  #       | 'Par with 1' >> beam.Map(lambda word: (word, 1))
  #       | 'Print out 2' >> beam.Map(print)
  #       | 'Window of 10 seconds' >> beam.WindowInto(window.FixedWindows(10))
  #       | 'Group by key' >> beam.GroupByKey()
  #       | 'Print out 3' >> beam.Map(print)
  #       | 'Sum word counts' >> beam.Map(lambda kv: (kv[0], sum(kv[1])))
  #       | 'Print out 4' >> beam.Map(print)
  #       | 'Write to Kafka' >> WriteToKafka(producer_config={'bootstrap.servers': BOOTSTRAP_SERVER},
  #                                         topic='my-topic')
  # )

  read_and_clean_cdc_data = (p
        | 'Init Read from Kafka' >> beam.Create(["Initialization data"])
        | 'Read from Kafka' >> beam.Map(kafka_consumer, topic_name=TOPIC_NAME, bootstrap_server=BOOTSTRAP_SERVER)
        | 'Print out 1' >> beam.Map(print)
        | 'Window of 10 seconds' >> beam.WindowInto(window.FixedWindows(10))
        | "Write Kafka Message" >> WriteToText(file_path_prefix="output/out_kafka", file_name_suffix=".txt")
  )


  # read_and_clean_cdc_data | "Write Kafka Message" >> WriteToText(file_path_prefix="output/out_kafka", file_name_suffix=".txt")

  
  result = p.run()
  result.wait_until_finish()




if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  logging.basicConfig(format='%(asctime)s,%(msecs)d %(levelname)-8s [%(filename)s:%(lineno)d] %(message)s',
                      datefmt='%Y-%m-%d:%H:%M:%S',
                      level=logging.INFO)
              
  logging.info('Starting...')
  run()