from airflow import DAG
from datetime import datetime
from _common import DEFAULT_ARGS, sql_task
from _alerts import on_failure_callback

with DAG(
    dag_id="raw_to_ods",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=True,
    default_args=DEFAULT_ARGS,
    on_failure_callback=on_failure_callback,
    doc_md="RAW → ODS(Core)",
) as dag:
    ods_ddl    = sql_task(dag, "ods_core_ddl",    "10_ods_core_ddl.sql")
    ods_upsert = sql_task(dag, "ods_core_upsert", "12_ods_core_upsert.sql")
    ods_idx    = sql_task(dag, "ods_core_idx",    "11_ods_core_indexes.sql")

    ods_ddl >> ods_upsert >> ods_idx
