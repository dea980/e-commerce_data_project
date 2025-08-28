# 프로젝트 로드맵 (Lakehouse-lite)
작성일: 2025-08-27

## 비전
- S3 기반 데이터 레이크(브론즈/실버/골드) + RDS(Postgres) 서빙층 시작
- 임계치 도달 시 Redshift Serverless/Snowflake 확장
- 오케스트레이션은 Airflow(EC2) → 필요 시 MWAA 전환

## 단계 요약
- Sprint A: 레이크 기초(브론즈 정리, Glue Catalog) + DQ 대시보드
- Sprint B: 실버/골드 강화 + BI 연결
- Sprint C: 웨어하우스 PoC(Redshift Serverless or Snowflake)
- Sprint D: 운영 성숙도(권한·백업·MWAA)
- Sprint E: ML/피처 스토어 & 모델 베이스라인

## WH 전환 결정 기준(예시)
- KPI 쿼리 p95가 30초+ 지속
- 데이터 200~300GB+, 동시 사용자 10~20+, 스케줄 쿼리 100+/일
- 비용/성능/운영성에서 WH가 유의미한 개선

## 핵심 지표
- DQ 하드 실패율/소프트 경고율, Freshness 지연
- 주요 쿼리 p95/p99, BI 동시 사용자 수
- 월간 S3/쿼리 비용, 장애 MTTR


### 개선 제안 사항

프로젝트가 이미 매우 훌륭하지만, 몇 가지 추가적으로 고려해볼 만한 사항들을 제안합니다.

1.  **자격 증명 관리**: `docker-compose.yml` 파일에 `kdea989`/`Kdea504605`와 같은 자격 증명이 일부 남아있습니다. `.env` 파일을 잘 활용하고 계시지만, 버전 관리되는 모든 파일에서 자격 증명을 완전히 분리하는 것을 권장합니다. 이는 보안을 강화하는 가장 기본적인 단계입니다.
2.  **데이터 로딩 방식**: 현재 DAG(`olist_raw_load.py`)는 컨테이너 내 로컬 파일 시스템(`_loaders.py`의 `/opt/airflow/data/raw`)에서 데이터를 읽어 PostgreSQL에 적재합니다. 이 방식은 볼륨 마운트 덕분에 잘 동작하지만, 클라우드 환경을 가정한다면 DAG가 S3(MinIO)에서 직접 데이터를 가져오는 것이 더 일반적입니다. Airflow의 `S3Hook` 등을 사용하여 MinIO의 파일을 워커로 다운로드한 후 적재하는 방식을 고려해볼 수 있습니다.
3.  **자동화된 테스트**: `tests/` 디렉토리가 있지만, 실제 테스트 코드는 없습니다. 데이터 변환 로직(특히 ODS와 Gold 계층)의 정확성을 보장하기 위해 `pytest` 같은 프레임워크를 사용한 자동화된 데이터 테스트를 추가하면 파이프라인의 신뢰성을 한층 더 높일 수 있습니다. (예: 소량의 샘플 데이터로 변환을 실행하고 결과가 예상과 같은지 검증)

### 총평

**매우 잘 설계되고 실행된 데이터 엔지니어링 프로젝트입니다.** 현대적인 데이터 아키텍처에 대한 깊은 이해를 바탕으로 체계적인 구조, 뛰어난 문서화, 안정적인 파이프라인, 그리고 확장성까지 고려한 모범적인 사례라고 할 수 있습니다. 제안해 드린 몇 가지 사항들을 보완한다면 더욱 완성도 높은 프로젝트가 될 것입니다.
(e-commerce) (base) Daeyeopsui-MacBookAir:e-commerce_data_project daeyeop$    gemini -a -p "내 프로젝트에 대해 분석하고 개선방한들을 써주고... 문서화를 어떻할수 있을까?"
Loaded cached credentials.
네, 안녕하세요. 제공해주신 프로젝트 전체 내용을 바탕으로 심도 있게 분석하고, 개선 방안과 문서화 전략을 제안해 드리겠습니다.

먼저, 현재 프로젝트는 매우 훌륭하게 구성되어 있다는 점을 말씀드리고 싶습니다.

### 프로젝트 분석 (강점)

