# 소프트웨어 설계 명세서 (SDS)
# Olist 이커머스 ETL 파이프라인

**버전:** 1.0  
**날짜:** 2025년 8월 26일  
**작성자:** 데이터 엔지니어링 팀

## 1. 소개

### 1.1 목적
이 소프트웨어 설계 명세서(SDS)는 Olist 이커머스 ETL 파이프라인의 상세한 기술적 설명을 제공합니다. 개발 및 유지보수를 안내하기 위해 시스템 아키텍처, 구성 요소, 인터페이스, 데이터 모델 및 구현 세부 사항을 설명합니다.

### 1.2 범위
이 문서는 브라질 Olist 이커머스 공개 데이터셋을 처리하기 위한 컨테이너화된 ETL 파이프라인의 설계를 다룹니다. 객체 스토리지에서의 데이터 추출, 여러 처리 계층을 통한 변환, 분석 목적의 관계형 데이터베이스로의 로딩에 대한 사양을 포함합니다.

### 1.3 정의, 약어 및 약어
- **ETL**: 추출, 변환, 적재 (Extract, Transform, Load)
- **DAG**: 방향성 비순환 그래프 (Directed Acyclic Graph)
- **ODS**: 운영 데이터 저장소 (Operational Data Store)
- **SCD**: 천천히 변화하는 차원 (Slowly Changing Dimension)
- **DDL**: 데이터 정의 언어 (Data Definition Language)
- **DQ**: 데이터 품질 (Data Quality)
- **RDBMS**: 관계형 데이터베이스 관리 시스템 (Relational Database Management System)

### 1.4 참조
- Apache Airflow 문서: https://airflow.apache.org/docs/
- PostgreSQL 문서: https://www.postgresql.org/docs/
- MinIO 문서: https://min.io/docs/minio/linux/index.html
- Docker 문서: https://docs.docker.com/
- Olist 데이터셋: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## 2. 시스템 아키텍처

### 2.1 아키텍처 개요

시스템은 다음과 같은 주요 구성 요소를 가진 컨테이너화된 마이크로서비스 아키텍처를 따릅니다:

1. **데이터 저장 계층**
   - MinIO: 원시 데이터 파일을 위한 S3 호환 객체 스토리지
   - PostgreSQL: 처리된 데이터를 위한 관계형 데이터베이스

2. **처리 계층**
   - Apache Airflow: 워크플로우 오케스트레이션 엔진
   - Python: 데이터 처리 스크립트
   - SQL: 데이터 변환 로직

3. **메달리온 아키텍처**
   - Bronze 계층 (Raw): 최소한의 변환으로 소스 데이터 보존
   - Silver 계층 (ODS): 스키마 적용 및 데이터 품질 검사 적용
   - Gold 계층 (Dimensional): 분석을 위한 차원 모델링 구현

### 2.2 구성 요소 다이어그램

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  MinIO Storage  │────▶│  Apache Airflow │────▶│   PostgreSQL    │
│  (Raw Data)     │     │  (Orchestration)│     │   (Processed    │
│                 │     │                 │     │    Data)        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               │
                               ▼
                        ┌─────────────────┐
                        │                 │
                        │  Docker Engine  │
                        │  (Container     │
                        │   Runtime)      │
                        │                 │
                        └─────────────────┘
```

### 2.3 컨테이너 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Network                         │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │               │  │               │  │               │    │
│  │ PostgreSQL    │  │ MinIO         │  │ Airflow       │    │
│  │ Container     │  │ Container     │  │ Webserver     │    │
│  │               │  │               │  │ Container     │    │
│  └───────────────┘  └───────────────┘  └───────────────┘    │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │               │  │               │  │               │    │
│  │ Airflow       │  │ Airflow Init  │  │ MinIO Setup   │    │
│  │ Scheduler     │  │ Container     │  │ Container     │    │
│  │ Container     │  │               │  │               │    │
│  └───────────────┘  └───────────────┘  └───────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 3. 데이터 아키텍처

### 3.1 데이터 흐름 다이어그램

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│           │     │           │     │           │     │           │
│  CSV      │────▶│  Raw      │────▶│  ODS      │────▶│  Dim      │
│  Files    │     │  Tables   │     │  Tables   │     │  Tables   │
│           │     │           │     │           │     │           │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
    MinIO           PostgreSQL        PostgreSQL        PostgreSQL
    Storage          raw schema        ods schema        dim schema
```

