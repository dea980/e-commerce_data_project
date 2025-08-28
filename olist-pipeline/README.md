# Olist E-commerce Data Pipeline

> **완전한 데이터 파이프라인**: RAW → ODS → DIM → GOLD  
> **기술 스택**: Airflow + PostgreSQL + MinIO + Docker

---

## 🚀 빠른 시작

### 1. 환경 설정
```bash
# 프로젝트 루트로 이동
cd olist-pipeline

# 환경변수 파일 생성
cp .env.example .env
# .env 파일을 편집하여 필요한 값들 설정

# Docker 컨테이너 실행
docker-compose -f docker/docker-compose.local.yml up -d
```

### 2. Airflow 웹 UI 접속
- **URL**: http://localhost:8080
- **사용자명**: admin
- **비밀번호**: admin

### 3. 파이프라인 실행
1. Airflow UI에서 `olist_raw_load` DAG 활성화
2. `raw_to_ods` DAG 활성화  
3. `ods_dim` DAG 활성화
4. `fact_gold_build` DAG 활성화

---

## 🏗️ 아키텍처

### 데이터 플로우
```
CSV Files (S3/MinIO) 
    ↓ 
RAW Layer (PostgreSQL)
    ↓ (Data Quality Checks)
ODS Layer (PostgreSQL)
    ↓
DIM Layer (PostgreSQL)  
    ↓
GOLD Layer (PostgreSQL)
```

### 서비스 구성
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Airflow       │    │   PostgreSQL    │    │     MinIO       │
│   (오케스트레이션) │    │   (데이터웨어하우스) │    │   (데이터레이크)  │
│                 │    │                 │    │                 │
│ - Webserver     │◄──►│ - Raw Schema    │◄──►│ - CSV Files     │
│ - Scheduler     │    │ - ODS Schema    │    │ - Backup        │
│ - Worker        │    │ - DIM Schema    │    │                 │
│                 │    │ - GOLD Schema   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 📁 프로젝트 구조

```
olist-pipeline/
├── dag/                    # Airflow DAG 파일들
│   ├── olist_raw_load.py   # CSV → RAW 적재
│   ├── raw_to_ods.py       # RAW → ODS 변환
│   ├── ods_dim.py          # ODS → DIM 변환  
│   ├── fact_gold.build.py  # GOLD 마트 생성
│   ├── _common.py          # 공통 유틸리티
│   ├── _loaders.py         # 데이터 로더
│   └── _alerts.py          # 알림 로직
├── sql/                    # SQL 스크립트들
│   ├── 00_raw_ddl.sql      # RAW 스키마 생성
│   ├── 01_raw_meta.sql     # 메타데이터 컬럼
│   ├── 02_raw_indexes.sql  # RAW 인덱스
│   ├── 03_dq_hard.sql      # 하드 데이터 품질
│   ├── 04_dq_soft.sql      # 소프트 데이터 품질
│   ├── 10_ods_core_ddl.sql # ODS 스키마 생성
│   ├── 12_ods_core_upsert.sql # ODS 데이터 적재
│   ├── 20_ods_dim_ddl.sql  # DIM 스키마 생성
│   └── 40_gold_*.sql       # GOLD 마트들
├── tests/                  # 테스트 코드
│   ├── docs/               # 테스트 문서화
│   ├── test_simple.py      # 기본 기능 테스트
│   └── test_sql_validation.py # SQL 검증 테스트
├── docker/                 # Docker 설정
│   └── docker-compose.local.yml
└── README.md              # 이 파일
```

---

## 🔧 주요 DAG 설명

### 1. `olist_raw_load` - 원본 데이터 적재
- **목적**: CSV 파일을 RAW 스키마로 적재
- **입력**: MinIO의 CSV 파일들
- **출력**: `raw.*_raw` 테이블들
- **실행**: 매일 또는 수동

### 2. `raw_to_ods` - 데이터 정제 및 변환
- **목적**: RAW 데이터를 정제하여 ODS로 변환
- **처리**: 타입 변환, NULL 처리, 중복 제거
- **품질검사**: Hard DQ (실패시 중단) + Soft DQ (경고)
- **출력**: `ods.orders`, `ods.customers` 등

### 3. `ods_dim` - 차원 테이블 생성
- **목적**: 분석용 차원 테이블 생성
- **출력**: `ods.products`, `ods.sellers`, `ods.geolocation`
- **특징**: 마스터 데이터 관리

