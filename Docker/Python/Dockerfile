FROM python:3.8-slim


WORKDIR /app

COPY beam_consumer.py ./
COPY consume_write_table.py ./
COPY requirements.txt ./

RUN mkdir -p output
RUN apt-get update
RUN yes | apt-get install vim
RUN pip install -U --no-cache-dir -r requirements.txt

# CMD ["sh", "-c", "tail -f /dev/null"]
CMD [ "python", "consume_write_table.py" ]