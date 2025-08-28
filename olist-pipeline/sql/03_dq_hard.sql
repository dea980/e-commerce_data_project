-- 1) 필수 테이블/건수
DO $$ BEGIN
  PERFORM 1 FROM raw.orders_raw LIMIT 1;
EXCEPTION WHEN undefined_table THEN
  RAISE EXCEPTION 'raw.orders_raw missing';
END $$;

-- 2) ODS 유일성
WITH d AS (
  SELECT COUNT(*) dup_cnt FROM (
    SELECT order_id FROM ods.orders GROUP BY 1 HAVING COUNT(*)>1
  ) x
)
INSERT INTO ops.dq_results(check_name,table_name,level,status,actual,threshold,details)
SELECT 'pk_unique_orders','ods.orders','hard',
       CASE WHEN dup_cnt=0 THEN 'pass' ELSE 'fail' END, dup_cnt,0,'order_id duplicates'
FROM d;
-- 실패 시 예외 던져 DAG 중단
DO $$ BEGIN
  IF (SELECT status FROM ops.dq_results ORDER BY checked_at DESC LIMIT 1)='fail' THEN
    RAISE EXCEPTION 'DQ hard fail: pk_unique_orders';
  END IF;
END $$;

-- 3) FK: order_items → orders
WITH bad AS (
  SELECT oi.order_id FROM ods.order_items oi
  LEFT JOIN ods.orders o ON o.order_id=oi.order_id
  WHERE o.order_id IS NULL
), m AS (SELECT COUNT(*) c FROM bad)
INSERT INTO ops.dq_results(check_name,table_name,level,status,actual,threshold,details)
SELECT 'fk_items_orders','ods.order_items','hard',
       CASE WHEN c=0 THEN 'pass' ELSE 'fail' END, c,0,'items without parent order'
FROM m;
DO $$ BEGIN
  IF (SELECT status FROM ops.dq_results ORDER BY checked_at DESC LIMIT 1)='fail' THEN
    RAISE EXCEPTION 'DQ hard fail: fk_items_orders';
  END IF;
END $$;

-- 4) 값 범위(예: review_score)
WITH m AS (SELECT COUNT(*) bad FROM ods.reviews WHERE review_score NOT BETWEEN 1 AND 5 OR review_score IS NULL)
INSERT INTO ops.dq_results(check_name,table_name,level,status,actual,threshold,details)
SELECT 'reviews_score_range','ods.reviews','hard',
       CASE WHEN bad=0 THEN 'pass' ELSE 'fail' END,bad,0,'score not in [1,5]' FROM m;
DO $$ BEGIN
  IF (SELECT status FROM ops.dq_results ORDER BY checked_at DESC LIMIT 1)='fail' THEN
    RAISE EXCEPTION 'DQ hard fail: reviews_score_range';
  END IF;
END $$;
