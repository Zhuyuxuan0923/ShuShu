"""
Row count fluctuation monitor.

Compares today's table row counts against yesterday's snapshot across all
four data warehouse layers (ODS/DWD/DWS/ADS).  Sends WeCom / DingTalk alerts
when any table has deviated more than 30 % from the previous day.
"""
import os
from datetime import date, datetime, timedelta

import psycopg2
from psycopg2 import sql

from webhook_notifier import send_wecom_markdown, send_dingtalk_markdown

SCHEMAS = ["ods", "dwd", "dws", "ads"]
THRESHOLD_PCT = 30.0
PG_HOST = os.getenv("DBT_HOST", "postgres")
PG_USER = os.getenv("POSTGRES_USER", "dw_admin")
PG_PASSWORD = os.getenv("POSTGRES_PASSWORD", "dw_secure_pwd_2025")
PG_DB = os.getenv("POSTGRES_DW_DB", "data_warehouse")


def _get_connection():
    return psycopg2.connect(
        host=PG_HOST, user=PG_USER, password=PG_PASSWORD, dbname=PG_DB
    )


def monitor_row_counts(**context):
    """Airflow PythonOperator callable.

    Queries current row counts for every table in ods/dwd/dws/ads,
    diffs against yesterday's snapshot, and alerts on >30 % change.
    """
    conn = _get_connection()
    today = date.today()
    yesterday = today - timedelta(days=1)

    alerts = []
    snapshots = []

    try:
        with conn.cursor() as cur:
            # -- gather today's counts --
            cur.execute(
                """
                SELECT table_schema, table_name
                FROM information_schema.tables
                WHERE table_schema = ANY(%s)
                  AND table_type = 'BASE TABLE'
                ORDER BY table_schema, table_name
                """,
                (SCHEMAS,),
            )
            tables = cur.fetchall()

            for schema_name, table_name in tables:
                cur.execute(
                    sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
                        sql.Identifier(schema_name),
                        sql.Identifier(table_name),
                    )
                )
                row = cur.fetchone()
                today_count = row[0] if row else 0
                snapshots.append((today, schema_name, table_name, today_count))

            # -- fetch yesterday's snapshot --
            cur.execute(
                """
                SELECT schema_name, table_name, row_count
                FROM dws.row_count_snapshot
                WHERE snapshot_date = %s
                """,
                (yesterday,),
            )
            yesterday_map = {
                (r[0], r[1]): r[2] for r in cur.fetchall()
            }

            # -- diff --
            for snap_date, schema, table, today_count in snapshots:
                yesterday_count = yesterday_map.get((schema, table))
                if yesterday_count is None:
                    continue  # first run, no baseline
                if yesterday_count == 0:
                    pct = 100.0 if today_count > 0 else 0.0
                else:
                    pct = abs(today_count - yesterday_count) / yesterday_count * 100
                if pct > THRESHOLD_PCT:
                    direction = "+" if today_count > yesterday_count else "-"
                    alerts.append(
                        f"| {schema}.{table} | {yesterday_count} | {today_count} "
                        f"| {direction}{pct:.1f}% |"
                    )

            # -- persist today's snapshot (upsert) --
            for snapshot_date, schema, table, cnt in snapshots:
                cur.execute(
                    """
                    INSERT INTO dws.row_count_snapshot (snapshot_date, schema_name, table_name, row_count)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (snapshot_date, schema_name, table_name)
                    DO UPDATE SET row_count = EXCLUDED.row_count
                    """,
                    (snapshot_date, schema, table, cnt),
                )

        conn.commit()
    finally:
        conn.close()

    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")

    if alerts:
        header = (
            f"**Row Count Fluctuation Alert**\n"
            f"**DAG**: data_warehouse_full_pipeline\n"
            f"**Time**: {timestamp}\n"
            f"> Threshold: >{THRESHOLD_PCT:.0f}% change vs yesterday\n\n"
        )
        table_header = (
            "| Table | Yesterday | Today | Change |\n"
            "| :--- | ---: | ---: | :---: |\n"
        )
        content = header + table_header + "\n".join(alerts)

        title = "Row Count Alert - FLUCTUATION DETECTED"
        send_wecom_markdown(title, content)
        send_dingtalk_markdown(title, content)
        print(f"[row_count_monitor] Alert: {len(alerts)} table(s) fluctuated >{THRESHOLD_PCT:.0f}%")
    else:
        print("[row_count_monitor] All tables within normal range")

    print(f"[row_count_monitor] Snapshot saved: {len(snapshots)} tables")