### 3.2 데이터 모델

#### 3.2.1 소스 데이터 모델
소스 데이터는 다음과 같은 엔티티 관계를 가진 9개의 CSV 파일로 구성됩니다:

```
                      ┌───────────┐
                      │           │
                      │ Customers │
                      │           │
                      └─────┬─────┘
                            │
                            │
┌───────────┐         ┌─────▼─────┐         ┌───────────┐
│           │         │           │         │           │
│ Payments  │◀────────│  Orders   │────────▶│  Reviews  │
│           │         │           │         │           │
└───────────┘         └─────┬─────┘         └───────────┘
                            │
                            │
                      ┌─────▼─────┐
                      │           │
                      │ Order     │
                      │ Items     │
                      │           │
                      └──┬─────┬──┘
                         │     │
                         │     │
                  ┌──────▼─┐ ┌─▼──────┐
                  │        │ │        │
                  │Products│ │Sellers │
                  │        │ │        │
                  └────────┘ └────────┘
```

#### 3.2.2 Raw 계층 데이터 모델
Raw 계층은 추가 메타데이터 열과 함께 소스 데이터 구조를 보존합니다:
- `_batch_id`: 처리 배치 추적을 위한 UUID
- `_src_key`: 객체 스토리지의 소스 파일 경로
- `_src_etag`: 변경 감지를 위한 ETag
- `_ingested_at`: 수집 타임스탬프

#### 3.2.3 ODS 계층 데이터 모델
ODS 계층은 다음을 포함하는 정규화된 관계형 모델을 구현합니다:
- 표준화된 데이터 타입
- 강제 제약 조건 (NOT NULL, 고유 키)
- 참조 무결성 (외래 키)
- 최적화된 열 순서

#### 3.2.4 차원 계층 데이터 모델
차원 계층은 다음을 포함하는 스타 스키마를 구현합니다:
- 팩트 테이블 (orders, order_items)
- 차원 테이블 (d_customer, d_product, d_seller, d_date)
- 시간에 따라 변화하는 차원을 위한 SCD Type 2

## 4. 구성 요소 설계

### 4.1 Apache Airflow

#### 4.1.1 DAG: olist_raw_load
**목적**: MinIO에서 데이터를 추출하여 PostgreSQL raw 테이블에 로드
**스케줄**: 수동 트리거 (이벤트 기반)
**태스크**:
1. `run_sql("00_raw_ddl")`: 존재하지 않는 경우 raw 테이블 생성
2. `run_sql("01_raw_meta")`: 메타데이터 열 추가
3. `run_sql("02_raw_indexes")`: raw 테이블에 인덱스 생성
4. `load_raw_streaming()`: MinIO에서 PostgreSQL로 데이터 스트리밍
5. `quick_checks()`: 기본 데이터 유효성 검사 수행
6. `trigger_raw_to_ods`: 다음 DAG 트리거

#### 4.1.2 DAG: raw_to_ods
**목적**: raw 데이터를 ODS 테이블로 변환
**스케줄**: olist_raw_load에 의해 트리거됨
**태스크**:
1. `run_sql_file("10_ods_core_ddl")`: 존재하지 않는 경우 ODS 테이블 생성
2. `run_sql_file("11_ods_core_indexes")`: ODS 테이블에 인덱스 생성
3. `run_sql_file("12_ods_core_upsert")`: raw에서 ODS로 데이터 변환 및 로드
4. `run_sql_with_batch("03_dq_hard")`: 중요 데이터 품질 검사 실행
5. `run_sql_with_batch("04_dq_soft")`: 비중요 데이터 품질 검사 실행
6. `trigger_dims`: 다음 DAG 트리거

#### 4.1.3 DAG: ods_dim
**목적**: ODS 테이블에서 차원 모델 생성
**스케줄**: raw_to_ods에 의해 트리거됨
**태스크**:
1. `run_sql("20_ods_dim_ddl")`: 존재하지 않는 경우 차원 테이블 생성
2. `run_sql("21_ods_dim_indexes")`: 차원 테이블에 인덱스 생성
3. `run_sql("22_ods_dim_upsert")`: ODS에서 차원 테이블로 데이터 변환 및 로드

