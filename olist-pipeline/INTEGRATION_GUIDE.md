# 🔗 Docker Compose 통합 가이드

> **DAG + SQL + Docker의 완전한 통합 실행 가이드**

---

## 🚀 빠른 시작 (3분 만에 실행)

### 1단계: 환경 설정
```bash
# 프로젝트 루트로 이동
cd olist-pipeline

# 환경변수 파일 생성 및 편집
cp env.example .env
nano .env  # 또는 원하는 에디터로 편집
```

### 2단계: 파이프라인 시작
```bash
# 전체 파이프라인 시작
./scripts/start.sh

# 또는 깨끗한 시작 (기존 데이터 삭제)
./scripts/start.sh --clean
```

### 3단계: 웹 UI 접속
- **Airflow**: http://localhost:8080 (admin/admin)
- **MinIO Console**: http://localhost:9001 (env에서 설정한 키)
- **PostgreSQL**: localhost:5432 (env에서 설정한 정보)

---

## 🏗️ 아키텍처 개요

### 서비스 구성
```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Airflow    │  │ PostgreSQL  │  │   MinIO     │         │
│  │             │  │             │  │             │         │
│  │ - Webserver │◄─┤ - Raw       │◄─┤ - CSV Files │         │
│  │ - Scheduler │  │ - ODS       │  │ - Backups   │         │
│  │ - Worker    │  │ - Gold      │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### 데이터 플로우
```
CSV Files (MinIO)
    ↓ (olist_raw_load DAG)
RAW Tables (PostgreSQL)
    ↓ (raw_to_ods DAG + Data Quality)
ODS Tables (PostgreSQL)
    ↓ (ods_dim DAG)
DIM Tables (PostgreSQL)
    ↓ (fact_gold_build DAG)
GOLD Tables (PostgreSQL)
```

---

## 📁 볼륨 마운팅

### Docker Compose에서 마운트되는 디렉토리들

| 로컬 경로 | 컨테이너 경로 | 용도 |
|-----------|---------------|------|
| `./dag/` | `/opt/airflow/dags/` | Airflow DAG 파일들 |
| `./sql/` | `/opt/airflow/sql/` | SQL 스크립트들 |
| `./tests/` | `/opt/airflow/tests/` | 테스트 코드 |
| `../data/` | `/opt/airflow/data/` | 원본 데이터 파일 |

### 데이터 지속성

| 볼륨 | 용도 |
|------|------|
| `postgres-db-volume` | PostgreSQL 데이터 |
| `minio-data` | MinIO 객체 스토리지 |
| `airflow-logs` | Airflow 로그 |
| `airflow-plugins` | Airflow 플러그인 |

---

## 🔧 주요 개선사항

### 기존 `docker-compose.local.yml` 문제점
- ❌ 하드코딩된 자격증명 (`kdea989:Kdea504605`)
- ❌ DAG/SQL 파일 마운트 누락
- ❌ 헬스체크 부족
- ❌ 볼륨 관리 미흡

### 새로운 `docker-compose.improved.yml` 장점
- ✅ 환경변수 완전 분리 (`.env` 파일)
- ✅ 모든 필요 디렉토리 마운트
- ✅ 포괄적 헬스체크
- ✅ 적절한 볼륨 관리
- ✅ 네트워크 격리
- ✅ 자동 초기화 스크립트

---

## 🎯 실행 시나리오

### 시나리오 1: 개발 환경 구축
```bash
# 1. 환경 설정
cp env.example .env
# .env 파일에서 개발용 패스워드 설정

# 2. 시작
./scripts/start.sh

# 3. 테스트
./scripts/test.sh

# 4. 개발 작업...

# 5. 종료 (데이터 보존)
./scripts/stop.sh
```

### 시나리오 2: 데모/프레젠테이션
```bash
# 1. 깨끗한 시작
./scripts/start.sh --clean

# 2. Airflow UI에서 DAG 실행 시연

# 3. 완료 후 정리
./scripts/stop.sh --clean
```

### 시나리오 3: 프로덕션 준비
```bash
# 1. 보안 강화된 .env 설정
cp env.example .env
# 강력한 패스워드, 실제 S3 엔드포인트 등 설정

# 2. 시작
./scripts/start.sh

