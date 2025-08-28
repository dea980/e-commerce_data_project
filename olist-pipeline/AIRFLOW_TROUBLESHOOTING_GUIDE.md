# Airflow 문제 진단 및 해결 가이드

Airflow에서 데이터 파이프라인 실행 시 발생하는 문제들을 진단하고 해결하는 방법입니다.

## 1. 기본 상태 확인

### Docker 컨테이너 상태 확인
```bash
cd olist-pipeline/docker
docker-compose -f docker-compose.improved.yml ps
```

**정상 상태:**
- 모든 서비스가 "Up" 상태
- Health check가 "healthy" 상태

### 서비스 접속 정보
```
Airflow UI: http://localhost:8080 (admin/admin)
MinIO Console: http://localhost:9001 (minioadmin/minioadmin)
PostgreSQL: localhost:5432 (olist_user/비밀번호)
```

## 2. 파일 마운트 확인

### DAG 파일 확인
```bash
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/dags/
```

**예상 결과:**
```
olist_raw_load.py
raw_to_ods.py
ods_dim.py
fact_gold.build.py
_common.py
_loaders.py
_alerts.py
```

### SQL 파일 확인
```bash
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/sql/
```

**예상 결과:**
```
00_raw_ddl.sql
01_raw_meta.sql
02_raw_indexes.sql
03_dq_hard.sql
...
```

### 데이터 파일 확인
```bash
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/data/raw/
```

**예상 결과:**
```
olist_customers_dataset.csv
olist_orders_dataset.csv
olist_order_items_dataset.csv
...
```

## 3. DAG 상태 확인

### DAG 목록 확인
```bash
docker exec docker-airflow-webserver-1 airflow dags list
```

**정상 결과:**
```
dag_id          | fileloc                              | owners  | is_paused
================+======================================+=========+==========
fact_gold_build | /opt/airflow/dags/fact_gold.build.py | airflow | False    
ods_dim         | /opt/airflow/dags/ods_dim.py         | airflow | False    
olist_raw_load  | /opt/airflow/dags/olist_raw_load.py  | airflow | False    
raw_to_ods      | /opt/airflow/dags/raw_to_ods.py      | airflow | False    
```

### DAG 실행 이력 확인
```bash
docker exec docker-airflow-webserver-1 airflow dags list-runs -d olist_raw_load
```

**문제 지표:**
- 많은 failed runs
- queued 상태로 멈춰있는 runs

## 4. 데이터베이스 상태 확인

### 테이블 존재 확인
```bash
docker exec -it docker-postgres-1 psql -U olist_user -d olist -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('raw', 'ods', 'gold') ORDER BY schemaname, tablename;"
```

**정상 결과:**
```
 schemaname | tablename 
------------+-----------
 raw        | customers_raw
 raw        | orders_raw
 raw        | order_items_raw
...
```

## 5. 로그 확인

### 스케줄러 로그
```bash
docker logs docker-airflow-scheduler-1 --tail 20
```

**확인할 내용:**
- Task 실행 상태
- 오류 메시지
- 실행 시간

### 웹서버 로그
```bash
docker logs docker-airflow-webserver-1 --tail 20
```

**확인할 내용:**
- DAG 파싱 오류
- 연결 문제

## 6. DAG 실행 및 모니터링

### DAG 실행
```bash
docker exec docker-airflow-webserver-1 airflow dags trigger olist_raw_load
```

### 실행 상태 확인
```bash
docker exec docker-airflow-webserver-1 airflow dags state olist_raw_load [execution_date]
```

**상태 종류:**
- queued: 대기 중
- running: 실행 중
- success: 성공
- failed: 실패

### Task 상태 확인
```bash
docker exec docker-airflow-webserver-1 airflow tasks states-for-dag-run olist_raw_load [run_id]
```

## 7. 일반적인 문제 해결

