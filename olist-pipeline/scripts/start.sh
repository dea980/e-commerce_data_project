#!/bin/bash

# Olist Data Pipeline 시작 스크립트
set -e

echo "🚀 Olist 데이터 파이프라인 시작 중..."

# 현재 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 프로젝트 루트: $PROJECT_ROOT"

# 환경변수 파일 확인
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "⚠️  .env 파일이 없습니다. env.example을 복사하여 .env 파일을 생성하세요."
    echo "   cp env.example .env"
    echo "   그 후 .env 파일을 편집하여 필요한 값들을 설정하세요."
    exit 1
fi

echo "✅ 환경변수 파일 확인됨"

# Docker 실행 확인
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker가 실행되지 않았습니다. Docker를 시작하세요."
    exit 1
fi

echo "✅ Docker 실행 확인됨"

# 필요한 디렉토리 생성
mkdir -p "$PROJECT_ROOT/logs"
mkdir -p "$PROJECT_ROOT/plugins"

# Docker Compose 실행
echo "🐳 Docker 컨테이너 시작 중..."
cd "$PROJECT_ROOT"

# 환경변수 로드
export $(cat .env | grep -v '^#' | xargs)

# 기존 컨테이너 정리 (선택사항)
if [ "$1" = "--clean" ]; then
    echo "🧹 기존 컨테이너 정리 중..."
    docker-compose -f docker/docker-compose.improved.yml down -v
    docker volume prune -f
fi

# 컨테이너 시작
docker-compose -f docker/docker-compose.improved.yml up -d

echo "⏳ 서비스 초기화 대기 중..."
sleep 30

# 서비스 상태 확인
echo "📊 서비스 상태 확인 중..."
docker-compose -f docker/docker-compose.improved.yml ps

# 헬스체크
echo "🔍 헬스체크 수행 중..."

# PostgreSQL 연결 테스트
echo "  - PostgreSQL 연결 테스트..."
if docker exec $(docker-compose -f docker/docker-compose.improved.yml ps -q postgres) pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}; then
    echo "    ✅ PostgreSQL 연결 성공"
else
    echo "    ❌ PostgreSQL 연결 실패"
fi

# MinIO 연결 테스트
echo "  - MinIO 연결 테스트..."
if curl -s http://localhost:9000/minio/health/live > /dev/null; then
    echo "    ✅ MinIO 연결 성공"
else
    echo "    ❌ MinIO 연결 실패"
fi

# Airflow 웹서버 테스트
echo "  - Airflow 웹서버 테스트..."
sleep 10
if curl -s http://localhost:8080/health > /dev/null; then
    echo "    ✅ Airflow 웹서버 연결 성공"
else
    echo "    ⚠️  Airflow 웹서버 아직 시작 중... (잠시 후 다시 확인하세요)"
fi

echo ""
echo "🎉 파이프라인 시작 완료!"
echo ""
echo "📋 접속 정보:"
echo "  🌐 Airflow UI:    http://localhost:8080 (admin/admin)"
echo "  🗄️  MinIO Console: http://localhost:9001 (${AWS_ACCESS_KEY_ID}/${AWS_SECRET_ACCESS_KEY})"
echo "  🐘 PostgreSQL:    localhost:5432 (${POSTGRES_USER}/${POSTGRES_PASSWORD})"
echo ""
echo "📝 다음 단계:"
echo "  1. Airflow UI에 접속하여 DAG들을 활성화하세요"
echo "  2. olist_raw_load DAG부터 순서대로 실행하세요"
echo "  3. 로그는 'docker-compose -f docker/docker-compose.improved.yml logs -f' 명령으로 확인하세요"
echo ""
echo "🛑 종료하려면: ./scripts/stop.sh"
