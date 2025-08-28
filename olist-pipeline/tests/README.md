# 테스트 가이드

Olist 데이터 파이프라인의 자동화된 테스트를 포함합니다.

## 테스트 전략

### 1. 단위 테스트 (Unit Tests)
- 대상: DAG 유틸리티 함수들 (`_common.py`, `_alerts.py`)
- 목적: 개별 함수의 정확성 검증
- 파일: `test_common.py`

### 2. 통합 테스트 (Integration Tests)  
- 대상: 데이터 변환 로직 (RAW → ODS → DIM)
- 목적: 전체 데이터 플로우의 정확성 검증
- 파일: `test_data_quality.py`

### 3. DAG 검증 테스트
- 대상: Airflow DAG 구조 및 의존성
- 목적: DAG 설정의 정확성과 순환 의존성 방지
- 파일: `test_dag_validation.py`

## 테스트 실행 방법

### 빠른 시작
```bash
cd olist-pipeline
./tests/run_tests.sh
```

### 개별 테스트 실행
```bash
# 단위 테스트만
pytest tests/test_common.py -v

# 데이터 품질 테스트만  
pytest tests/test_data_quality.py -v

# DAG 검증 테스트만
pytest tests/test_dag_validation.py -v

# 커버리지 포함 전체 테스트
pytest tests/ --cov=dag --cov-report=html
```

### 특정 테스트만 실행
```bash
# 특정 클래스
pytest tests/test_data_quality.py::TestDataQualityHard -v

# 특정 메서드
pytest tests/test_common.py::TestReadSQL::test_read_sql_success -v
```

## 테스트 구성 요소

### conftest.py
- pytest 설정 및 공통 픽스처
- PostgreSQL 테스트 컨테이너
- 샘플 데이터 생성

### test_common.py
- `read_sql()` 함수 테스트
- SQL 파일 읽기 및 에러 처리
- 배치 ID 치환 로직 검증

### test_data_quality.py
- 하드 DQ 규칙 테스트 (PK 유일성, FK 무결성)
- 소프트 DQ 규칙 테스트 (음수 가격, 신선도)
- RAW → ODS 데이터 변환 검증

### test_dag_validation.py
- DAG 구조 및 설정 검증
- 태스크 의존성 확인
- 순환 의존성 탐지
- 배치 ID 치환 로직 테스트

## 테스트 환경 설정

### 필수 의존성
```bash
pip install -r tests/requirements-test.txt
```

### 환경변수
```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)/dag"
export AIRFLOW__CORE__DAGS_FOLDER="$(pwd)/dag"
```

## 커버리지 목표

- 단위 테스트: 80% 이상
- 통합 테스트: 주요 데이터 변환 로직 100%
- DAG 테스트: 모든 DAG 구조 검증

## CI/CD 통합

### GitHub Actions 예시
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.12'
    - name: Run tests
      run: |
        cd olist-pipeline
        ./tests/run_tests.sh
```

## 테스트 작성 가이드

### 새로운 테스트 추가 시
1. 파일명: `test_*.py` 형식
2. 클래스명: `Test*` 형식  
3. 메서드명: `test_*` 형식
4. Given-When-Then 패턴 사용

### 샘플 테스트 구조
```python
def test_function_name(self, fixture_name):
    # Given - 테스트 데이터 준비
    input_data = "test_input"
    
    # When - 테스트 대상 실행
    result = target_function(input_data)
    
    # Then - 결과 검증
    assert result == expected_output
```

## 문제 해결

### 일반적인 문제들
1. ImportError: `PYTHONPATH` 설정 확인
2. PostgreSQL 연결 실패: Docker 실행 상태 확인
3. 테스트 데이터 충돌: 각 테스트 후 데이터 정리 확인

### 로그 확인
```bash
pytest tests/ -v --tb=long --log-cli-level=DEBUG
```

## 향후 개선 계획

1. 성능 테스트: 대용량 데이터 처리 성능 검증
2. End-to-End 테스트: 실제 S3/MinIO와 연동 테스트
3. 데이터 품질 프레임워크: Great Expectations 통합
4. Airflow 테스트: 실제 Airflow 환경에서의 DAG 실행 테스트
