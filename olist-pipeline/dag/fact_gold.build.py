from airflow import DAG
from datetime import datetime
from _common import DEFAULT_ARGS, sql_task
from _alerts import on_failure_callback

with DAG(
    dag_id="fact_gold_build",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=True,
    default_args=DEFAULT_ARGS,
    on_failure_callback=on_failure_callback,
    doc_md="FACT + GOLD marts (KPI/Cohort/Funnel/Payment/Delay)",
) as dag:
    # FACT
    f0 = sql_task(dag, "fact_ddl",    "23_fact_order_item_ddl.sql")
    f1 = sql_task(dag, "fact_idx",    "24_fact_order_item_indexes.sql")
    f2 = sql_task(dag, "fact_upsert", "25_fact_order_item_upsert.sql")

    # GOLD
    g0 = sql_task(dag, "gold_kpi_daily",        "40_gold_kpi_daily.sql")
    g1 = sql_task(dag, "gold_cohort_retention", "41_gold_cohort_monthly_retention.sql")
    g2 = sql_task(dag, "gold_funnel_daily",     "42_gold_funnel_daily.sql")
    g3 = sql_task(dag, "gold_payment_mix",      "43_gold_payment_mix_daily.sql")
    g4 = sql_task(dag, "gold_delay_top_seller", "44_gold_delay_top_seller_daily.sql")

    f0 >> f1 >> f2 >> [g0, g1, g2, g3, g4]
