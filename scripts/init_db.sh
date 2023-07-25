#!/usr/bin/env bash
set -x
set -eo pipefail

if ! [ -x "$(command -v sqlx)" ]; then
  echo 'Error: sqlx is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v psql)" ]; then
  echo 'Error: psql is not installed.' >&2
  exit 1
fi

DB_USER="${ZERO2PROD_DB_USER:=postgres}"
DB_PASSWORD="${ZERO2PROD_DB_PASSWORD:=postgres}"
DB_NAME="${ZERO2PROD_DB_NAME:=newsletter}"
DB_PORT="${ZERO2PROD_DB_PORT:=5432}"
DB_HOST="${ZERO2PROD_DB_HOST:=localhost}"

if [[ -z "${SKIP_DOCKER}" ]]
then
  docker run \
    -e POSTGRES_USER=${DB_USER} \
    -e POSTGRES_PASSWORD=${DB_PASSWORD} \
    -e POSTGRES_DB=${DB_NAME} \
    -p ${DB_PORT}:5432 \
    -d postgres \
    postgres -N 1000
fi

until nc -z "${DB_HOST}" "${DB_PORT}"; do
  >&2 echo "Postgres is still unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is available on port ${DB_PORT} - continuing..."

DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
export DATABASE_URL

sqlx database create
sqlx migrate run

>&2 echo "Postgres ready!"
