# -*- coding: utf-8 -*-
import os, csv, psycopg2
from pathlib import Path
from airflow.operators.python import PythonOperator

RAW_DIR = os.environ.get("DATA_RAW_DIR", "/opt/airflow/data/raw")
PG_URI   = os.environ.get("AIRFLOW_CONN_POSTGRES_DEFAULT")

# 테이블별 CSV 파일명
CSV_MAP = {
    "raw.customers": "olist_customers_dataset.csv",
    "raw.sellers": "olist_sellers_dataset.csv",
    "raw.orders": "olist_orders_dataset.csv",
    "raw.order_items": "olist_order_items_dataset.csv",
    "raw.order_payments": "olist_order_payments_dataset.csv",
    "raw.order_reviews": "olist_order_reviews_dataset.csv",
    "raw.products": "olist_products_dataset.csv",
    "raw.geolocation": "olist_geolocation_dataset.csv",
    "raw.product_category_name_translation": "product_category_name_translation.csv",
}

def copy_csv_to_raw(table: str):
    path = Path(RAW_DIR) / CSV_MAP[table]
    if not path.exists():
        raise FileNotFoundError(f"CSV not found: {path}")
    with path.open("r", encoding="utf-8") as f, psycopg2.connect(PG_URI) as conn:
        conn.autocommit = True
        with conn.cursor() as cur:
            # 헤더를 자동으로 읽어서 COPY … CSV HEADER 실행
            sql = f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"')"
            cur.copy_expert(sql, f)

def csv_load_task(dag, task_id: str, table: str):
    return PythonOperator(
        task_id=task_id,
        python_callable=copy_csv_to_raw,
        op_args=[table],
    )
