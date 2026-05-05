"""
Data quality alert plugin for WeCom (企业微信) and DingTalk (钉钉).

Reads dbt test artifacts (target/run_results.json), builds a summary table,
and posts Markdown notifications to configured webhook URLs.
"""
import json
import os
from datetime import datetime

import requests

WECOM_URL = os.getenv("WECOM_WEBHOOK_URL", "")
DINGTALK_URL = os.getenv("DINGTALK_WEBHOOK_URL", "")


def _build_result_table(failures: list, max_rows: int = 20) -> str:
    header = "| Test | Model | Column | Message |\n| :--- | :--- | :--- | :--- |\n"
    rows = []
    for f in failures[:max_rows]:
        msg = f.get("message", "-")[:80].replace("\n", " ").replace("|", "\\|")
        rows.append(
            f"| {f.get('test', '-')} | {f.get('model', '-')} "
            f"| {f.get('column', '-')} | {msg} |"
        )
    return header + "\n".join(rows)


def send_wecom_markdown(title: str, content: str):
    if not WECOM_URL:
        print("[webhook] WECOM_WEBHOOK_URL not configured, skipping")
        return
    payload = {"msgtype": "markdown", "markdown": {"content": f"## {title}\n{content}"}}
    try:
        r = requests.post(WECOM_URL, json=payload, timeout=10)
        print(f"[webhook] WeCom response: {r.status_code}")
    except requests.RequestException as e:
        print(f"[webhook] WeCom send failed: {e}")


def send_dingtalk_markdown(title: str, content: str):
    if not DINGTALK_URL:
        print("[webhook] DINGTALK_WEBHOOK_URL not configured, skipping")
        return
    payload = {"msgtype": "markdown", "markdown": {"title": title, "text": content}}
    try:
        r = requests.post(DINGTALK_URL, json=payload, timeout=10)
        print(f"[webhook] DingTalk response: {r.status_code}")
    except requests.RequestException as e:
        print(f"[webhook] DingTalk send failed: {e}")


def notify_data_quality_results(**context):
    """
    Airflow PythonOperator callable.

    Reads dbt run_results.json from /opt/dbt/target/, summarizes pass/fail/error,
    and pushes notifications to WeCom and DingTalk.
    """
    results_path = "/opt/dbt/target/run_results.json"

    if not os.path.exists(results_path):
        print(f"[webhook] run_results.json not found at {results_path}, skipping")
        return

    with open(results_path, encoding="utf-8") as f:
        results = json.load(f)

    summary = {"pass": 0, "fail": 0, "error": 0, "warn": 0}
    failures = []
    for r in results.get("results", []):
        status = r.get("status", "unknown")
        summary[status] = summary.get(status, 0) + 1
        if status in ("fail", "error"):
            failures.append(
                {
                    "test": r.get("unique_id", "").split(".")[-1],
                    "model": r.get("unique_id", "").split(".")[-2]
                    if len(r.get("unique_id", "").split(".")) > 2
                    else r.get("unique_id", ""),
                    "column": r.get("column_name") or "-",
                    "message": r.get("message") or "",
                }
            )

    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    total = sum(summary.values())

    header = (
        f"**DAG**: data_warehouse_full_pipeline\n"
        f"**Time**: {timestamp}\n"
        f"**Tests**: {total} total | "
        f'<font color="info">{summary["pass"]} passed</font>'
    )

    if failures:
        header += (
            f' | <font color="warning">{summary["fail"]} failed</font>'
            f' | <font color="warning">{summary["error"]} errors</font>\n'
            f"> Status: **FAILED**\n"
        )
        content = header + "\n" + _build_result_table(failures)
        extra = len(failures) - 20
        if extra > 0:
            content += f"\n\n... and {extra} more failures."

        title = "Data Quality Alert - FAILED"
        send_wecom_markdown(title, content)
        send_dingtalk_markdown(title, content)
    else:
        header += "\n> Status: **PASSED**"
        content = header + f"\n\nAll {summary['pass']} tests passed successfully."

        title = "Data Quality Check - PASSED"
        send_wecom_markdown(title, content)
        send_dingtalk_markdown(title, content)

    print(f"[webhook] Notification sent: {summary}")
