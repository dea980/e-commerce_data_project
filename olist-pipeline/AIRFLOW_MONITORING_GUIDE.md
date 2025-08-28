# Airflow를 통한 데이터 파이프라인 진단 및 모니터링

실시간 데이터 파이프라인 상태 확인 및 문제 진단 가이드입니다.

## 현재 실행 상태

### 성공적으로 실행된 서비스
```
PostgreSQL     → localhost:5432 (정상)
MinIO          → localhost:9000/9001 (정상)
Airflow        → localhost:8080 (정상)
Airflow Init   → 초기화 완료
스케줄러       → 실행 중
```

### 서비스 상태 요약
| 서비스 | 상태 | 포트 | 접속 정보 |
|--------|------|------|-----------|
| Airflow UI | 실행 중 | 8080 | admin/admin |
| MinIO Console | 실행 중 | 9001 | minio_access_key/minio_secret_key |
| PostgreSQL | 실행 중 | 5432 | olist_user/change_this_password |
| MinIO API | 실행 중 | 9000 | S3 호환 API |

## Airflow UI를 통한 시스템 진단

### 1. 기본 접속 및 확인
```
URL: http://localhost:8080
로그인: admin / admin
```

#### 첫 접속 시 확인사항
```
DAG 목록 확인:
- olist_raw_load (CSV → RAW)
- raw_to_ods (RAW → ODS + DQ)
- ods_dim (ODS → DIM)
- fact_gold_build (DIM → GOLD)

모든 DAG가 "Paused" 상태 확인
Connection 설정 확인 (Admin → Connections)
Variables 설정 확인 (Admin → Variables)
```

### 2. DAG 상태 모니터링

#### 전체 DAG 현황 (DAGs 페이지)
```
확인 가능한 정보:
- DAG 활성화 상태 (Paused/Unpaused)
- 최근 실행 상태 (Success/Failed/Running)
- 다음 실행 예정 시간
- 평균 실행 시간
- 실행 성공률
```

#### 개별 DAG 상세 분석 (Graph View)
```
DAG 클릭 → Graph View
확인 가능한 정보:
- Task 의존성 관계 시각화
- 각 Task 실행 상태 (색상으로 구분)
  - 성공 (Success)
  - 실패 (Failed)
  - 실행 중 (Running)
  - 대기 중 (Queued)
  - 비활성 (None)
- Task 실행 시간
- 재시도 횟수
```

### 3. Task 레벨 상세 진단

#### 개별 Task 분석
```
Graph View → Task 클릭 → "Log"
확인 가능한 정보:
- 상세 실행 로그
- 에러 메시지 및 스택 트레이스
- SQL 실행 결과
- 데이터 처리량
- 실행 환경 정보
```

#### Task Instance 상태
```
Browse → Task Instances
확인 가능한 정보:
- 모든 Task 실행 이력
- 실행 시간 분석
- 실패 패턴 분석
- 재시도 통계
```

## 데이터 품질 모니터링

### 1. Hard DQ (필수 품질 규칙) 모니터링

#### Airflow에서 확인
```
DAG: raw_to_ods → Task: dq_hard
로그에서 확인할 내용:
- PK 유일성 검사 결과
- FK 참조 무결성 결과
- 필수값 존재 확인 결과
- 실패 시 파이프라인 중단 여부
```

#### PostgreSQL에서 직접 확인
```sql
-- 최근 Hard DQ 결과 확인
SELECT 
    check_name,
    status,
    actual,
    expected,
    checked_at
FROM ops.dq_results 
WHERE level = 'hard' 
ORDER BY checked_at DESC 
LIMIT 10;
```

### 2. Soft DQ (권장 품질 규칙) 모니터링

#### Airflow에서 확인
```
DAG: raw_to_ods → Task: dq_soft
로그에서 확인할 내용:
- 음수 가격 비율 (< 5% 권장)
- 시간 순서 위반 건수
- 결제-주문 금액 오차율
- 데이터 신선도 체크
```

#### PostgreSQL에서 직접 확인
```sql
-- 최근 Soft DQ 결과 확인
SELECT 
    check_name,
    status,
    actual,
    threshold,
    checked_at,
    message
FROM ops.dq_results 
WHERE level = 'soft' 
ORDER BY checked_at DESC 
LIMIT 10;
```

