DO $$
BEGIN
    IF EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='ods' AND tablename='reviews' AND indexname='ods_reviews_order_id_key'
    ) THEN
        -- 보호적 검사: 실제 환경에서 이름이 다를 수 있음. 제약명 확인 후 교체.
        RAISE NOTICE 'Please drop the UNIQUE constraint on ods.reviews(order_id) manually if named differently.';
    END IF;
END$$;

-- 일반적으로는 다음 형태(제약명 확인 후 실행):
-- ALTER TABLE ods.reviews DROP CONSTRAINT IF EXISTS reviews_order_id_key;
-- 또는: ALTER TABLE ods.reviews DROP CONSTRAINT IF EXISTS ods_reviews_order_id_key;
-- UNIQUE 제약 없나명 이파일 생략 가능