"""
Master DAG: Enterprise Data Warehouse Full Pipeline

Orchestrates the complete data pipeline:
1. Check source freshness (dbt source freshness)
2. Ingest data from 4 sources (3 external APIs + 1 business DB) via SeaTunnel (parallel)
3. Run dbt models (ODS -> DWD -> DWS -> ADS)
4. Run dbt tests
5. Monitor row count fluctuation (>30% alert)
6. Notify results to WeCom/DingTalk

Schedule: daily at 07:00 UTC
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

from webhook_notifier import notify_data_quality_results
from row_count_monitor import monitor_row_counts

default_args = {
    "owner": "data_team",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "start_date": datetime(2025, 1, 1),
}

with DAG(
    dag_id="data_warehouse_full_pipeline",
    default_args=default_args,
    description="Full data warehouse pipeline: ingest -> transform -> test -> alert",
    schedule="0 7 * * *",
    catchup=False,
    max_active_runs=1,
    tags=["production", "full_pipeline"],
) as dag:

    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    # --- Source Freshness ---
    check_source_freshness = BashOperator(
        task_id="check_source_freshness",
        bash_command="cd /opt/dbt && dbt source freshness --profiles-dir /opt/dbt 2>&1 || true",
    )

    # --- Ingestion (6 parallel SeaTunnel jobs) ---
    with TaskGroup("ingest_all", tooltip="Ingest data from 4 sources (3 HTTP + 1 JDBC) via SeaTunnel") as ingest_all:

        ingest_github = BashOperator(
            task_id="ingest_github_events",
            bash_command=(
                'curl -s -X POST http://seatunnel:5801/hazelcast/rest/maps/submit-job '
                '-H "Content-Type: application/json" '
                '-d "{\\"jobId\\":\\"github_events_{{ ds_nodash }}\\",'
                '\\"jobConfig\\":\\"$(cat /opt/seatunnel/jobs/github_events_to_ods.conf | sed \'s/\"/\\\\\\"/g\' | tr \'\\n\' \' \')\\"}" '
                '|| echo "SeaTunnel submit failed"'
            ),
        )

        ingest_weather = BashOperator(
            task_id="ingest_weather_forecast",
            bash_command=(
                'curl -s -X POST http://seatunnel:5801/hazelcast/rest/maps/submit-job '
                '-H "Content-Type: application/json" '
                '-d "{\\"jobId\\":\\"weather_forecast_{{ ds_nodash }}\\",'
                '\\"jobConfig\\":\\"$(cat /opt/seatunnel/jobs/weather_forecast_to_ods.conf | sed \'s/\"/\\\\\\"/g\' | tr \'\\n\' \' \')\\"}" '
                '|| echo "SeaTunnel submit failed"'
            ),
        )

        ingest_ecommerce = BashOperator(
            task_id="ingest_ecommerce_products",
            bash_command=(
                'curl -s -X POST http://seatunnel:5801/hazelcast/rest/maps/submit-job '
                '-H "Content-Type: application/json" '
                '-d "{\\"jobId\\":\\"ecommerce_products_{{ ds_nodash }}\\",'
                '\\"jobConfig\\":\\"$(cat /opt/seatunnel/jobs/ecommerce_products_to_ods.conf | sed \'s/\"/\\\\\\"/g\' | tr \'\\n\' \' \')\\"}" '
                '|| echo "SeaTunnel submit failed"'
            ),
        )

        ingest_business_customers = BashOperator(
            task_id="ingest_business_customers",
            bash_command=(
                'curl -s -X POST http://seatunnel:5801/hazelcast/rest/maps/submit-job '
                '-H "Content-Type: application/json" '
                '-d "{\\"jobId\\":\\"business_customers_{{ ds_nodash }}\\",'
                '\\"jobConfig\\":\\"$(cat /opt/seatunnel/jobs/business_customers_to_ods.conf | sed \'s/\"/\\\\\\"/g\' | tr \'\\n\' \' \')\\"}" '
                '|| echo "SeaTunnel submit failed"'
            ),
        )

        ingest_business_orders = BashOperator(
            task_id="ingest_business_orders",
            bash_command=(
                'curl -s -X POST http://seatunnel:5801/hazelcast/rest/maps/submit-job '
                '-H "Content-Type: application/json" '
                '-d "{\\"jobId\\":\\"business_orders_{{ ds_nodash }}\\",'
                '\\"jobConfig\\":\\"$(cat /opt/seatunnel/jobs/business_orders_to_ods.conf | sed \'s/\"/\\\\\\"/g\' | tr \'\\n\' \' \')\\"}" '
                '|| echo "SeaTunnel submit failed"'
            ),
        )

        ingest_business_order_items = BashOperator(
            task_id="ingest_business_order_items",
            bash_command=(
                'curl -s -X POST http://seatunnel:5801/hazelcast/rest/maps/submit-job '
                '-H "Content-Type: application/json" '
                '-d "{\\"jobId\\":\\"business_order_items_{{ ds_nodash }}\\",'
                '\\"jobConfig\\":\\"$(cat /opt/seatunnel/jobs/business_order_items_to_ods.conf | sed \'s/\"/\\\\\\"/g\' | tr \'\\n\' \' \')\\"}" '
                '|| echo "SeaTunnel submit failed"'
            ),
        )

        wait_for_ingestion = BashOperator(
            task_id="wait_for_ingestion",
            bash_command="sleep 30 && echo 'Ingestion wait complete'",
        )

        [ingest_github, ingest_weather, ingest_ecommerce,
         ingest_business_customers, ingest_business_orders, ingest_business_order_items] >> wait_for_ingestion

    # --- dbt Transformations ---
    with TaskGroup("transform", tooltip="Run dbt models and tests") as transform:

        dbt_seed = BashOperator(
            task_id="dbt_seed",
            bash_command="cd /opt/dbt && dbt seed --profiles-dir /opt/dbt",
            retries=0,
        )

        dbt_run = BashOperator(
            task_id="dbt_run",
            bash_command="cd /opt/dbt && dbt run --profiles-dir /opt/dbt",
            retries=0,
        )

        dbt_test = BashOperator(
            task_id="dbt_test",
            bash_command="cd /opt/dbt && dbt test --profiles-dir /opt/dbt 2>&1 || true",
            retries=0,
        )

        dbt_docs = BashOperator(
            task_id="dbt_docs_generate",
            bash_command="cd /opt/dbt && dbt docs generate --profiles-dir /opt/dbt",
            retries=0,
        )

        dbt_seed >> dbt_run >> dbt_test >> dbt_docs

    # --- Row Count Monitoring ---
    monitor_row_count = PythonOperator(
        task_id="monitor_row_count",
        python_callable=monitor_row_counts,
    )

    # --- Alerting ---
    notify_quality = PythonOperator(
        task_id="notify_data_quality",
        python_callable=notify_data_quality_results,
        op_kwargs={},
    )

    # --- DAG Structure ---
    start >> check_source_freshness >> ingest_all >> transform
    transform >> monitor_row_count >> notify_quality >> end