### 4.2 PostgreSQL

#### 4.2.1 스키마 설계
- **raw**: 소스 데이터 구조를 미러링하는 테이블 포함
- **ods**: 정규화되고 정제된 데이터 포함
- **dim**: 분석을 위한 차원 모델 포함

#### 4.2.2 성능 최적화
- 각 계층에 적합한 인덱싱 전략
- 대용량 테이블(geolocation)에 대한 파티셔닝
- Vacuum 및 분석 스케줄링
- 연결 풀링

### 4.3 MinIO

#### 4.3.1 버킷 구조
- `olist-data`: 모든 Olist 데이터를 위한 루트 버킷
  - 루트 레벨에 저장된 원시 CSV 파일

#### 4.3.2 접근 패턴
- Airflow DAG에서의 읽기 전용 접근
- MinIO 설정 컨테이너를 통한 초기 데이터 로드

## 5. 인터페이스 설계

### 5.1 사용자 인터페이스

#### 5.1.1 Airflow 웹 UI
- **URL**: http://localhost:8080
- **인증**: 기본 인증 (사용자 이름/비밀번호)
- **주요 기능**:
  - DAG 모니터링 및 관리
  - 태스크 실행 기록
  - 로그 보기
  - 수동 트리거링

#### 5.1.2 MinIO 콘솔
- **URL**: http://localhost:9001
- **인증**: 기본 인증 (사용자 이름/비밀번호)
- **주요 기능**:
  - 버킷 관리
  - 객체 탐색
  - 접근 정책 구성

### 5.2 API 인터페이스

#### 5.2.1 Airflow REST API
- **기본 URL**: http://localhost:8080/api/v1
- **인증**: 기본 인증
- **주요 엔드포인트**:
  - `/dags`: DAG 목록 및 관리
  - `/dagRuns`: DAG 실행 목록 및 관리
  - `/tasks`: 태스크 목록 및 관리

#### 5.2.2 MinIO S3 API
- **기본 URL**: http://localhost:9000
- **인증**: AWS 서명 v4
- **주요 작업**:
  - `GetObject`: 버킷에서 객체 검색
  - `ListObjects`: 버킷의 객체 나열
  - `PutObject`: 버킷에 객체 업로드

## 6. 데이터 품질 프레임워크

### 6.1 데이터 품질 차원
- **완전성**: 필요한 모든 데이터가 존재하는지 확인
- **정확성**: 데이터 값이 정확한지 확인
- **일관성**: 테이블 간에 데이터가 일관되는지 확인
- **적시성**: 데이터가 예상 시간 내에 처리되는지 확인
- **고유성**: 예상치 못한 중복이 없는지 확인

### 6.2 데이터 품질 검사

#### 6.2.1 하드 검사 (중요)
- 기본 키 위반
- 외래 키 위반
- NOT NULL 제약 조건 위반
- 데이터 타입 위반
- 구현: 위반 시 파이프라인이 실패하는 SQL 어설션

#### 6.2.2 소프트 검사 (비중요)
- 값 범위 유효성 검사
- 패턴 매칭
- 통계적 이상치 감지
- 구현: 경고를 기록하지만 파이프라인이 계속 진행되도록 하는 SQL 쿼리

### 6.3 데이터 품질 모니터링
- 전용 DQ 테이블에 저장된 메트릭
- 처리 배치 간 추세 분석
- Slack 통합을 통한 알림

## 7. 배포 사양

### 7.1 Docker 컨테이너

#### 7.1.1 PostgreSQL 컨테이너
- **이미지**: postgres:15
- **환경 변수**:
  - POSTGRES_USER: kdea989
  - POSTGRES_PASSWORD: Kdea504605
  - POSTGRES_DB: olist
- **볼륨**:
  - postgres-db-volume:/var/lib/postgresql/data
- **상태 확인**: pg_isready 명령

#### 7.1.2 MinIO 컨테이너
- **이미지**: minio/minio
- **포트**:
  - 9000: S3 API
  - 9001: 웹 콘솔
- **환경 변수**:
  - MINIO_ROOT_USER: kdea989
  - MINIO_ROOT_PASSWORD: Kdea504605
