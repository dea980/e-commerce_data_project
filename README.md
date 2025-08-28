# Olist E-Commerce Data Pipeline

Brazilian e-commerce 데이터를 처리하는 ETL 파이프라인입니다. Airflow로 오케스트레이션하고 PostgreSQL에 저장하는 구조로 되어있어요.

## Quick Start

```bash
# 1. 클론
git clone <repo-url>
cd e-commerce_data_project

# 2. 환경변수 설정
cp olist-pipeline/docker/.env.local .env
# .env 파일에서 DB 비밀번호 등 수정

# 3. 실행
cd olist-pipeline/docker
docker-compose -f docker-compose.improved.yml up -d

# 4. 확인
# Airflow: http://localhost:8080 (admin/admin)
# MinIO: http://localhost:9001 (minioadmin/minioadmin)
```

## 데이터 소스

Olist에서 제공하는 9개 CSV 파일을 사용합니다:

- **orders**: 주문 정보 (99,441건)
- **order_items**: 주문 상품 (112,650건) 
- **customers**: 고객 정보 (99,441건)
- **sellers**: 판매자 정보 (3,095건)
- **products**: 상품 정보 (32,951건)
- **reviews**: 리뷰 (104,719건)
- **payments**: 결제 정보 (103,886건)
- **geolocation**: 지역 정보 (1,000,163건)
- **product_category_translation**: 카테고리 번역 (71건)

## 아키텍처

3단계로 데이터를 처리합니다:

### 1. Raw Layer
- CSV 파일을 그대로 PostgreSQL에 로드
- 모든 컬럼을 TEXT로 저장 (스키마 변경 대응)
- 배치 ID, 수집 시간 등 메타데이터 추가

### 2. ODS Layer  
- 데이터 타입 변환 (TEXT → 적절한 타입)
- 기본적인 데이터 품질 체크
- 중복 제거, NULL 처리

### 3. Dimensional Layer
- 분석용 차원 테이블 생성
- 팩트 테이블과 차원 테이블 분리
- 인덱스 최적화

## DAG 구조

```
olist_raw_load → raw_to_ods → ods_dim
```

각 DAG는 이전 DAG 완료 후 자동으로 실행됩니다.

## 주요 파일들

```
olist-pipeline/
├── dag/                    # Airflow DAG들
│   ├── olist_raw_load.py   # CSV → Raw
│   ├── raw_to_ods.py       # Raw → ODS  
│   └── ods_dim.py          # ODS → Dimensional
├── sql/                    # SQL 스크립트들
│   ├── 00_raw_ddl.sql      # Raw 테이블 생성
│   ├── 10_ods_core_ddl.sql # ODS 테이블 생성
│   └── 20_ods_dim_ddl.sql  # 차원 테이블 생성
└── docker/                 # Docker 설정
    └── docker-compose.improved.yml
```

## 문제 해결

### 포트 충돌
```bash
# 8080 포트가 사용 중인 경우
lsof -ti:8080 | xargs kill -9
```

### 컨테이너 재시작
```bash
docker-compose -f docker-compose.improved.yml restart
```

### 로그 확인
```bash
# Airflow 로그
docker logs e-commerce_data_project-airflow-webserver-1

# PostgreSQL 로그  
docker logs e-commerce_data_project-postgres-1
```

### 데이터 품질 이슈
- Airflow UI에서 DAG 로그 확인
- `quarantine.bad_rows` 테이블에서 실패한 데이터 확인

## 개발 환경

- Python 3.12
- Apache Airflow 2.9.3
- PostgreSQL 15
- MinIO (S3 호환)

## 테스트

```bash
cd olist-pipeline/tests
./run_tests.sh
```

## 주의사항

- `.env` 파일에 민감한 정보가 있으니 `.gitignore`에 추가되어 있는지 확인
- 프로덕션에서는 기본 비밀번호 변경 필수
- 대용량 데이터 처리 시 메모리 모니터링 필요

## 라이센스

Olist Brazilian E-commerce Dataset을 사용합니다. 상업적 사용 시 적절한 출처 표시가 필요합니다.
