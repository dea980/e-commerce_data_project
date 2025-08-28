"""
pytest 설정 및 공통 픽스처
"""
import pytest
import os
import tempfile
import pandas as pd
from pathlib import Path
from unittest.mock import Mock
from sqlalchemy import create_engine

# 프로젝트 루트 경로
PROJECT_ROOT = Path(__file__).parent.parent


@pytest.fixture
def mock_postgres_engine():
    """모킹된 PostgreSQL 엔진"""
    engine = Mock()
    return engine


@pytest.fixture
def sample_raw_data():
    """테스트용 샘플 RAW 데이터"""
    return {
        'orders': pd.DataFrame({
            'order_id': ['order_1', 'order_2', 'order_3'],
            'customer_id': ['customer_1', 'customer_2', 'customer_1'],
            'order_status': ['delivered', 'shipped', 'delivered'],
            'order_purchase_timestamp': ['2024-01-01 10:00:00', '2024-01-02 11:00:00', '2024-01-03 12:00:00'],
            'order_approved_at': ['2024-01-01 10:30:00', '2024-01-02 11:30:00', '2024-01-03 12:30:00'],
            'order_delivered_carrier_date': ['2024-01-02 10:00:00', '', '2024-01-04 10:00:00'],
            'order_delivered_customer_date': ['2024-01-03 15:00:00', '', '2024-01-05 16:00:00'],
            'order_estimated_delivery_date': ['2024-01-05 00:00:00', '2024-01-07 00:00:00', '2024-01-07 00:00:00']
        }),
        'customers': pd.DataFrame({
            'customer_id': ['customer_1', 'customer_2', 'customer_3'],
            'customer_unique_id': ['unique_1', 'unique_2', 'unique_3'],
            'customer_zip_code_prefix': ['01234', '56789', '01234'],
            'customer_city': ['São Paulo', 'Rio de Janeiro', 'São Paulo'],
            'customer_state': ['SP', 'RJ', 'SP']
        }),
        'order_items': pd.DataFrame({
            'order_id': ['order_1', 'order_1', 'order_2'],
            'order_item_id': ['1', '2', '1'],
            'product_id': ['product_1', 'product_2', 'product_1'],
            'seller_id': ['seller_1', 'seller_2', 'seller_1'],
            'shipping_limit_date': ['2024-01-02 00:00:00', '2024-01-02 00:00:00', '2024-01-03 00:00:00'],
            'price': ['100.50', '200.75', '100.50'],
            'freight_value': ['10.00', '15.50', '10.00']
        }),
        'payments': pd.DataFrame({
            'order_id': ['order_1', 'order_2', 'order_3'],
            'payment_sequential': ['1', '1', '1'],
            'payment_type': ['credit_card', 'debit_card', 'credit_card'],
            'payment_installments': ['1', '1', '2'],
            'payment_value': ['110.50', '110.50', '150.00']
        })
    }


@pytest.fixture
def temp_sql_dir():
    """임시 SQL 디렉토리"""
    with tempfile.TemporaryDirectory() as temp_dir:
        sql_dir = Path(temp_dir) / "sql"
        sql_dir.mkdir()
        yield sql_dir


@pytest.fixture
def mock_airflow_context():
    """Airflow 컨텍스트 모킹"""
    context = Mock()
    context.get.return_value = Mock()
    context.get.return_value.conf = {'batch_id': 'test-batch-123'}
    return context
