#!/bin/bash

# Olist Data Pipeline 테스트 스크립트
set -e

echo "🧪 Olist 데이터 파이프라인 테스트 시작..."

# 현재 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Python 가상환경 확인
if [ ! -d "../e-commerce" ]; then
    echo "⚠️  Python 가상환경이 없습니다. 먼저 가상환경을 생성하세요:"
    echo "   python -m venv ../e-commerce"
    echo "   source ../e-commerce/bin/activate"
    echo "   pip install -r tests/requirements-test.txt"
    exit 1
fi

# 가상환경 활성화
echo "🐍 Python 가상환경 활성화 중..."
source ../e-commerce/bin/activate

# 테스트 의존성 확인 및 설치
echo "📦 테스트 의존성 확인 중..."
if [ -f "tests/requirements-test.txt" ]; then
    pip install -q -r tests/requirements-test.txt
else
    echo "⚠️  tests/requirements-test.txt 파일이 없습니다."
fi

# 테스트 실행
echo "🔍 테스트 실행 중..."
cd tests

# 기본 기능 테스트
echo "  📋 기본 기능 테스트..."
python -m pytest test_simple.py -v --tb=short

# SQL 검증 테스트  
echo "  📊 SQL 파일 검증 테스트..."
python -m pytest test_sql_validation.py -v --tb=short

# 전체 테스트 요약
echo "  📈 전체 테스트 실행..."
python -m pytest test_simple.py test_sql_validation.py -v --tb=short

# 테스트 리포트 생성 (가능한 경우)
if [ -x "docs/generate-simple-report.sh" ]; then
    echo "📝 테스트 리포트 생성 중..."
    ./docs/generate-simple-report.sh || true
fi

echo ""
echo "✅ 모든 테스트 완료!"
echo ""
echo "📊 테스트 결과:"
echo "  - 기본 기능: ✅"
echo "  - SQL 검증: ✅"
echo "  - 전체 파이프라인: ✅"
echo ""
echo "📄 상세 리포트: tests/docs/ 디렉토리 확인"
