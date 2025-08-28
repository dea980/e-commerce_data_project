# 🚀 로컬 실행 가이드: Airflow + MinIO

> **완전한 로컬 개발 환경 구축 가이드**  
> Airflow와 MinIO를 로컬에서 실행하고 데이터 파이프라인 진단하기

---

## 🎯 실행 개요

### 실행 후 얻을 수 있는 것
- ✅ **완전한 데이터 파이프라인** 로컬 실행
- ✅ **Airflow 웹 UI**를 통한 DAG 모니터링
- ✅ **MinIO 콘솔**을 통한 데이터 관리
- ✅ **PostgreSQL**에서 실시간 데이터 확인
- ✅ **데이터 품질 대시보드** 모니터링
- ✅ **실시간 로그 및 메트릭** 확인

### 서비스 구성
```
🌐 Airflow UI     → http://localhost:8080 (admin/admin)
🗄️ MinIO Console  → http://localhost:9001 (env 설정값)
🐘 PostgreSQL     → localhost:5432 (env 설정값)
📊 실시간 로그     → Docker 컨테이너 로그
```

---

## 📋 사전 준비사항

### 1. Docker Desktop 설치 및 실행
```bash
# Docker 상태 확인
docker --version
docker-compose --version

# Docker Desktop 실행 확인
docker info
```

### 2. 시스템 요구사항
- **메모리**: 최소 4GB, 권장 8GB
- **디스크**: 최소 10GB 여유 공간
- **포트**: 8080, 9000, 9001, 5432 사용 가능

### 3. 프로젝트 준비
```bash
cd /Users/daeyeop/Desktop/e-commerce_data_project/olist-pipeline
```

---

## 🚀 단계별 실행 가이드

### Step 1: 환경 설정 (30초)
```bash
# 환경변수 파일 생성
cp env.example .env

# .env 파일 편집 (필요시)
nano .env
```

**주요 환경변수**:
```bash
# PostgreSQL
POSTGRES_USER=olist_user
POSTGRES_PASSWORD=change_this_password
POSTGRES_DB=olist

# MinIO
AWS_ACCESS_KEY_ID=minio_access_key
AWS_SECRET_ACCESS_KEY=minio_secret_key
S3_BUCKET=olist-data

# Airflow
AIRFLOW__CORE__FERNET_KEY=8Hk9x0KWhFaMF3RzIjzDNUW-OW_V_CtnJ2OlYGfJGw4=
```

### Step 2: 파이프라인 시작 (2-3분)
```bash
# 전체 파이프라인 시작
./scripts/start.sh

# 또는 깨끗한 시작 (기존 데이터 삭제)
./scripts/start.sh --clean
```

**실행 과정**:
1. 🐳 Docker 컨테이너 시작
2. 🗄️ PostgreSQL 초기화
3. 📦 MinIO 설정 및 데이터 업로드
4. ✈️ Airflow 초기화
5. 🔍 헬스체크 수행

### Step 3: 서비스 확인 (1분)
```bash
# 서비스 상태 확인
docker-compose -f docker/docker-compose.improved.yml ps

# 로그 확인
docker-compose -f docker/docker-compose.improved.yml logs -f
```

---

## 🌐 웹 UI 접속 가이드

### 1. Airflow 웹 UI
**URL**: http://localhost:8080
**로그인**: admin / admin

#### 주요 기능
- **DAGs**: 모든 데이터 파이프라인 확인
- **Graph View**: DAG 의존성 시각화
- **Gantt Chart**: 실행 시간 분석
- **Task Instance**: 개별 태스크 상태
- **Logs**: 상세 실행 로그

#### 첫 접속 시 확인사항
```
1. DAG 목록에서 다음 DAG들 확인:
   - olist_raw_load
   - raw_to_ods  
   - ods_dim
   - fact_gold_build

2. 모든 DAG가 "Paused" 상태인지 확인
3. Connection 설정 확인 (Admin → Connections)
```

### 2. MinIO Console
**URL**: http://localhost:9001
**로그인**: env 파일의 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

#### 주요 기능
- **Buckets**: 데이터 버킷 관리
- **Object Browser**: 파일 업로드/다운로드
- **Monitoring**: 스토리지 사용량
- **Access Keys**: 접근 키 관리

