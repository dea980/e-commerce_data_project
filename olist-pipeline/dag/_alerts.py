# -*- coding: utf-8 -*-
"""
간단 실패 알림 콜백 (Slack Incoming Webhook 사용)
- SLACK_WEBHOOK_URL 환경변수 필요
"""
import os
import json
import urllib.request

SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")

def _post_to_slack(message: str):
    if not SLACK_WEBHOOK_URL:
        return
    data = {"text": message}
    req = urllib.request.Request(
        SLACK_WEBHOOK_URL,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    urllib.request.urlopen(req, timeout=5)

def on_failure_callback(context):
    dag_id = context.get("dag").dag_id if context.get("dag") else "unknown_dag"
    task_id = context.get("task_instance").task_id if context.get("task_instance") else "unknown_task"
    exec_date = context.get("ts")
    log_url = context.get("task_instance").log_url if context.get("task_instance") else ""
    _post_to_slack(f":x: Airflow Task Failed\n• DAG: *{dag_id}*\n• Task: `{task_id}`\n• When: {exec_date}\n• Logs: {log_url}")
