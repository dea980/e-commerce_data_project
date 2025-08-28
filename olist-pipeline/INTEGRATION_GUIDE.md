# Docker Compose 통합 가이드

DAG + SQL + Docker의 완전한 통합 실행 가이드입니다.

## 빠른 시작

### 1. 환경 설정
```bash
cd olist-pipeline
cp env.example .env
# .env 파일에서 비밀번호 등 수정
```

### 2. 파이프라인 시작
```bash
./scripts/start.sh
```

### 3. 웹 UI 접속
- Airflow: http://localhost:8080 (admin/admin)
- MinIO: http://localhost:9001 (minioadmin/minioadmin)
- PostgreSQL: localhost:5432

## 아키텍처

### 서비스 구성
```
Airflow (DAGs) → PostgreSQL (데이터) ← MinIO (CSV 파일)
```

### 데이터 플로우
```
CSV Files → RAW → ODS → DIM → GOLD
```

## 볼륨 마운팅

| 로컬 경로 | 컨테이너 경로 | 용도 |
|-----------|---------------|------|
| `./dag/` | `/opt/airflow/dags/` | Airflow DAG 파일들 |
| `./sql/` | `/opt/airflow/sql/` | SQL 스크립트들 |
| `./tests/` | `/opt/airflow/tests/` | 테스트 코드 |
| `../data/` | `/opt/airflow/data/` | 원본 데이터 파일 |

## 주요 개선사항

### 기존 문제점
- 하드코딩된 자격증명
- DAG/SQL 파일 마운트 누락
- 헬스체크 부족

### 개선된 점
- 환경변수 완전 분리
- 모든 필요 디렉토리 마운트
- 포괄적 헬스체크
- 자동 초기화 스크립트

## 실행 시나리오

### 개발 환경
```bash
# 1. 환경 설정
cp env.example .env

# 2. 시작
./scripts/start.sh

# 3. 테스트
./scripts/test.sh

# 4. 종료
./scripts/stop.sh
```

### 데모/프레젠테이션
```bash
# 깨끗한 시작
./scripts/start.sh --clean

# 완료 후 정리
./scripts/stop.sh --clean
```

## DAG 실행 순서

1. **olist_raw_load** - CSV → RAW
2. **raw_to_ods** - RAW → ODS + 데이터 품질 체크
3. **ods_dim** - ODS → DIM
4. **fact_gold_build** - DIM → GOLD

## 모니터링 및 디버깅

### 로그 확인
```bash
# 전체 로그
docker-compose -f docker/docker-compose.improved.yml logs -f

# 특정 서비스
docker-compose -f docker/docker-compose.improved.yml logs -f airflow-scheduler
```

### 컨테이너 상태
```bash
# 서비스 상태
docker-compose -f docker/docker-compose.improved.yml ps

# 리소스 사용량
docker stats
```

### 데이터베이스 접근
```bash
# PostgreSQL 접속
docker exec -it $(docker-compose -f docker/docker-compose.improved.yml ps -q postgres) \
  psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}
```

## 문제 해결

### 포트 충돌
```bash
# 포트 사용 확인
lsof -i :8080
lsof -i :5432
lsof -i :9000
```

### 권한 문제
```bash
# 권한 수정
sudo chown -R $(id -u):$(id -g) dag/ sql/ tests/
```

### DAG 인식 안됨
```bash
# DAG 디렉토리 확인
docker exec -it $(docker-compose -f docker/docker-compose.improved.yml ps -q airflow-webserver) \
  ls -la /opt/airflow/dags/

# 재시작
docker-compose -f docker/docker-compose.improved.yml restart airflow-scheduler
```

## 보안 고려사항

### 개발 환경
- `.env` 파일 사용 (Git 제외)
- 기본 패스워드 변경
- 네트워크 격리

### 프로덕션 준비
- AWS Secrets Manager 사용
- IAM 역할 기반 인증
- VPC 내 배포
- SSL/TLS 적용

## 성능 최적화

### 리소스 조정
```yaml
# docker-compose.improved.yml에서 조정
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 2G
```

### Airflow 설정
```bash
# .env 파일에서 설정
AIRFLOW__CORE__PARALLELISM=32
AIRFLOW__CORE__DAG_CONCURRENCY=16
```

## 다음 단계

### 단기 계획
- Grafana + Prometheus 모니터링
- Nginx 리버스 프록시
- SSL 인증서 적용

### 중기 계획
- Kubernetes 배포 준비
- CI/CD 파이프라인 통합
- 다중 환경 지원
