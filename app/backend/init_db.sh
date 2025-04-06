#!/bin/bash
set -e

until psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - executing commands"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS vector;"
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "CREATE TABLE messages (id SERIAL PRIMARY KEY, message TEXT NOT NULL, response TEXT NOT NULL, embedding VECTOR(384));"

exec "$@"