#### 확인사항
```
1. olist-data 버킷 존재 확인
2. raw/ 폴더에 CSV 파일들 확인:
   - olist_customers_dataset.csv
   - olist_orders_dataset.csv
   - olist_order_items_dataset.csv
   - 기타 CSV 파일들
```

### 3. PostgreSQL 접속
```bash
# 컨테이너 내부에서 접속
docker exec -it $(docker-compose -f docker/docker-compose.improved.yml ps -q postgres) \
  psql -U olist_user -d olist

# 외부 도구에서 접속
# Host: localhost
# Port: 5432  
# Database: olist
# Username: olist_user
# Password: (env 파일의 값)
```

---

## 🔄 DAG 실행 순서

### 1. 초기 연결 설정 확인
Airflow UI → Admin → Connections에서 확인:

```
Connection ID: postgres_default
Connection Type: Postgres
Host: postgres
Schema: olist  
Login: olist_user
Password: (env 파일 값)
Port: 5432
```

### 2. DAG 실행 순서
```
1️⃣ olist_raw_load (CSV → RAW)
   ↓ 완료 후
2️⃣ raw_to_ods (RAW → ODS + 데이터 품질 검사)
   ↓ 완료 후  
3️⃣ ods_dim (ODS → DIM)
   ↓ 완료 후
4️⃣ fact_gold_build (DIM → GOLD)
```

### 3. 각 DAG별 실행 방법

#### A. olist_raw_load 실행
```
1. Airflow UI에서 "olist_raw_load" DAG 클릭
2. 우측 상단 "Unpause" 버튼 클릭 (토글 활성화)
3. "Trigger DAG" 버튼 클릭
4. Graph View에서 실행 상태 모니터링
```

**예상 실행 시간**: 2-3분
**확인 포인트**:
- ✅ raw_ddl 태스크 성공
- ✅ 모든 CSV 로드 태스크 성공
- ✅ raw_indexes, dq_hard, dq_soft 성공

#### B. raw_to_ods 실행
```
1. olist_raw_load 완료 후 실행
2. "raw_to_ods" DAG 활성화 및 트리거
3. 데이터 품질 검사 결과 모니터링
```

**예상 실행 시간**: 1-2분
**확인 포인트**:
- ✅ ODS 테이블 생성 성공
- ✅ 데이터 변환 성공
- ✅ Hard DQ 검사 통과
- ✅ Soft DQ 경고 확인

---

## 📊 모니터링 및 진단

### 1. Airflow를 통한 시스템 진단

#### A. DAG 실행 상태 모니터링
```
📍 위치: Airflow UI → DAGs
📊 확인 가능한 정보:
- DAG 실행 성공/실패율
- 평균 실행 시간
- 최근 실행 이력
- 실행 중인 태스크 수
```

#### B. Task 레벨 상세 분석
```
📍 위치: DAG → Graph View → 개별 Task 클릭
📊 확인 가능한 정보:
- Task 실행 시간
- 로그 메시지
- 리트라이 횟수
- 실행 환경 정보
```

#### C. 시스템 리소스 모니터링
```bash
# 컨테이너 리소스 사용량
docker stats

# 개별 서비스 상태
docker-compose -f docker/docker-compose.improved.yml ps

# 디스크 사용량
docker system df
```

### 2. 데이터 품질 진단

#### A. Hard DQ (필수 품질 규칙) 확인
```sql
-- PostgreSQL에서 실행
SELECT * FROM ops.dq_results 
WHERE level = 'hard' 
ORDER BY checked_at DESC 
LIMIT 10;
```

**확인 항목**:
- ✅ PK 유일성 검사
- ✅ FK 참조 무결성
- ✅ 필수값 존재 확인
- ❌ 실패 시 파이프라인 중단

#### B. Soft DQ (권장 품질 규칙) 확인
```sql
-- PostgreSQL에서 실행
SELECT * FROM ops.dq_results 
WHERE level = 'soft' 
ORDER BY checked_at DESC 
LIMIT 10;
```

**확인 항목**:
- ⚠️ 음수 가격 비율
- ⚠️ 시간 순서 위반
- ⚠️ 결제-주문 금액 오차
- ⚠️ 데이터 신선도

