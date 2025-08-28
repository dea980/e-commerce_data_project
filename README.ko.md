# Olist 이커머스 ETL 파이프라인

## 개요

이 저장소는 브라질 Olist 이커머스 공개 데이터셋을 위한 확장 가능한 컨테이너화된 ETL(추출, 변환, 적재) 파이프라인을 구현합니다. 아키텍처는 업계 표준 데이터 엔지니어링 도구를 활용합니다:

- **Apache Airflow 2.9.3**: 워크플로우 스케줄링 및 의존성 관리를 위한 오케스트레이션 엔진
- **PostgreSQL 15**: 트랜잭션 무결성을 갖춘 구조화된 데이터 저장을 위한 RDBMS
- **MinIO**: 원시 데이터 지속성을 위한 S3 호환 객체 스토리지

이 파이프라인은 여러 처리 계층을 통한 점진적 데이터 정제를 통해 메달리온 아키텍처 패턴을 따릅니다.

## 데이터 소스

이 파이프라인은 다음 사양을 가진 9개의 정규화된 CSV 파일로 구성된 Olist 브라질 이커머스 데이터셋을 처리합니다:

| 엔티티 | 레코드 수 | 주요 속성 |
|--------|---------|----------------|
| 주문(Orders) | 99,441 | order_id, customer_id, status, timestamps |
| 주문 항목(Order Items) | 112,650 | order_id, product_id, seller_id, price |
| 고객(Customers) | 99,441 | customer_id, location data |
| 판매자(Sellers) | 3,095 | seller_id, location data |
| 제품(Products) | 32,951 | product_id, category, dimensions |
| 리뷰(Reviews) | 104,719 | review_id, order_id, score, comments |
| 결제(Payments) | 103,886 | order_id, payment_type, installments |
| 지리적 위치(Geolocation) | 1,000,163 | zip_code_prefix, lat/lng coordinates |
| 카테고리 번역(Category Translation) | 71 | 포르투갈어에서 영어로의 매핑 |

## 파이프라인 아키텍처

데이터 파이프라인은 3계층 메달리온 아키텍처를 구현합니다:

### 1. Raw 계층 (Bronze)
**DAG: olist_raw_load**
- MinIO S3에서 PostgreSQL 원시 테이블로 데이터 수집
- 최소한의 변환으로 소스 데이터 무결성 보존
- 메타데이터 추적 구현 (batch_id, 수집 타임스탬프, 소스)
- 경량 데이터 유효성 검사 실행
- 기술적 구현:
  ```python
  # Raw 계층의 주요 작업
  batch_id = str(uuid.uuid4())  # 고유 처리 ID
  s3 = _s3()  # S3/MinIO 클라이언트 초기화
  
  # 객체 스토리지에서 PostgreSQL로 직접 데이터 스트리밍
  for tbl, key in RAW_FILES.items():
      obj = s3.get_object(Bucket=S3_BUCKET, Key=s3key)
      with io.TextIOWrapper(obj["Body"], encoding="utf-8") as f:
          cur.copy_expert(f"COPY raw.{tbl} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)", f)
  ```

### 2. ODS 계층 (Silver)
**DAG: raw_to_ods**
- 스키마 적용 및 데이터 타입 표준화
- 데이터 품질 검사 실행 (하드 제약 조건 및 소프트 유효성 검사)
- 구성 가능한 실패 임계값을 통한 오류 처리 구현
- DQ 위반에 대한 알림 시스템과 통합
- 기술적 구현:
  ```sql
  -- ODS 계층 변환 예시 (간소화됨)
  INSERT INTO ods.orders
  SELECT 
    order_id,
    customer_id,
    CASE 
      WHEN order_status IN ('delivered', 'shipped', 'canceled') THEN order_status
      ELSE 'other' 
    END AS order_status,
    CAST(order_purchase_timestamp AS TIMESTAMP),
    -- 추가 변환
  FROM raw.orders_raw
  WHERE _batch_id = '{{BATCH_ID}}'
  ON CONFLICT (order_id) DO UPDATE
  SET /* 업데이트 로직 */;
  ```

### 3. 차원 계층 (Gold)
**DAG: ods_dim**
- 차원 모델링 구현 (팩트/차원 테이블)
- 분석 쿼리 성능 최적화
- 적절한 인덱싱 전략 적용
- SCD(천천히 변화하는 차원) 패턴 처리
- 기술적 구현:
  ```sql
  -- 차원 테이블 생성 예시
  CREATE TABLE IF NOT EXISTS dim.d_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_city VARCHAR(50),
    customer_state CHAR(2),
    geolocation_lat NUMERIC(15,10),
    geolocation_lng NUMERIC(15,10),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    UNIQUE(customer_id, valid_from)
  );
  ```