- **명확한 아키텍처**: Medallion Architecture(RAW-ODS-DIM/GOLD)를 채택하여 데이터의 흐름과 정제 과정을 체계적으로 관리하고 있습니다.
- **상세한 문서**: `README`, `SDS`, `ADR` (아키텍처 결정 기록) 등 표준적인 문서화가 매우 잘 되어 있어 프로젝트의 의사결정 과정과 구조를 쉽게 파악할 수 있습니다.
- **인프라 코드화(IaC)**: `docker-compose.yml`을 통해 로컬 개발 환경을 코드로 관리하여 일관성과 재현성을 확보했습니다.
- **체계적인 SQL 관리**: SQL 스크립트를 번호와 기능에 따라 분리하여 유지보수성을 높였습니다.
- **데이터 품질(DQ) 고려**: `03_dq_hard.sql`, `04_dq_soft.sql`처럼 데이터 품질 규칙을 파이프라인에 통합한 것은 매우 성숙한 접근 방식입니다.

이러한 강점들을 기반으로, 프로젝트를 한 단계 더 발전시킬 수 있는 몇 가지 개선 방안을 제안합니다.

---

### 개선 방안 제안

#### 1. Airflow DAG 고도화

현재 `PythonOperator`에서 `psycopg2`를 직접 사용해 SQL 파일을 실행하는 방식도 좋지만, Airflow의 기능을 더 활용하여 개선할 수 있습니다.

- **`PostgresOperator` 활용**: SQL 실행을 위해 `PythonOperator` 대신 `PostgresOperator`를 사용하면 코드가 더 간결해지고 의도가 명확해집니다.
  
  *변경 전 (`_common.py` + `dag.py`)*
  ```python
  # _common.py
  def run_sql_file(pg_conn_uri, rel_path, ...):
      # ... psycopg2 connection and execution ...
  
  # dag.py
  ods_ddl = sql_task(dag, "ods_core_ddl", "10_ods_core_ddl.sql")
  ```

  *변경 후 (`dag.py`)*
  ```python
  from airflow.providers.postgres.operators.postgres import PostgresOperator

  ods_ddl = PostgresOperator(
      task_id="ods_core_ddl",
      postgres_conn_id="postgres_default", # Airflow Connection ID
      sql="sql/10_ods_core_ddl.sql",
  )
  ```

- **데이터 기반 스케줄링 (Datasets)**: 현재 DAG들은 시간(`@daily`) 또는 다른 DAG 완료 시 트리거됩니다. Airflow 2.4+ 부터는 **Datasets**를 사용하여 데이터의 생산과 소비를 명확하게 연결할 수 있습니다.
  
  *예시: ODS 테이블이 업데이트되면, FACT/GOLD DAG이 실행되도록 설정*

  *`raw_to_ods.py` (생산자)*
  ```python
  from airflow.datasets import Dataset

  # ODS 테이블을 Dataset으로 정의
  ODS_ORDERS_DATASET = Dataset("postgres://ods/orders")

  with DAG(...) as dag:
      # ...
      ods_upsert = PostgresOperator(
          task_id="ods_core_upsert",
          # ...
          outlets=[ODS_ORDERS_DATASET] # 이 태스크가 ODS_ORDERS_DATASET을 생산함을 명시
      )
  ```

  *`fact_gold.build.py` (소비자)*
  ```python
  from airflow.datasets import Dataset

  ODS_ORDERS_DATASET = Dataset("postgres://ods/orders")

  with DAG(
      dag_id="fact_gold_build",
      schedule=[ODS_ORDERS_DATASET], # ODS_ORDERS_DATASET이 업데이트될 때 실행
      ...
  ) as dag:
      # ...
  ```
  이렇게 하면 시간 기반이 아닌, 실제 데이터의 변경에 따라 파이프라인이 동작하여 더 안정적이고 효율적이 됩니다.

#### 2. 인프라 및 배포 개선

- **Dockerfile 최적화 (Multi-stage builds)**: 현재 `Dockerfile`은 빌드에 필요한 도구(`build-essential` 등)와 소스 코드를 한 번에 복사합니다. Multi-stage build를 사용하면 최종 이미지 크기를 줄이고 빌드 속도를 개선할 수 있습니다.
  ```dockerfile
  # Stage 1: Build dependencies
  FROM python:3.12-slim as builder
  WORKDIR /app
  RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev
  COPY requirements.txt .
  RUN pip install --upgrade pip && pip install -r requirements.txt

  # Stage 2: Final image
  FROM python:3.12-slim
  WORKDIR /app
  ENV PYTHONDONTWRITEBYTECODE=1
  ENV PYTHONUNBUFFERED=1
  
  # 빌드된 패키지만 복사
  COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
  COPY --from=builder /app/requirements.txt .
  
  # 소스 코드 복사
  COPY . .
  
  # ... 나머지 설정 ...
  ```