## 실시간 시스템 진단

### 1. Airflow 시스템 메트릭

#### 스케줄러 상태 확인
```
Admin → System → Configuration
확인 가능한 정보:
- 스케줄러 실행 상태
- Worker 프로세스 수
- 큐에 대기 중인 Task 수
- 동시 실행 가능한 Task 수
- 메모리 사용량
```

#### 연결 상태 확인
```
Admin → Connections
확인 필요한 연결:
- postgres_default (PostgreSQL)
- s3_default (MinIO/S3)
- 각 연결의 Test 버튼으로 상태 확인
```

### 2. 데이터베이스 상태 진단

#### 스키마 및 테이블 확인
```sql
-- 생성된 스키마 확인
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name IN ('raw', 'ods', 'gold', 'ops', 'meta', 'quarantine');

-- 각 스키마별 테이블 수 확인
SELECT 
    schemaname,
    COUNT(*) as table_count
FROM pg_tables 
WHERE schemaname IN ('raw', 'ods', 'gold', 'ops', 'meta', 'quarantine')
GROUP BY schemaname;
```

#### 데이터 건수 및 품질 확인
```sql
-- RAW 계층 데이터 건수
SELECT 
    'customers' as table_name,
    COUNT(*) as row_count,
    MAX(_ingested_at) as last_updated
FROM raw.customers_raw
UNION ALL
SELECT 'orders', COUNT(*), MAX(_ingested_at) FROM raw.orders_raw
UNION ALL
SELECT 'order_items', COUNT(*), MAX(_ingested_at) FROM raw.order_items_raw;

-- ODS 계층 데이터 건수 (변환 후)
SELECT 
    'customers' as table_name,
    COUNT(*) as row_count
FROM ods.customers
UNION ALL
SELECT 'orders', COUNT(*) FROM ods.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM ods.order_items;
```

### 3. 성능 및 리소스 모니터링

#### Docker 컨테이너 리소스 사용량
```bash
# 실시간 리소스 모니터링
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

#### 데이터베이스 성능 확인
```sql
-- 활성 연결 수
SELECT 
    count(*) as active_connections,
    state
FROM pg_stat_activity 
GROUP BY state;

-- 테이블별 크기
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables 
WHERE schemaname IN ('raw', 'ods', 'gold')
ORDER BY size_bytes DESC;
```

## 알림 및 경고 시스템

### 1. Airflow 내장 알림

#### DAG 실패 시 확인사항
```
DAGs → Failed DAG 클릭
확인할 내용:
- 실패한 Task 식별
- 에러 메시지 분석
- 재시도 가능 여부
- 수동 재실행 필요성
- 의존성 Task 영향도
```

#### Task 재실행 방법
```
Graph View → 실패한 Task 클릭
가능한 액션:
- "Clear" → Task 상태 초기화 후 재실행
- "Mark Success" → 강제로 성공 처리
- "Mark Failed" → 강제로 실패 처리
- "Task Instance" → 상세 정보 확인
```

### 2. 데이터 품질 경고

#### Hard DQ 실패 대응
```sql
-- Hard DQ 실패 확인
SELECT * FROM ops.dq_results 
WHERE level = 'hard' AND status = 'fail'
ORDER BY checked_at DESC;
```

**대응 방법**:
1. 원인 분석: 실패한 규칙의 actual vs expected 확인
2. 데이터 확인: 해당 테이블의 원본 데이터 검토
3. 수정 후 재실행: 데이터 수정 또는 규칙 조정 후 DAG 재실행

#### Soft DQ 경고 모니터링
```sql
-- Soft DQ 경고 확인
SELECT * FROM ops.dq_results 
WHERE level = 'soft' AND status IN ('warn', 'fail')
ORDER BY checked_at DESC;
```

**대응 방법**:
1. 트렌드 분석: 경고 수치의 시간별 변화 확인
2. 임계값 검토: 비즈니스 요구사항에 맞는 임계값 조정
3. Slack 알림: 설정된 경우 자동 알림 확인

## 성능 최적화 진단

### 1. DAG 실행 시간 분석

#### Gantt Chart 활용
```
DAG → Gantt Chart
분석 포인트:
- 전체 DAG 실행 시간
- 병목 Task 식별
- 병렬 실행 효율성
- Task 간 대기 시간
- 리소스 사용 패턴
```

#### 실행 시간 최적화
```
최적화 방법:
- 느린 SQL 쿼리 튜닝
- 인덱스 추가 검토
- 병렬 처리 증대
- 메모리 할당 조정
- 배치 크기 최적화
```

### 2. 리소스 사용량 최적화

#### 메모리 사용량 모니터링
```bash
# Airflow 컨테이너 메모리 사용량
docker exec docker-airflow-webserver-1 free -h
docker exec docker-airflow-scheduler-1 free -h