## 기술 요구사항

- Docker Engine 20.10+ 및 Docker Compose v2+
- Docker에 할당된 최소 4GB RAM
- 사용 가능한 포트: 8080 (Airflow), 9000-9001 (MinIO)
- 5GB+ 사용 가능한 디스크 공간

## 배포

1. 저장소 복제:
   ```bash
   git clone <repository-url>
   cd e-commerce_data_project
   ```

2. 컨테이너화된 인프라 배포:
   ```bash
   docker-compose up -d
   ```

3. 배포 상태 확인:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
   ```

## 서비스 접근

| 서비스 | URL | 인증 정보 | 목적 |
|---------|-----|-------------|---------|
| Airflow | http://localhost:8080 | kdea989/Kdea504605 | 워크플로우 오케스트레이션 |
| MinIO 콘솔 | http://localhost:9001 | kdea989/Kdea504605 | 객체 스토리지 관리 |

## 저장소 구조

```
e-commerce_data_project/
├── data/
│   └── raw/                  # 소스 CSV 파일
├── olist-pipeline/
│   ├── dag/                  # Airflow DAG 정의
│   │   ├── _alerts.py        # 알림 프레임워크
│   │   ├── _common.py        # 공유 유틸리티
│   │   ├── olist_raw_load.py # Raw 수집 DAG
│   │   ├── raw_to_ods.py     # ODS 변환 DAG
│   │   └── ods_dim.py        # 차원 모델링 DAG
│   ├── docker/               # Docker 구성
│   └── sql/                  # SQL 변환 스크립트
│       ├── 00_raw_ddl.sql    # Raw 스키마 정의
│       ├── 01_raw_meta.sql   # 메타데이터 열 정의
│       ├── 02_raw_indexes.sql # Raw 계층 인덱싱
│       ├── 03_dq_hard.sql    # 중요 데이터 품질 검사
│       ├── 04_dq_soft.sql    # 비중요 데이터 품질 검사
│       ├── 10_ods_core_ddl.sql # ODS 스키마 정의
│       ├── 11_ods_core_indexes.sql # ODS 성능 최적화
│       ├── 12_ods_core_upsert.sql # ODS 증분 로딩
│       └── 20_ods_dim_ddl.sql # 차원 모델 정의
└── docker-compose.yml        # 코드로서의 인프라
```

## 실행

파이프라인은 DAG 의존성을 통한 이벤트 기반 오케스트레이션을 구현합니다:

1. Airflow UI 접근: http://localhost:8080
2. 제공된 인증 정보로 인증
3. DAG 뷰로 이동
4. DAG 활성화 (일시 중지된 경우 토글 스위치)
5. `olist_raw_load` DAG 트리거
   - 후속 DAG(`raw_to_ods` → `ods_dim`)는 TriggerDagRunOperator를 통해 자동으로 트리거됨

## 모니터링 및 문제 해결

### 로그
```bash
# 컨테이너 로그 보기
docker logs e-commerce_data_project-airflow-webserver-1 -f

# UI를 통해 Airflow 태스크 로그 보기
# DAG > [DAG_이름] > [태스크_이름] > 로그
```

### 일반적인 문제

#### 포트 충돌
충돌이 발생하는 경우 `docker-compose.yml`에서 포트 매핑 수정:
```yaml
ports:
  - "8081:8080"  # 대체 호스트 포트에 매핑
```

#### 컨테이너 상태
```bash
# 컨테이너 상태 확인
docker ps --format "table {{.Names}}\t{{.Status}}"

# 특정 컨테이너 재시작
docker restart e-commerce_data_project-airflow-webserver-1
```

#### 데이터 품질 알림
데이터 품질 문제는 다음에 기록됩니다:
1. Airflow 태스크 로그
2. Slack 알림 (구성된 경우)

## 라이선스 및 귀속

이 프로젝트는 [Kaggle 약관](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)에 따라 제공되는 브라질 이커머스 공개 데이터셋 by Olist를 활용합니다. 상업적 사용에는 적절한 귀속이 필요합니다.

## 기여자

- 데이터 엔지니어링 팀

## 감사의 말

- 데이터셋 공개에 대한 Olist
- Apache Airflow, PostgreSQL 및 MinIO 오픈 소스 커뮤니티