# -*- coding: utf-8 -*-
"""
공통 유틸: SQL 파일 실행, 태스크 팩토리, 기본 디폴트 args
- AIRFLOW_CONN_POSTGRES_DEFAULT 환경변수 또는 Connection ID 사용
- include/sql/ 경로 기준으로 SQL 파일을 읽어 실행
"""
import os
from pathlib import Path
from datetime import timedelta
import psycopg2

from airflow.operators.python import PythonOperator

SQL_BASE_DIR = os.environ.get("SQL_BASE_DIR", "/opt/airflow/include/sql")

def _run_sql(pg_conn_uri: str, sql_text: str, params: dict = None):
    with psycopg2.connect(pg_conn_uri) as conn:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(sql_text, params or {})

def run_sql_file(pg_conn_uri: str, rel_path: str, params: dict = None):
    path = Path(SQL_BASE_DIR) / rel_path
    sql = path.read_text(encoding="utf-8")
    _run_sql(pg_conn_uri, sql, params)

def sql_task(dag, task_id: str, rel_path: str, extra_params: dict = None):
    # Airflow env-style conn string (e.g., postgresql+psycopg2://... 는 psycopg2 URI로 맞춰주세요)
    pg_uri = os.environ.get("AIRFLOW_CONN_POSTGRES_DEFAULT")
    if not pg_uri:
        raise RuntimeError("AIRFLOW_CONN_POSTGRES_DEFAULT is not set.")

    def _runner(ds, **_):
        params = {"ds": ds}
        if extra_params:
            params.update(extra_params)
        run_sql_file(pg_uri, rel_path, params)

    return PythonOperator(
        task_id=task_id,
        python_callable=_runner,
    )

DEFAULT_ARGS = {
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": False,
    "email_on_retry": False,
}