# PostgreSQL 메모리 사용량
docker exec docker-postgres-1 free -h
```

#### CPU 사용률 분석
```bash
# CPU 사용률 실시간 모니터링
docker exec docker-airflow-scheduler-1 top -bn1 | head -20
```

## 일반적인 문제 해결

### 1. DAG 관련 문제

#### DAG가 보이지 않는 경우
```
해결 방법:
1. DAG 파일 마운트 확인:
   docker exec docker-airflow-webserver-1 ls -la /opt/airflow/dags/

2. 스케줄러 재시작:
   docker-compose -f docker/docker-compose.improved.yml restart airflow-scheduler

3. 파일 권한 확인:
   ls -la dag/
```

#### DAG 파싱 오류
```
Admin → DAGs → 오류 DAG 클릭
확인 내용:
- Python 문법 오류
- Import 오류
- Connection 설정 오류
- Variable 설정 오류
```

### 2. 연결 문제

#### PostgreSQL 연결 실패
```
해결 방법:
1. 컨테이너 상태 확인:
   docker-compose -f docker/docker-compose.improved.yml ps postgres

2. 연결 테스트:
   docker exec docker-postgres-1 pg_isready -U olist_user -d olist

3. Connection 재설정:
   Admin → Connections → postgres_default 수정
```

#### MinIO/S3 연결 실패
```
해결 방법:
1. MinIO 상태 확인:
   docker-compose -f docker/docker-compose.improved.yml ps minio

2. 버킷 존재 확인:
   docker exec docker-minio-1 mc ls myminio/

3. Connection 재설정:
   Admin → Connections → s3_default 수정
```

## 정기 점검 체크리스트

### 일일 점검 (Daily)
- [ ] 모든 DAG 실행 상태 확인
- [ ] Hard DQ 결과 확인 (실패 시 즉시 대응)
- [ ] Soft DQ 경고 트렌드 확인
- [ ] 시스템 리소스 사용량 확인
- [ ] 로그 에러 메시지 확인

### 주간 점검 (Weekly)
- [ ] DAG 실행 시간 트렌드 분석
- [ ] 데이터 품질 지표 리뷰
- [ ] 시스템 성능 최적화 검토
- [ ] 백업 상태 확인
- [ ] 보안 설정 점검

### 월간 점검 (Monthly)
- [ ] 전체 아키텍처 성능 리뷰
- [ ] 용량 계획 및 확장성 검토
- [ ] 데이터 보존 정책 점검
- [ ] 재해 복구 계획 테스트
- [ ] 문서 업데이트

## 핵심 모니터링 지표

### 즉시 대응 필요 (Critical)
- Hard DQ 실패
- DAG 연속 실패 (3회 이상)
- 데이터베이스 연결 실패
- 메모리 사용률 95% 이상

### 주의 필요 (Warning)
- Soft DQ 경고 증가
- DAG 실행 시간 2배 이상 증가
- CPU 사용률 80% 이상
- 디스크 사용률 85% 이상

### 정상 범위 (Normal)
- 모든 DAG 성공
- 데이터 품질 지표 정상
- 시스템 리소스 안정
- 응답 시간 정상

---

이제 Airflow를 통해 완전한 데이터 파이프라인 진단과 모니터링이 가능합니다. 이 가이드를 따라하시면 실시간으로 시스템 상태를 파악하고 문제를 조기에 발견하여 해결할 수 있습니다.

*작성일: 2025-08-27*
