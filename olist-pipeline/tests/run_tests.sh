#!/bin/bash

# 테스트 실행 스크립트
set -e

echo "🧪 E-commerce 데이터 파이프라인 테스트 시작"

# 현재 디렉토리를 프로젝트 루트로 설정
cd "$(dirname "$0")/.."

# 가상환경 활성화 (존재하는 경우)
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ 가상환경 활성화됨"
fi

# 테스트 의존성 설치
echo "📦 테스트 의존성 설치 중..."
pip install -r tests/requirements-test.txt

# 환경변수 설정
export PYTHONPATH="${PYTHONPATH}:$(pwd)/dag"
export AIRFLOW__CORE__DAGS_FOLDER="$(pwd)/dag"
export AIRFLOW__CORE__PLUGINS_FOLDER="$(pwd)/plugin"

echo "🔍 단위 테스트 실행..."
pytest tests/test_common.py -v --tb=short

echo "🔍 DAG 검증 테스트 실행..."
pytest tests/test_dag_validation.py -v --tb=short

echo "🔍 데이터 품질 테스트 실행..."
pytest tests/test_data_quality.py -v --tb=short

echo "📊 전체 테스트 커버리지 리포트..."
pytest tests/ --cov=dag --cov-report=html --cov-report=term

echo "✅ 모든 테스트 완료!"
echo "📄 상세한 커버리지 리포트: htmlcov/index.html"