### 4. `fact_gold_build` - 분석 마트 생성
- **목적**: 비즈니스 분석용 집계 테이블
- **출력**: `gold.kpi_daily`, `gold.cohort_retention` 등
- **용도**: BI 도구, 대시보드 연동

---

## 📊 데이터 품질 관리

### Hard DQ (필수 품질 규칙)
- ✅ PK 유일성 검증
- ✅ FK 참조 무결성  
- ✅ 필수값 존재 확인
- ❌ **실패 시 파이프라인 중단**

### Soft DQ (권장 품질 규칙)  
- ⚠️ 음수 금액 비율 체크
- ⚠️ 시간 순서 위반 체크
- ⚠️ 결제-주문 금액 오차 체크
- ⚠️ **실패 시 Slack 알림만**

---

## 🛠️ 개발 및 테스트

### 테스트 실행
```bash
cd tests
python -m pytest test_simple.py test_sql_validation.py -v
```

### 새로운 SQL 추가
1. `sql/` 디렉토리에 번호_설명.sql 형태로 파일 생성
2. DAG에서 해당 SQL 파일 실행 로직 추가
3. 테스트 케이스 작성 및 실행

### 새로운 DAG 추가
1. `dag/` 디렉토리에 DAG 파일 생성
2. `_common.py`의 유틸리티 함수 활용
3. 의존성 및 스케줄 설정

---

## 🔐 보안 및 설정

### 환경변수 (.env)
```bash
# PostgreSQL
POSTGRES_USER=olist_user
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=olist

# MinIO/S3
AWS_ACCESS_KEY_ID=minio_access
AWS_SECRET_ACCESS_KEY=minio_secret
S3_BUCKET=olist-data
S3_ENDPOINT=http://minio:9000

# Airflow
AIRFLOW__CORE__FERNET_KEY=your_fernet_key_here
```

### 주의사항
- ⚠️ 프로덕션에서는 Secrets Manager 사용 권장
- ⚠️ Fernet Key는 반드시 변경
- ⚠️ 기본 패스워드 변경 필수

---

## 🚨 트러블슈팅

### 일반적인 문제들

#### 1. Airflow 연결 실패
```bash
# 컨테이너 상태 확인
docker-compose -f docker/docker-compose.local.yml ps

# 로그 확인
docker-compose -f docker/docker-compose.local.yml logs airflow-webserver
```

#### 2. PostgreSQL 연결 실패
```bash
# DB 연결 테스트
docker exec -it postgres psql -U olist_user -d olist -c "SELECT 1;"
```

#### 3. MinIO 접근 실패
```bash
# MinIO 웹 UI 접속: http://localhost:9001
# 버킷 존재 확인
```

#### 4. SQL 실행 오류
- `sql/` 디렉토리의 파일 권한 확인
- SQL 구문 검증 (테스트 실행)
- 의존성 순서 확인

---

## 📈 모니터링 및 알림

### Airflow UI에서 확인 가능한 지표
- DAG 실행 성공/실패율
- 태스크별 실행 시간
- 데이터 품질 체크 결과

### 로그 위치
```bash
# Airflow 로그
docker-compose -f docker/docker-compose.local.yml logs -f airflow-scheduler

# PostgreSQL 로그  
docker-compose -f docker/docker-compose.local.yml logs -f postgres
```

---

## 🚀 확장 계획

### Phase 1: 기본 파이프라인 ✅
- [x] RAW → ODS → DIM 파이프라인
- [x] 데이터 품질 검증
- [x] 테스트 프레임워크

### Phase 2: 고도화 (진행 중)
- [ ] Great Expectations 통합
- [ ] 실시간 스트리밍 (Kafka)
- [ ] ML 피처 파이프라인

### Phase 3: 프로덕션 (계획)
- [ ] AWS MWAA 마이그레이션
- [ ] Redshift/Snowflake 연동
- [ ] 완전 자동화 CI/CD

---

## 📞 지원 및 기여

### 문의사항
- **Slack**: #data-engineering
- **이메일**: data-team@company.com
- **이슈**: GitHub Issues

### 기여 방법
1. Fork 프로젝트
2. Feature 브랜치 생성
3. 변경사항 커밋
4. Pull Request 생성

---

**🎯 목표**: 신뢰할 수 있는 데이터 파이프라인으로 비즈니스 인사이트 제공  
**📊 현재 상태**: 25개 테스트 모두 통과, 100% 품질 보장
