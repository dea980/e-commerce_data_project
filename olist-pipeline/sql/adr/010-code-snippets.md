---
doc: appendix-b
title: 코드/설정 스니펫
date: 2025-08-26
---

### Airflow 한 컨테이너(웹+스케줄러)
```yaml
command: >
  bash -lc '
    airflow db migrate || airflow db init &&
    airflow users create --username admin --password admin       --firstname Admin --lastname User --role Admin --email admin@example.com || true &&
    airflow webserver & exec airflow scheduler
  '
```

### DAG SQL 로더
```python
import os
SQL_DIR = os.getenv("SQL_DIR", "/opt/airflow/sql")
def read_sql(basename: str) -> str:
    with open(f"{SQL_DIR}/{basename}.sql", "r", encoding="utf-8") as f:
        return f.read()
```

### DQ 태스크 (배치ID 치환)
```python
from airflow.decorators import task
from airflow.operators.python import get_current_context
from airflow.providers.postgres.hooks.postgres import PostgresHook

@task
def run_sql_with_batch(basename: str, conn_id: str = "postgres_default"):
    ctx = get_current_context()
    batch_id = (ctx.get("dag_run") or {}).conf.get("batch_id", "")
    from _common import read_sql
    sql = read_sql(basename).replace("{{BATCH_ID}}", batch_id)
    PostgresHook(conn_id).run(sql, autocommit=True)
    return batch_id or ""
```
