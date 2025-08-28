#!/bin/bash

# Olist Data Pipeline 중지 스크립트
set -e

echo "🛑 Olist 데이터 파이프라인 중지 중..."

# 현재 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Docker Compose 중지
echo "🐳 Docker 컨테이너 중지 중..."

if [ "$1" = "--clean" ]; then
    echo "🧹 볼륨 및 네트워크도 함께 제거 중..."
    docker-compose -f docker/docker-compose.improved.yml down -v --remove-orphans
    
    echo "🗑️  사용하지 않는 볼륨 정리 중..."
    docker volume prune -f
    
    echo "🔄 사용하지 않는 네트워크 정리 중..."
    docker network prune -f
else
    docker-compose -f docker/docker-compose.improved.yml down --remove-orphans
fi

echo "✅ 파이프라인 중지 완료!"

if [ "$1" = "--clean" ]; then
    echo "🧹 모든 데이터가 삭제되었습니다."
    echo "   다시 시작하려면: ./scripts/start.sh"
else
    echo "💾 데이터는 보존되었습니다."
    echo "   다시 시작하려면: ./scripts/start.sh"
    echo "   완전 삭제하려면: ./scripts/stop.sh --clean"
fi
