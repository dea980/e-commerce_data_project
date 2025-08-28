-- 금액 음수 비율
WITH m AS (
  SELECT 100.0*AVG(CASE WHEN price<0 OR freight_value<0 THEN 1 ELSE 0 END)::numeric AS neg_rate
  FROM ods.order_items
)
INSERT INTO ops.dq_results(check_name,table_name,level,status,actual,threshold,details)
SELECT 'neg_price_rate','ods.order_items','soft',
       CASE WHEN neg_rate<=0 THEN 'pass' ELSE 'fail' END, neg_rate,0,'negative price/freight' FROM m;

-- 시간 순서 위반 비율
WITH m AS (
  SELECT 100.0*AVG(CASE WHEN delivered_customer_ts < delivered_carrier_ts THEN 1 ELSE 0 END)::numeric AS rate
  FROM ods.orders WHERE delivered_customer_ts IS NOT NULL AND delivered_carrier_ts IS NOT NULL
)
INSERT INTO ops.dq_results(check_name,table_name,level,status,actual,threshold,details)
SELECT 'ts_sequence_violation','ods.orders','soft',
       CASE WHEN rate<=0 THEN 'pass' ELSE 'fail' END, rate,0,'delivery timestamps out of order' FROM m;

-- 결제 vs 아이템 합계 오차율 (절대 10% 초과 시 fail로 기록)
WITH sums AS (
  SELECT COALESCE(SUM(p.payment_value),0) pay, COALESCE(SUM(i.price+i.freight_value),0) items
  FROM ods.orders o
  LEFT JOIN ods.payments p ON p.order_id=o.order_id
  LEFT JOIN ods.order_items i ON i.order_id=o.order_id
), m AS (
  SELECT CASE WHEN items=0 THEN 0 ELSE 100.0*ABS(pay - items)/items END AS err_pct FROM sums
)
INSERT INTO ops.dq_results(check_name,table_name,level,status,actual,threshold,details)
SELECT 'payments_items_recon','ods.*','soft',
       CASE WHEN err_pct<=10 THEN 'pass' ELSE 'fail' END, err_pct,10,'|pay-items|/items %' FROM m;

-- 신선도: 최근 적재 UTC 24h 이내 (RAW 메타 활용)
WITH m AS (
  SELECT EXTRACT(EPOCH FROM (NOW() - MAX(_ingested_at)))/3600 AS hours
  FROM raw.orders_raw
)
INSERT INTO ops.dq_results(check_name,table_name,level,status,actual,threshold,details)
SELECT 'freshness_hours','raw.orders_raw','soft',
       CASE WHEN hours<=24 THEN 'pass' ELSE 'fail' END, hours,24,'max _ingested_at age (h)' FROM m;
