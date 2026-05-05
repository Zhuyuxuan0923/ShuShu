#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE airflow;
    CREATE DATABASE data_warehouse;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d data_warehouse <<-EOSQL
    CREATE SCHEMA IF NOT EXISTS ods;
    CREATE SCHEMA IF NOT EXISTS dwd;
    CREATE SCHEMA IF NOT EXISTS dws;
    CREATE SCHEMA IF NOT EXISTS ads;
    CREATE SCHEMA IF NOT EXISTS stage;

    COMMENT ON SCHEMA ods IS 'Operational Data Store -- raw ingested data, 1:1 with source';
    COMMENT ON SCHEMA dwd IS 'Data Warehouse Detail -- cleansed, deduped, standardized';
    COMMENT ON SCHEMA dws IS 'Data Warehouse Service -- aggregated metrics';
    COMMENT ON SCHEMA ads IS 'Application Data Service -- business KPIs and reports';
    COMMENT ON SCHEMA stage IS 'Staging area for intermediate transformations';

    CREATE TABLE IF NOT EXISTS dws.row_count_snapshot (
        snapshot_date DATE NOT NULL,
        schema_name  TEXT NOT NULL,
        table_name   TEXT NOT NULL,
        row_count    BIGINT NOT NULL,
        PRIMARY KEY (snapshot_date, schema_name, table_name)
    );
    COMMENT ON TABLE dws.row_count_snapshot IS 'Daily row count snapshots for fluctuation monitoring';
EOSQL
