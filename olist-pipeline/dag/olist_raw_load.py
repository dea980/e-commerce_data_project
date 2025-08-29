from airflow import DAG
from datetime import datetime
from _common import DEFAULT_ARGS, sql_task
from _alerts import on_failure_callback
from _loaders import csv_load_task

with DAG(
    dag_id="olist_raw_load",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=True,
    default_args=DEFAULT_ARGS,
    max_active_runs=1,
    on_failure_callback=on_failure_callback,
    doc_md="RAW 계층 적재 + DQ",
) as dag:
    raw_ddl = sql_task(dag, "raw_ddl", "00_raw_ddl.sql")

    t_customers = csv_load_task(dag, "load_customers", "raw.customers_raw")
    t_sellers   = csv_load_task(dag, "load_sellers",   "raw.sellers_raw")
    t_orders    = csv_load_task(dag, "load_orders",    "raw.orders_raw")
    t_items     = csv_load_task(dag, "load_items",     "raw.order_items_raw")
    t_payments  = csv_load_task(dag, "load_payments",  "raw.payments_raw")
    t_reviews   = csv_load_task(dag, "load_reviews",   "raw.reviews_raw")
    t_products  = csv_load_task(dag, "load_products",  "raw.products_raw")
    t_geo       = csv_load_task(dag, "load_geo",       "raw.geolocation_raw")
    t_trans     = csv_load_task(dag, "load_translation","raw.product_category_translation_raw")

    raw_idx   = sql_task(dag, "raw_indexes",      "02_raw_indexes.sql")
    dq_hard   = sql_task(dag, "dq_hard",          "03_dq_hard.sql")
    dq_soft   = sql_task(dag, "dq_soft",          "04_dq_soft.sql")
    meta      = sql_task(dag, "meta_lineage",     "05_meta_lineage.sql")
    quarantine= sql_task(dag, "error_quarantine", "06_error_quarantine.sql")

    raw_ddl >> [t_customers, t_sellers, t_orders, t_items, t_payments, t_reviews, t_products, t_geo, t_trans]
    [t_customers, t_sellers, t_orders, t_items, t_payments, t_reviews, t_products, t_geo, t_trans] >> raw_idx
    raw_idx >> dq_hard >> dq_soft >> meta >> quarantine