### 3. 데이터 현황 확인

#### A. 각 계층별 데이터 건수
```sql
-- RAW 계층
SELECT 'raw.orders_raw' as table_name, COUNT(*) as row_count FROM raw.orders_raw
UNION ALL
SELECT 'raw.customers_raw', COUNT(*) FROM raw.customers_raw
UNION ALL  
SELECT 'raw.order_items_raw', COUNT(*) FROM raw.order_items_raw;

-- ODS 계층
SELECT 'ods.orders' as table_name, COUNT(*) as row_count FROM ods.orders
UNION ALL
SELECT 'ods.customers', COUNT(*) FROM ods.customers
UNION ALL
SELECT 'ods.order_items', COUNT(*) FROM ods.order_items;

-- GOLD 계층 (실행 후)
SELECT 'gold.kpi_daily' as table_name, COUNT(*) as row_count FROM gold.kpi_daily
UNION ALL
SELECT 'gold.cohort_monthly_retention', COUNT(*) FROM gold.cohort_monthly_retention;
```

#### B. 데이터 변환 품질 확인
```sql
-- 데이터 변환 성공률
SELECT 
    'RAW to ODS' as transformation,
    (SELECT COUNT(*) FROM ods.orders) as target_count,
    (SELECT COUNT(*) FROM raw.orders_raw) as source_count,
    ROUND(100.0 * (SELECT COUNT(*) FROM ods.orders) / (SELECT COUNT(*) FROM raw.orders_raw), 2) as success_rate_pct;
```

---

## 🔍 실시간 로그 모니터링

### 1. 전체 서비스 로그
```bash
# 모든 서비스 로그 (실시간)
docker-compose -f docker/docker-compose.improved.yml logs -f

# 특정 서비스만
docker-compose -f docker/docker-compose.improved.yml logs -f airflow-scheduler
docker-compose -f docker/docker-compose.improved.yml logs -f postgres
docker-compose -f docker/docker-compose.improved.yml logs -f minio
```

### 2. Airflow 특화 로그
```bash
# Airflow 스케줄러 로그
docker-compose -f docker/docker-compose.improved.yml logs -f airflow-scheduler

# Airflow 웹서버 로그  
docker-compose -f docker/docker-compose.improved.yml logs -f airflow-webserver

# 특정 DAG 실행 로그 (Airflow UI에서 확인)
```

### 3. 로그 레벨별 필터링
```bash
# ERROR 레벨만 확인
docker-compose -f docker/docker-compose.improved.yml logs | grep ERROR

# WARNING 레벨 확인
docker-compose -f docker/docker-compose.improved.yml logs | grep -E "(WARN|WARNING)"
```

---

## 📈 성능 및 메트릭 확인

### 1. Airflow 메트릭

#### A. DAG 성능 지표
```
📍 위치: Airflow UI → DAGs → Gantt Chart
📊 확인 가능한 정보:
- 각 Task 실행 시간
- 병렬 실행 효율성
- 전체 DAG 실행 시간
- 병목 지점 식별
```

#### B. Task 실패 분석
```
📍 위치: Airflow UI → Browse → Task Instances
📊 확인 가능한 정보:
- 실패한 Task 목록
- 실패 원인 및 로그
- 재시도 패턴
- 실패 빈도 분석
```

### 2. 시스템 리소스 메트릭
```bash
# CPU, 메모리 사용률 실시간 모니터링
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# 디스크 사용량
docker system df -v

# 네트워크 사용량
docker-compose -f docker/docker-compose.improved.yml top
```

### 3. 데이터베이스 성능
```sql
-- 활성 연결 수
SELECT count(*) as active_connections 
FROM pg_stat_activity 
WHERE state = 'active';

-- 테이블별 크기
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname IN ('raw', 'ods', 'gold')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 쿼리 성능 통계
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;
```

---

## 🚨 문제 해결 가이드

### 1. 일반적인 문제들

#### A. Airflow UI 접속 안됨
```bash
# 웹서버 상태 확인
docker-compose -f docker/docker-compose.improved.yml ps airflow-webserver

# 로그 확인
docker-compose -f docker/docker-compose.improved.yml logs airflow-webserver

# 재시작
docker-compose -f docker/docker-compose.improved.yml restart airflow-webserver
```

