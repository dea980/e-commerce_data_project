from airflow import DAG
from datetime import datetime
from _common import DEFAULT_ARGS, sql_task
from _alerts import on_failure_callback
### 제품 / 셀러 / 지오 / 카테고리 transform
with DAG(
    dag_id="ods_dim",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=True,
    default_args=DEFAULT_ARGS,
    on_failure_callback=on_failure_callback,
    doc_md="ODS DIM: products/sellers/geolocation/category translation",
) as dag:
    dim_ddl = sql_task(dag, "ods_dim_ddl",     "20_ods_dim_ddl.sql")
    dim_idx = sql_task(dag, "ods_dim_indexes", "21_ods_dim_indexes.sql")
    dim_up  = sql_task(dag, "ods_dim_upsert",  "22_ods_dim_upsert.sql")

    dim_ddl >> dim_idx >> dim_up