- **명령**: server /data --console-address ":9001"
- **상태 확인**: /minio/health/live에 대한 HTTP 요청

#### 7.1.3 Airflow 웹서버 컨테이너
- **이미지**: apache/airflow:2.9.3
- **포트**:
  - 8080: 웹 UI
- **환경 변수**:
  - AIRFLOW__CORE__EXECUTOR: LocalExecutor
  - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://kdea989:Kdea504605@postgres:5432/olist
  - 추가 구성 변수
- **볼륨**:
  - ./olist-pipeline/dag:/opt/airflow/dags
  - ./olist-pipeline/sql:/opt/airflow/sql
  - ./data:/opt/airflow/data
- **상태 확인**: /health에 대한 HTTP 요청

#### 7.1.4 Airflow 스케줄러 컨테이너
- **이미지**: apache/airflow:2.9.3
- **환경 변수**: 웹서버와 동일
- **볼륨**: 웹서버와 동일
- **명령**: airflow scheduler

#### 7.1.5 Airflow 초기화 컨테이너
- **이미지**: apache/airflow:2.9.3
- **목적**: Airflow 데이터베이스 초기화 및 사용자 생성
- **명령**: 
  ```
  airflow db migrate;
  airflow users create --username kdea989 --password Kdea504605 --firstname Daeyeop --lastname Kim --role Admin --email kdea989@gmail.com
  ```

#### 7.1.6 MinIO 설정 컨테이너
- **이미지**: minio/mc
- **목적**: MinIO 구성 및 초기 데이터 로드
- **명령**:
  ```
  mc alias set myminio http://minio:9000 kdea989 Kdea504605;
  mc mb myminio/olist-data --ignore-existing;
  mc cp --recursive /data/raw/ myminio/olist-data/;
  ```

### 7.2 네트워크 구성
- **네트워크 이름**: airflow-network
- **드라이버**: bridge
- **서비스 검색**: 컨테이너 이름 해결

### 7.3 볼륨 구성
- **postgres-db-volume**: PostgreSQL 데이터를 위한 영구 볼륨

### 7.4 리소스 요구사항
- **CPU**: 최소 2코어 권장
- **메모리**: 최소 4GB RAM
- **디스크**: 최소 5GB 여유 공간

## 8. 테스트 전략

### 8.1 단위 테스트
- 사용자 정의 연산자 및 함수에 대한 Python 단위 테스트
- 변환 로직에 대한 SQL 단위 테스트

### 8.2 통합 테스트
- 엔드투엔드 DAG 실행 테스트
- 데이터베이스 스키마 유효성 검사 테스트
- 데이터 품질 검사 유효성 검사

### 8.3 성능 테스트
- 전체 데이터셋으로 부하 테스트
- 여러 DAG 실행에 대한 동시성 테스트
- 리소스 사용률 모니터링

## 9. 보안 고려사항

### 9.1 인증
- Airflow 및 MinIO에 대한 기본 인증
- 안전한 비밀번호 저장

### 9.2 권한 부여
- Airflow의 역할 기반 접근 제어
- MinIO의 버킷 정책

### 9.3 데이터 보호
- Docker 네트워크를 통한 네트워크 격리
- 호스트에 PostgreSQL 포트 노출 없음
- 민감한 환경 변수의 암호화

## 10. 유지보수 및 운영

### 10.1 로깅
- Docker 로깅 드라이버를 통한 중앙 집중식 로깅
- 컨테이너 파일 시스템의 애플리케이션별 로그
- 로그 순환 및 보존 정책

### 10.2 모니터링
- 컨테이너 상태 모니터링
- DAG 실행 모니터링
- 데이터베이스 성능 모니터링

### 10.3 백업 및 복구
- PostgreSQL 데이터베이스 백업
- MinIO 버킷 스냅샷
- Docker 볼륨 백업

### 10.4 확장 고려사항
- Airflow 작업자에 대한 수평적 확장
- PostgreSQL에 대한 수직적 확장
- 데이터베이스 접근을 위한 연결 풀링

## 11. 부록

### 11.1 SQL 스크립트
SQL 변환 스크립트에 대한 상세 문서

### 11.2 환경 변수
환경 변수 및 그 목적의 전체 목록

### 11.3 문제 해결 가이드
일반적인 문제 및 해결책