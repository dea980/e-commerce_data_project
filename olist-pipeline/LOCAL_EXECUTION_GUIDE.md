# 로컬 실행 가이드

Airflow와 MinIO를 로컬에서 실행하는 방법입니다.

## 빠른 시작

```bash
# 1. 환경변수 설정
cd olist-pipeline/docker
cp .env.local .env
# .env 파일에서 비밀번호 수정

# 2. 실행
docker-compose -f docker-compose.improved.yml up -d

# 3. 확인
# Airflow: http://localhost:8080 (admin/admin)
# MinIO: http://localhost:9001 (minioadmin/minioadmin)
```

## 서비스 접속

| 서비스 | URL | 계정 |
|--------|-----|------|
| Airflow | http://localhost:8080 | admin/admin |
| MinIO | http://localhost:9001 | minioadmin/minioadmin |
| PostgreSQL | localhost:5432 | olist_user/비밀번호 |

## DAG 실행 순서

1. **olist_raw_load** - CSV 파일을 raw 테이블에 로드
2. **raw_to_ods** - raw → ods 변환 + 데이터 품질 체크
3. **ods_dim** - ods → 차원 테이블 변환

### 실행 방법

```bash
# 1. Airflow UI 접속
# 2. DAG 목록에서 "olist_raw_load" 클릭
# 3. 우측 상단 "Unpause" 버튼 클릭
# 4. "Trigger DAG" 버튼 클릭
# 5. Graph View에서 진행상황 확인
```

## 문제 해결

### 포트 충돌
```bash
# 8080 포트 사용 중인 프로세스 종료
lsof -ti:8080 | xargs kill -9
```

### 컨테이너 재시작
```bash
docker-compose -f docker-compose.improved.yml restart
```

### 로그 확인
```bash
# 전체 로그
docker-compose -f docker-compose.improved.yml logs -f

# 특정 서비스만
docker-compose -f docker-compose.improved.yml logs -f airflow-webserver
```

### DAG가 보이지 않을 때
```bash
# DAG 폴더 확인
docker exec -it $(docker-compose -f docker-compose.improved.yml ps -q airflow-webserver) ls -la /opt/airflow/dags/

# 스케줄러 재시작
docker-compose -f docker-compose.improved.yml restart airflow-scheduler
```

## 데이터 확인

### PostgreSQL 접속
```bash
docker exec -it $(docker-compose -f docker-compose.improved.yml ps -q postgres) psql -U olist_user -d olist
```

### 데이터 건수 확인
```sql
-- raw 테이블들
SELECT 'orders_raw' as table_name, COUNT(*) FROM raw.orders_raw
UNION ALL
SELECT 'customers_raw', COUNT(*) FROM raw.customers_raw
UNION ALL
SELECT 'order_items_raw', COUNT(*) FROM raw.order_items_raw;

-- ods 테이블들
SELECT 'orders' as table_name, COUNT(*) FROM ods.orders
UNION ALL
SELECT 'customers', COUNT(*) FROM ods.customers
UNION ALL
SELECT 'order_items', COUNT(*) FROM ods.order_items;
```

### 데이터 품질 확인
```sql
-- 최근 DQ 결과
SELECT * FROM ops.dq_results ORDER BY checked_at DESC LIMIT 10;

-- 실패한 DQ 체크
SELECT * FROM ops.dq_results WHERE status = 'fail' ORDER BY checked_at DESC;
```

## 종료

```bash
# 정상 종료 (데이터 보존)
docker-compose -f docker-compose.improved.yml down

# 완전 삭제 (데이터도 삭제)
docker-compose -f docker-compose.improved.yml down -v
```

## 주의사항

- `.env` 파일에 민감한 정보가 있으니 `.gitignore`에 추가되어 있는지 확인
- 프로덕션에서는 기본 비밀번호 변경 필수
- 대용량 데이터 처리 시 메모리 모니터링 필요
