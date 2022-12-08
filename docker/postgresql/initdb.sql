CREATE TABLE person_identity (
   id           SERIAL PRIMARY KEY,
   login_date   DATE,
   first_name   VARCHAR(30),
   last_name    VARCHAR(30),
   address      VARCHAR(255),
   active       BOOLEAN
);

CREATE TABLE person_identity_captured (
   id             INTEGER,
   login_date     DATE,
   first_name     VARCHAR(30),
   last_name      VARCHAR(30),
   address        VARCHAR(255),
   active         BOOLEAN,
   previous_data  TEXT,
   operation      VARCHAR(15),
   ts_ms          FLOAT
);

ALTER SYSTEM SET wal_level TO 'logical';
ALTER TABLE person_identity REPLICA IDENTITY FULL;