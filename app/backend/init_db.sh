#!/bin/bash
set -e

until psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - executing commands"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS vector;"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  message TEXT NOT NULL,
  response TEXT NOT NULL,
  embedding VECTOR(384)
);"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password TEXT NOT NULL
);"

exec "$@"
