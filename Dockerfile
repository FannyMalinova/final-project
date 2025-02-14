FROM python:3.13.2-slim

RUN apt-get update \
    && apt-get install -y postgresql-client \
    &&  apt-get install -y curl \
    && mkdir /app

WORKDIR /app

COPY src/requirements.txt /app/
RUN pip install -r requirements.txt

COPY src /app

RUN chmod +x ./wait-for-postgres.sh

ENV FLASK_APP=app.py

CMD ["./wait-for-postgres.sh", "flask", "run", "--host=0.0.0.0"]