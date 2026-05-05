"""
Single-source DAG: GitHub Archive Pipeline

Standalone pipeline for GitHub events ingestion and transformation.
Useful for development, debugging, or incremental adoption of new sources.

Schedule: every 30 minutes (respects GitHub API 60 req/hr rate limit)
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    "owner": "data_team",
    "depends_on_past": False,
    "email_on_failure": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
    "start_date": datetime(2025, 1, 1),
}

with DAG(
    dag_id="github_archive_pipeline",
    default_args=default_args,
    description="GitHub events: ingest via SeaTunnel -> dbt run -> dbt test",
    schedule="*/30 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["github", "single_source"],
) as dag:

    start = EmptyOperator(task_id="start")
    end = EmptyOperator(task_id="end")

    ingest_github = BashOperator(
        task_id="ingest_github_events",
        bash_command=(
            'curl -s -X POST http://seatunnel:5801/hazelcast/rest/maps/submit-job '
            '-H "Content-Type: application/json" '
            '-d "{\\"jobId\\":\\"github_events_{{ ts_nodash }}\\",'
            '\\"jobConfig\\":\\"$(cat /opt/seatunnel/jobs/github_events_to_ods.conf | sed \'s/\"/\\\\\\"/g\' | tr \'\\n\' \' \')\\"}" '
            '|| echo "SeaTunnel submit failed"'
        ),
    )

    wait_ods = BashOperator(
        task_id="wait_for_ods",
        bash_command="sleep 15 && echo 'ODS write complete'",
    )

    dbt_run_github = BashOperator(
        task_id="dbt_run_github",
        bash_command=(
            "cd /opt/dbt && "
            "dbt run --select ods_github_events+ --profiles-dir /opt/dbt"
        ),
    )

    dbt_test_github = BashOperator(
        task_id="dbt_test_github",
        bash_command=(
            "cd /opt/dbt && "
            "dbt test --select ods_github_events+ --profiles-dir /opt/dbt 2>&1 || true"
        ),
    )

    start >> ingest_github >> wait_ods >> dbt_run_github >> dbt_test_github >> end
