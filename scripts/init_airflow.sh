#!/bin/bash
set -e

airflow db migrate

airflow users create \
    --username "${AIRFLOW_ADMIN_USER:-admin}" \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password "${AIRFLOW_ADMIN_PASSWORD:-admin}"

echo "Airflow initialized. Admin user: ${AIRFLOW_ADMIN_USER:-admin}"