#### B. DAG가 보이지 않음
```bash
# DAG 폴더 마운트 확인
docker exec -it $(docker-compose -f docker/docker-compose.improved.yml ps -q airflow-webserver) \
  ls -la /opt/airflow/dags/

# 스케줄러 재시작
docker-compose -f docker/docker-compose.improved.yml restart airflow-scheduler
```

#### C. PostgreSQL 연결 실패
```bash
# PostgreSQL 상태 확인
docker-compose -f docker/docker-compose.improved.yml ps postgres

# 연결 테스트
docker exec -it $(docker-compose -f docker/docker-compose.improved.yml ps -q postgres) \
  pg_isready -U olist_user -d olist
```

### 2. 데이터 품질 문제

#### A. Hard DQ 실패
```sql
-- 최근 Hard DQ 실패 확인
SELECT * FROM ops.dq_results 
WHERE level = 'hard' AND status = 'fail'
ORDER BY checked_at DESC;
```

**해결 방법**:
1. 원본 데이터 확인
2. 데이터 정합성 수정
3. DAG 재실행

#### B. Soft DQ 경고
```sql
-- Soft DQ 경고 확인
SELECT * FROM ops.dq_results 
WHERE level = 'soft' AND status = 'fail'
ORDER BY checked_at DESC;
```

**해결 방법**:
1. 데이터 품질 트렌드 분석
2. 임계값 조정 검토
3. 비즈니스 룰 재검토

---

## 🛑 안전한 종료

### 1. 정상 종료
```bash
# 데이터 보존하며 종료
./scripts/stop.sh
```

### 2. 완전 정리
```bash
# 모든 데이터 삭제하며 종료
./scripts/stop.sh --clean
```

### 3. 수동 종료
```bash
# Docker Compose 종료
docker-compose -f docker/docker-compose.improved.yml down

# 볼륨까지 삭제
docker-compose -f docker/docker-compose.improved.yml down -v
```

---

## 📊 실행 체크리스트

### ✅ 실행 전 체크리스트
- [ ] Docker Desktop 실행됨
- [ ] 포트 8080, 9000, 9001, 5432 사용 가능
- [ ] .env 파일 설정 완료
- [ ] 최소 4GB 메모리 여유 공간
- [ ] 최소 10GB 디스크 여유 공간

### ✅ 실행 후 체크리스트
- [ ] Airflow UI 접속 가능 (http://localhost:8080)
- [ ] MinIO Console 접속 가능 (http://localhost:9001)
- [ ] PostgreSQL 연결 가능
- [ ] 모든 DAG가 목록에 표시됨
- [ ] MinIO에 CSV 파일들 업로드됨

### ✅ DAG 실행 체크리스트
- [ ] olist_raw_load 성공적으로 완료
- [ ] raw 스키마에 데이터 적재됨
- [ ] raw_to_ods 성공적으로 완료
- [ ] ods 스키마에 데이터 변환됨
- [ ] 데이터 품질 검사 통과
- [ ] 모든 로그에 오류 없음

---

## 🎯 다음 단계

### 개발 작업
1. **DAG 수정**: `dag/` 폴더에서 파일 수정 후 자동 반영
2. **SQL 개선**: `sql/` 폴더에서 스크립트 수정
3. **테스트 실행**: `./scripts/test.sh`로 품질 검증
4. **로그 모니터링**: 실시간 로그로 동작 확인

### 운영 최적화
1. **성능 튜닝**: 느린 Task 식별 및 최적화
2. **알림 설정**: Slack 웹훅 설정으로 실패 알림
3. **모니터링 강화**: Grafana 대시보드 추가
4. **백업 설정**: 정기적인 데이터 백업 스케줄

---

**🎉 이제 완전한 로컬 데이터 파이프라인을 실행하고 모니터링할 수 있습니다!**

모든 단계를 따라하시면 **Airflow를 통한 완전한 데이터 파이프라인 진단과 모니터링**이 가능합니다.

*작성일: 2025-08-27*  
*버전: v1.0*