# 3. 모니터링 설정...
```

---

## 📊 DAG 실행 순서

### 1. 초기 설정 (한 번만)
```
Airflow UI → Admin → Connections에서 연결 설정 확인
- postgres_default: PostgreSQL 연결
- aws_default: S3/MinIO 연결
```

### 2. DAG 실행 순서
```
1. olist_raw_load     (CSV → RAW)
   ↓
2. raw_to_ods         (RAW → ODS + DQ)
   ↓  
3. ods_dim            (ODS → DIM)
   ↓
4. fact_gold_build    (DIM → GOLD)
```

### 3. 자동화 설정
```
각 DAG의 schedule_interval 설정:
- olist_raw_load: @daily
- raw_to_ods: None (트리거 기반)
- ods_dim: None (트리거 기반)  
- fact_gold_build: None (트리거 기반)
```

---

## 🔍 모니터링 및 디버깅

### 로그 확인
```bash
# 전체 서비스 로그
docker-compose -f docker/docker-compose.improved.yml logs -f

# 특정 서비스 로그
docker-compose -f docker/docker-compose.improved.yml logs -f airflow-scheduler
docker-compose -f docker/docker-compose.improved.yml logs -f postgres
docker-compose -f docker/docker-compose.improved.yml logs -f minio
```

### 컨테이너 상태 확인
```bash
# 서비스 상태
docker-compose -f docker/docker-compose.improved.yml ps

# 리소스 사용량
docker stats

# 볼륨 사용량
docker volume ls
docker system df
```

### 데이터베이스 직접 접근
```bash
# PostgreSQL 접속
docker exec -it $(docker-compose -f docker/docker-compose.improved.yml ps -q postgres) \
  psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# 테이블 확인
\dt raw.*
\dt ods.*
\dt gold.*
```

---

## 🛠️ 트러블슈팅

### 자주 발생하는 문제들

#### 1. 포트 충돌
```bash
# 포트 사용 확인
lsof -i :8080  # Airflow
lsof -i :5432  # PostgreSQL
lsof -i :9000  # MinIO

# 해결: docker-compose.yml에서 포트 변경
```

#### 2. 권한 문제
```bash
# Airflow 권한 문제
sudo chown -R $(id -u):$(id -g) dag/ sql/ tests/

# 볼륨 권한 문제  
docker-compose -f docker/docker-compose.improved.yml down -v
./scripts/start.sh --clean
```

#### 3. 메모리 부족
```bash
# Docker 메모리 할당 증가 (Docker Desktop)
# 또는 불필요한 서비스 중지
docker-compose -f docker/docker-compose.improved.yml stop airflow-worker
```

#### 4. DAG 인식 안됨
```bash
# DAG 디렉토리 마운트 확인
docker exec -it $(docker-compose -f docker/docker-compose.improved.yml ps -q airflow-webserver) \
  ls -la /opt/airflow/dags/

# Airflow 재시작
docker-compose -f docker/docker-compose.improved.yml restart airflow-scheduler
```

---

## 🔐 보안 고려사항

### 개발 환경
- ✅ `.env` 파일 사용 (Git 제외)
- ✅ 기본 패스워드 변경
- ✅ 네트워크 격리

### 프로덕션 준비
- 🔒 AWS Secrets Manager 사용
- 🔒 IAM 역할 기반 인증
- 🔒 VPC 내 배포
- 🔒 SSL/TLS 적용
- 🔒 정기적 패스워드 로테이션

---

## 📈 성능 최적화

### 리소스 조정
```yaml
# docker-compose.improved.yml에서 조정 가능
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### Airflow 설정 최적화
```bash
# .env 파일에서 설정
AIRFLOW__CORE__PARALLELISM=32
AIRFLOW__CORE__DAG_CONCURRENCY=16
AIRFLOW__CORE__MAX_ACTIVE_RUNS_PER_DAG=16
```

---

## 🚀 다음 단계

### 즉시 가능한 개선
- [ ] Grafana + Prometheus 모니터링 추가
- [ ] Nginx 리버스 프록시 설정
- [ ] SSL 인증서 적용
- [ ] 백업 자동화 스크립트

### 중기 계획
- [ ] Kubernetes 배포 준비
- [ ] CI/CD 파이프라인 통합
- [ ] 다중 환경 지원 (dev/staging/prod)

---

**🎉 축하합니다!** 이제 완전히 통합된 데이터 파이프라인을 보유하게 되었습니다.

모든 컴포넌트가 Docker Compose로 통합되어 **원클릭 실행**이 가능하며, **테스트부터 프로덕션까지** 일관된 환경을 제공합니다.
