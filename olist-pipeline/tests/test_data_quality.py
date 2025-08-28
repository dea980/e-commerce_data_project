"""
데이터 품질 검증 테스트
"""
import pytest
import pandas as pd
from sqlalchemy import text
import tempfile
from pathlib import Path


class TestDataQualityHard:
    """하드 데이터 품질 규칙 테스트"""
    
    def setup_test_data(self, engine, sample_data):
        """테스트용 데이터 셋업"""
        # 스키마 생성
        engine.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
        engine.execute(text("CREATE SCHEMA IF NOT EXISTS ods;"))
        engine.execute(text("CREATE SCHEMA IF NOT EXISTS ops;"))
        
        # RAW 테이블 생성
        engine.execute(text("""
            CREATE TABLE IF NOT EXISTS raw.orders_raw(
                order_id TEXT, customer_id TEXT, order_status TEXT,
                order_purchase_timestamp TEXT, order_approved_at TEXT,
                order_delivered_carrier_date TEXT, order_delivered_customer_date TEXT,
                order_estimated_delivery_date TEXT
            );
        """))
        
        # ODS 테이블 생성
        engine.execute(text("""
            CREATE TABLE IF NOT EXISTS ods.orders (
                order_id TEXT PRIMARY KEY,
                customer_id TEXT NOT NULL,
                order_status TEXT NOT NULL,
                order_purchase_ts TIMESTAMPTZ,
                order_approved_ts TIMESTAMPTZ,
                delivered_carrier_ts TIMESTAMPTZ,
                delivered_customer_ts TIMESTAMPTZ,
                estimated_delivery_ts TIMESTAMPTZ
            );
        """))
        
        engine.execute(text("""
            CREATE TABLE IF NOT EXISTS ods.customers (
                customer_id TEXT PRIMARY KEY,
                customer_unique_id TEXT,
                customer_zip_code_prefix TEXT,
                customer_city TEXT,
                customer_state TEXT
            );
        """))
        
        engine.execute(text("""
            CREATE TABLE IF NOT EXISTS ods.order_items (
                order_id TEXT NOT NULL,
                order_item_id INT NOT NULL,
                product_id TEXT,
                seller_id TEXT,
                shipping_limit_ts TIMESTAMPTZ,
                price NUMERIC(18,2),
                freight_value NUMERIC(18,2),
                PRIMARY KEY (order_id, order_item_id)
            );
        """))
        
        # DQ 결과 테이블
        engine.execute(text("""
            CREATE TABLE IF NOT EXISTS ops.dq_results(
                check_name TEXT,
                table_name TEXT,
                level TEXT,
                status TEXT,
                actual NUMERIC,
                threshold NUMERIC,
                details TEXT,
                checked_at TIMESTAMPTZ DEFAULT NOW()
            );
        """))
        
        # 샘플 데이터 삽입
        sample_data['customers'].to_sql('customers', engine, schema='ods', if_exists='append', index=False)
        
        # 주문 데이터 변환 후 삽입
        orders_ods = sample_data['orders'].copy()
        orders_ods['order_purchase_ts'] = pd.to_datetime(orders_ods['order_purchase_timestamp'])
        orders_ods['order_approved_ts'] = pd.to_datetime(orders_ods['order_approved_at'])
        orders_ods = orders_ods.drop(['order_purchase_timestamp', 'order_approved_at', 
                                    'order_delivered_carrier_date', 'order_delivered_customer_date',
                                    'order_estimated_delivery_date'], axis=1)
        orders_ods.to_sql('orders', engine, schema='ods', if_exists='append', index=False)
    
    def test_pk_uniqueness_pass(self, postgres_engine, sample_raw_data):
        """PK 유일성 검증 - 통과 케이스"""
        # Given
        self.setup_test_data(postgres_engine, sample_raw_data)
        
        # When - PK 유일성 체크 쿼리 실행
        result = postgres_engine.execute(text("""
            WITH d AS (
              SELECT COUNT(*) dup_cnt FROM (
                SELECT order_id FROM ods.orders GROUP BY 1 HAVING COUNT(*)>1
              ) x
            )
            SELECT CASE WHEN dup_cnt=0 THEN 'pass' ELSE 'fail' END as status
            FROM d;
        """)).fetchone()
        
        # Then
        assert result[0] == 'pass'
    
    def test_pk_uniqueness_fail(self, postgres_engine, sample_raw_data):
        """PK 유일성 검증 - 실패 케이스"""
        # Given
        self.setup_test_data(postgres_engine, sample_raw_data)
        
        # 중복 데이터 삽입
        postgres_engine.execute(text("""
            INSERT INTO ods.orders (order_id, customer_id, order_status)
            VALUES ('order_1', 'customer_1', 'duplicate');
        """))
        
        # When
        result = postgres_engine.execute(text("""
            WITH d AS (
              SELECT COUNT(*) dup_cnt FROM (
                SELECT order_id FROM ods.orders GROUP BY 1 HAVING COUNT(*)>1
              ) x
            )
            SELECT CASE WHEN dup_cnt=0 THEN 'pass' ELSE 'fail' END as status,
                   dup_cnt
            FROM d;
        """)).fetchone()
        
        # Then
        assert result[0] == 'fail'
        assert result[1] > 0
    
    def test_foreign_key_integrity(self, postgres_engine, sample_raw_data):
        """외래키 무결성 검증"""
        # Given
        self.setup_test_data(postgres_engine, sample_raw_data)
        
        # order_items 데이터 삽입
        items_data = sample_raw_data['order_items'].copy()
        items_data['order_item_id'] = items_data['order_item_id'].astype(int)
        items_data['price'] = items_data['price'].astype(float)
        items_data['freight_value'] = items_data['freight_value'].astype(float)
        items_data.to_sql('order_items', postgres_engine, schema='ods', if_exists='append', index=False)
        
        # When - FK 검증 쿼리
        result = postgres_engine.execute(text("""
            WITH bad AS (
              SELECT oi.order_id FROM ods.order_items oi
              LEFT JOIN ods.orders o ON o.order_id=oi.order_id
              WHERE o.order_id IS NULL
            ), m AS (SELECT COUNT(*) c FROM bad)
            SELECT CASE WHEN c=0 THEN 'pass' ELSE 'fail' END as status, c
            FROM m;
        """)).fetchone()
        
        # Then
        assert result[0] == 'pass'
        assert result[1] == 0


