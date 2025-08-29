#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
누락된 payments와 reviews 데이터를 로드하는 스크립트
"""

import os
import psycopg2
from pathlib import Path

# 환경 설정
RAW_DIR = "/opt/airflow/data/raw"
PG_URI = "postgresql://olist_user:Kdea504605!@postgres:5432/olist"

def copy_csv_to_table(table_name: str, csv_file: str):
    """CSV 파일을 PostgreSQL 테이블에 복사"""
    csv_path = Path(RAW_DIR) / csv_file
    
    if not csv_path.exists():
        print(f"CSV 파일을 찾을 수 없습니다: {csv_path}")
        return False
    
    try:
        with psycopg2.connect(PG_URI) as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                # CSV 파일을 테이블에 복사
                with csv_path.open("r", encoding="utf-8") as f:
                    sql = f"COPY {table_name} FROM STDIN WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"')"
                    cur.copy_expert(sql, f)
                
                # 로드된 행 수 확인
                cur.execute(f"SELECT COUNT(*) FROM {table_name}")
                count = cur.fetchone()[0]
                print(f"✅ {table_name}: {count}행 로드 완료")
                return True
                
    except Exception as e:
        print(f"❌ {table_name} 로드 실패: {e}")
        return False

def main():
    print("=== 누락된 데이터 로딩 시작 ===")
    
    # payments 데이터 로드
    print("\n1. payments 데이터 로딩...")
    success_payments = copy_csv_to_table(
        "raw.payments_raw", 
        "olist_order_payments_dataset.csv"
    )
    
    # reviews 데이터 로드
    print("\n2. reviews 데이터 로딩...")
    success_reviews = copy_csv_to_table(
        "raw.reviews_raw", 
        "olist_order_reviews_dataset.csv"
    )
    
    # 결과 요약
    print("\n=== 로딩 결과 요약 ===")
    print(f"payments: {'✅ 성공' if success_payments else '❌ 실패'}")
    print(f"reviews: {'✅ 성공' if success_reviews else '❌ 실패'}")
    
    if success_payments and success_reviews:
        print("\n🎉 모든 데이터 로딩 완료!")
    else:
        print("\n⚠️ 일부 데이터 로딩 실패")

if __name__ == "__main__":
    main()