- **`docker-compose.yml` 단순화**: `.env` 파일을 프로젝트 루트에 두고 `docker-compose`가 자동으로 읽게 하면, `x-common-env` 같은 복잡한 구조를 더 단순화할 수 있습니다. 또한 `minio-setup`의 `sleep 10`은 불안정하므로, `healthcheck`에 의존하는 것이 더 좋습니다.

#### 3. 데이터 품질(DQ) 및 테스트 강화

- **전문 DQ 프레임워크 도입**: 현재 SQL 기반 DQ도 훌륭하지만, `Great Expectations`나 `soda-core` 같은 프레임워크를 도입하면 다음과 같은 장점이 있습니다.
    - **선언적 테스트**: "orders 테이블의 order_status는 ['delivered', 'shipped', ...] 중 하나여야 한다" 와 같이 쉽게 규칙을 정의할 수 있습니다.
    - **데이터 프로파일링 및 문서 자동 생성**: 데이터의 통계, 분포, 규칙 검사 결과를 HTML 문서(`Data Docs`)로 자동 생성하여 공유하기 좋습니다.
- **Python 코드 단위 테스트**: `olist-pipeline/dag` 내의 유틸리티 함수(`_common.py`, `_alerts.py`)에 대해 `pytest`를 사용한 단위 테스트를 추가하면 코드 변경 시 안정성을 크게 높일 수 있습니다.

---

### 문서화 전략

이미 훌륭한 문서(`SDS`, `ADR` 등)를 갖추고 있으므로, **유지보수 부담을 줄이고 문서를 살아있게 만드는 것**에 초점을 맞추는 것이 좋습니다.

1.  **문서의 자동화 (Documentation as Code)**
    - **DQ 리포트 자동 생성**: 위에서 제안한 `Great Expectations`를 도입하면, 데이터 품질 검사 결과가 자동으로 HTML 리포트로 생성됩니다. 이 리포트를 정기적으로 빌드하여 팀원들과 공유하면, 데이터 신뢰도에 대한 논의가 수월해집니다.
    - **dbt Docs 활용 (향후)**: 만약 SQL 변환 로직이 더 복잡해져 `dbt`를 도입하게 된다면, `dbt docs` 명령어로 데이터 모델의 설명, 관계, **Lineage Graph(계보)**를 포함한 웹사이트를 자동으로 생성할 수 있습니다. 현재 프로젝트 구조는 `dbt`로 전환하기에 매우 좋은 상태입니다.

2.  **중앙 허브 페이지 만들기**
    - 현재 문서들이 여러 파일에 흩어져 있습니다. `/docs` 같은 폴더를 만들고, 그 안에 `index.md` 파일을 두어 모든 중요 문서로 연결되는 링크를 제공하는 **문서 허브**를 만드세요.
    - 이 허브에는 다음 링크들이 포함될 수 있습니다:
        - `README.md`: 프로젝트 시작 가이드
        - `SDS.md`: 시스템 설계 명세
        - `sql/adr/`: 아키텍처 결정 기록 목록
        - `sql/Glossary.md`: 용어집
        - (자동 생성된) 데이터 품질 리포트
        - (자동 생성된) dbt 문서 사이트

3.  **`ADR` 지속적 활용**
    - "S3 + Postgres를 선택한 이유"(`002-storage-s3-postgres.md`)처럼 중요한 기술적 결정이 내려질 때마다 새로운 `ADR` 문서를 작성하는 문화를 유지하는 것이 매우 중요합니다. 이는 나중에 "왜 이렇게 만들었지?"라는 질문에 대한 최고의 답변이 됩니다.

### 요약

- **단기적 개선**: `PostgresOperator`와 Airflow **Datasets**를 도입하여 DAG을 현대화하고, `Dockerfile`을 최적화하여 배포 효율을 높이세요.
- **중기적 개선**: `Great Expectations` 같은 DQ 프레임워크를 도입하여 데이터 품질 관리를 자동화하고, `pytest`로 파이썬 코드의 안정성을 확보하세요.
- **문서화**: 기존의 훌륭한 문서를 기반으로, **자동 생성**되는 부분을 늘리고(DQ 리포트 등), **중앙 허브 페이지**를 만들어 접근성을 높이는 방향으로 전략을 세우는 것을 추천합니다.

이 프로젝트는 이미 매우 높은 수준에 도달해 있으며, 제안 드린 내용들은 프로젝트를 더욱 견고하고 확장 가능하게 만들어 줄 것입니다. 추가적으로 궁금한 점이 있다면 언제든지 질문해 주세요.