class TestDataQualitySoft:
    """소프트 데이터 품질 규칙 테스트"""
    
    def test_negative_price_detection(self, postgres_engine, sample_raw_data):
        """음수 가격 탐지 테스트"""
        # Given
        # 음수 가격 데이터 추가
        bad_items = sample_raw_data['order_items'].copy()
        bad_items.loc[0, 'price'] = '-50.00'  # 음수 가격
        bad_items['order_item_id'] = bad_items['order_item_id'].astype(int)
        bad_items['price'] = bad_items['price'].astype(float)
        bad_items['freight_value'] = bad_items['freight_value'].astype(float)
        
        # 테이블 생성 및 데이터 삽입
        postgres_engine.execute(text("CREATE SCHEMA IF NOT EXISTS ods;"))
        bad_items.to_sql('order_items', postgres_engine, schema='ods', if_exists='replace', index=False)
        
        # When
        result = postgres_engine.execute(text("""
            WITH m AS (
              SELECT 100.0*AVG(CASE WHEN price<0 OR freight_value<0 THEN 1 ELSE 0 END)::numeric AS neg_rate
              FROM ods.order_items
            )
            SELECT CASE WHEN neg_rate<=0 THEN 'pass' ELSE 'fail' END as status, neg_rate
            FROM m;
        """)).fetchone()
        
        # Then
        assert result[0] == 'fail'
        assert result[1] > 0
    
    def test_data_freshness_check(self, postgres_engine):
        """데이터 신선도 체크 테스트"""
        # Given
        postgres_engine.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
        postgres_engine.execute(text("""
            CREATE TABLE IF NOT EXISTS raw.orders_raw(
                order_id TEXT,
                _ingested_at TIMESTAMPTZ DEFAULT NOW()
            );
        """))
        
        # 오래된 데이터 삽입
        postgres_engine.execute(text("""
            INSERT INTO raw.orders_raw (order_id, _ingested_at)
            VALUES ('old_order', NOW() - INTERVAL '25 hours');
        """))
        
        # When
        result = postgres_engine.execute(text("""
            WITH m AS (
              SELECT EXTRACT(EPOCH FROM (NOW() - MAX(_ingested_at)))/3600 AS hours
              FROM raw.orders_raw
            )
            SELECT CASE WHEN hours<=24 THEN 'pass' ELSE 'fail' END as status, hours
            FROM m;
        """)).fetchone()
        
        # Then
        assert result[0] == 'fail'
        assert result[1] > 24


class TestDataTransformation:
    """데이터 변환 로직 테스트"""
    
    def test_raw_to_ods_transformation(self, postgres_engine, sample_raw_data):
        """RAW → ODS 변환 테스트"""
        # Given - RAW 테이블 생성 및 데이터 삽입
        postgres_engine.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
        postgres_engine.execute(text("CREATE SCHEMA IF NOT EXISTS ods;"))
        
        # RAW 테이블
        postgres_engine.execute(text("""
            CREATE TABLE raw.orders_raw(
                order_id TEXT, customer_id TEXT, order_status TEXT,
                order_purchase_timestamp TEXT, order_approved_at TEXT,
                order_delivered_carrier_date TEXT, order_delivered_customer_date TEXT,
                order_estimated_delivery_date TEXT
            );
        """))
        
        sample_raw_data['orders'].to_sql('orders_raw', postgres_engine, schema='raw', if_exists='append', index=False)
        
        # ODS 테이블
        postgres_engine.execute(text("""
            CREATE TABLE ods.orders (
                order_id TEXT PRIMARY KEY,
                customer_id TEXT NOT NULL,
                order_status TEXT NOT NULL,
                order_purchase_ts TIMESTAMPTZ,
                order_approved_ts TIMESTAMPTZ,
                delivered_carrier_ts TIMESTAMPTZ,
                delivered_customer_ts TIMESTAMPTZ,
                estimated_delivery_ts TIMESTAMPTZ
            );
        """))
        
        # When - 변환 로직 실행
        postgres_engine.execute(text("""
            INSERT INTO ods.orders
            (order_id, customer_id, order_status, order_purchase_ts, order_approved_ts,
                delivered_carrier_ts, delivered_customer_ts, estimated_delivery_ts)
            SELECT
                order_id, customer_id, order_status,
                NULLIF(order_purchase_timestamp,'')::timestamptz,
                NULLIF(order_approved_at,'')::timestamptz,
                NULLIF(order_delivered_carrier_date,'')::timestamptz,
                NULLIF(order_delivered_customer_date,'')::timestamptz,
                NULLIF(order_estimated_delivery_date,'')::timestamptz
            FROM raw.orders_raw WHERE order_id IS NOT NULL;
        """))
        
        # Then
        result = postgres_engine.execute(text("""
            SELECT COUNT(*) as count,
                   COUNT(CASE WHEN order_purchase_ts IS NOT NULL THEN 1 END) as with_purchase_ts
            FROM ods.orders;
        """)).fetchone()
        
        assert result[0] == 3  # 3개 레코드 변환됨
        assert result[1] == 3  # 모든 레코드에 purchase_ts 있음