### 문제 1: DAG가 보이지 않음
**원인:** DAG 파일 파싱 오류
**해결:**
```bash
# DAG 파일 권한 확인
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/dags/

# 스케줄러 재시작
docker-compose -f docker-compose.improved.yml restart airflow-scheduler
```

### 문제 2: Task가 queued 상태로 멈춤
**원인:** 스케줄러 문제 또는 의존성 문제
**해결:**
```bash
# 스케줄러 로그 확인
docker logs docker-airflow-scheduler-1 --tail 50

# Task 상태 초기화
docker exec docker-airflow-webserver-1 airflow tasks clear olist_raw_load --yes
```

### 문제 3: PostgreSQL 연결 실패
**원인:** Connection 설정 문제
**해결:**
```bash
# PostgreSQL 상태 확인
docker exec docker-postgres-1 pg_isready -U olist_user -d olist

# 연결 테스트
docker exec -it docker-postgres-1 psql -U olist_user -d olist -c "SELECT 1;"
```

### 문제 4: 파일 마운트 문제
**원인:** 볼륨 마운트 실패
**해결:**
```bash
# 컨테이너 재시작
docker-compose -f docker-compose.improved.yml restart airflow-webserver airflow-scheduler

# 마운트 확인
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/sql/
```

## 8. 단계별 실행 순서

### 1단계: 환경 확인
```bash
# 1. 컨테이너 상태 확인
docker-compose -f docker-compose.improved.yml ps

# 2. 파일 마운트 확인
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/dags/
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/sql/
docker exec docker-airflow-webserver-1 ls -la /opt/airflow/data/raw/
```

### 2단계: DAG 상태 확인
```bash
# 1. DAG 목록 확인
docker exec docker-airflow-webserver-1 airflow dags list

# 2. DAG 실행 이력 확인
docker exec docker-airflow-webserver-1 airflow dags list-runs -d olist_raw_load
```

### 3단계: 문제 해결
```bash
# 1. 기존 실행 상태 초기화
docker exec docker-airflow-webserver-1 airflow tasks clear olist_raw_load --yes

# 2. 새 DAG 실행
docker exec docker-airflow-webserver-1 airflow dags trigger olist_raw_load

# 3. 실행 상태 모니터링
docker exec docker-airflow-webserver-1 airflow dags state olist_raw_load [execution_date]
```

### 4단계: 결과 확인
```bash
# 1. 테이블 생성 확인
docker exec -it docker-postgres-1 psql -U olist_user -d olist -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('raw', 'ods', 'gold') ORDER BY schemaname, tablename;"

# 2. 데이터 적재 확인
docker exec -it docker-postgres-1 psql -U olist_user -d olist -c "SELECT COUNT(*) FROM raw.customers_raw;"
```

## 9. 브라우저에서 확인할 사항

### Airflow UI (http://localhost:8080)
1. **DAG 목록 페이지**
   - 모든 DAG가 보이는지 확인
   - DAG 상태 (Paused/Unpaused)
   - 성공/실패 통계

2. **개별 DAG 페이지**
   - Graph View에서 task 의존성 확인
   - Task 상태 (색상으로 구분)
   - 실패한 task 클릭 → Log 확인

3. **Admin → Connections**
   - `postgres_default` 연결 설정 확인
   - Test 버튼으로 연결 테스트

4. **Datasets 페이지**
   - 데이터셋이 생성되었는지 확인
   - "No Data found" 메시지 해결 여부

## 10. 성공 지표

### 정상 실행 시 확인할 사항
1. **DAG 실행 성공**
   - 모든 task가 녹색(성공) 상태
   - 실패한 task 없음

2. **데이터베이스 테이블 생성**
   - raw, ods, gold 스키마에 테이블 존재
   - 데이터가 적재됨

3. **Datasets 생성**
   - Datasets 페이지에 데이터셋 표시
   - "No Data found" 메시지 사라짐

4. **로그 확인**
   - 오류 메시지 없음
   - 정상적인 실행 로그

---

이 가이드를 따라 단계별로 확인하면서 문제를 진단하고 해결할 수 있습니다.
