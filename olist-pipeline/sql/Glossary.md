# Olist 프로젝트 용어집 (Glossary)

본 문서는 이커머스 데이터 제품 프로젝트에서 공통으로 사용하는 핵심 용어들을 정리합니다.

## 1) 데이터 레이어 & 모델링
- **RAW 레이어**: 원천 데이터 그대로 저장하는 층(스키마 검증 최소). 메타컬럼 예: `_batch_id`, `_ingested_at`, `_src_key`, `_src_etag`.
- **ODS (Operational Data Store)**: 업무 규칙 반영, 정타입·제약(PK/FK/CHECK) 적용한 신뢰 가능한 근거 데이터 층.
- **DIM/마트**: 리포팅·분석·특징 생성 목적의 집계/차원 테이블.
- **Fact / Dimension**: Fact는 이벤트·거래 중심, Dimension은 속성(고객/제품/일자 등).
- **서로게이트 키**: 의미 없는 대체키(정수/UUID)로 조인 안정성 확보.
- **SCD (Slowly Changing Dimension)**: 차원 속성의 역사 추적(Type 1/2/3 등).

## 2) 오케스트레이션(Airflow)
- **DAG**: 태스크 의존관계를 나타내는 비순환 그래프. 예) `olist_raw_load → raw_to_ods → ods_dim`.
- **Task / Operator**: 실행 단위 / 실행 로직. 예) `@task` Python, `PostgresHook.run`.
- **Hook / Connection**: 외부 시스템 연결 추상화 / 접속 정보. 예) `postgres_default`.
- **TriggerDagRunOperator**: 다른 DAG 트리거 + conf 전달(batch_id).
- **get_current_context()**: 런 컨텍스트 접근(DAG Run conf 등).
- **schedule_interval / catchup**: 스케줄 주기 / 과거 보정 실행 여부.
- **on_failure_callback / on_success_callback**: 성공·실패 시 후처리(Slack 알림).

## 3) 저장소 & 파일
- **S3**: 객체 스토리지(버킷/프리픽스). 원천 CSV 보관, 버저닝/라이프사이클.
- **S3 Prefix**: ‘폴더처럼’ 쓰는 경로 접두(앞 슬래시 X, 끝은 `/`). 예) `olist/raw/`.
- **ETag**: 객체 무결성 식별자(대개 MD5). 중복/변경 감지.
- **MinIO**: S3 호환 로컬 객체 스토리지. 로컬 개발용.

## 4) 데이터베이스(PostgreSQL/RDS)
- **RDS**: AWS 관리형 RDB. 엔드포인트로 접속(기본 포트 5432).
- **스키마**: 네임스페이스. 예) `raw`, `ods`, `dim`, `ops`.
- **PK/FK/CHECK**: 기본키/외래키/범위·형식 제약.
- **UPSERT**: `INSERT ... ON CONFLICT ... DO UPDATE`로 중복 없이 최신화.
- **TEXT vs VARCHAR**: RAW는 TEXT(실패 내성), ODS는 적절 타입 캐스팅.
- **TIMESTAMP (UTC)**: 타임존은 UTC로 통일.
- **인덱스 / VACUUM/ANALYZE**: 조회 성능 개선 / 통계 갱신·정리.
- **RDS Proxy**: 커넥션 풀·비밀 회전(확장 단계).

## 5) 보안/네트워크
- **IAM Role / Instance Profile**: 키 없이 AWS 리소스 권한 위임.
- **SSE-S3 / SSE-KMS**: 서버측 암호화(기본/고객 KMS 키).
- **KMS**: 키 관리/정책/감사. ARN: `arn:aws:kms:<region>:<acct>:key/<key-id>`.
- **Security Group**: 인바운드/아웃바운드 제어(화이트리스트 권장).
- **Elastic IP vs Public IP**: 고정 공인 IP / 재시작 시 변경 가능.
- **VPC Endpoint (S3)**: 프라이빗 S3 접근(보안·비용 이점).
- **Secrets Manager / SSM**: 비밀(암호/토큰) 저장·회전.

## 6) 데이터 품질(DQ)
- **Hard DQ / Soft DQ**: 실패 시 중단 / 기록·알림. 예) `03_dq_hard.sql`, `04_dq_soft.sql`.
- **품질 축**: 정합성·완전성·유효성·일관성·유일성·신선도·정확성.
- **Freshness**: 최신 데이터 도착 지연 측정.
- **MTTR / RCA**: 평균 복구 시간 / 근본 원인 분석.
- **Great Expectations / Soda / Deequ**: 선언적 DQ 프레임워크.

## 7) 운영 & 관측
- **Slack Webhook**: 실패/경고 즉시 알림(로그 URL 포함).
- **Batch ID**: 배치 실행 식별자. DQ/로그 상관관계 유지.
- **PITR**: 특정 시점 복구(RDS 자동 백업·스냅샷).

## 8) 배포/환경
- **Docker Compose**: 멀티 컨테이너 로컬 실행.
- **env_file / 환경변수**: `.env.local`/`.env.aws` 주입.
- **Volumes**: 호스트 디렉토리 → 컨테이너 경로 마운트.
- **MWAA**: AWS 관리형 Airflow(운영 부담 ↓, 제약 존재).

## 9) 분석 & ML(확장)
- **EDA**: 분포/결측/상관/가설 검정.
- **Feature Store**: 피처 정의/서빙/일관성.
- **모델 지표**: AUC/F1/PR-AUC, RMSE/MAE.
- **MLflow**: 실험 추적/모델 레지스트리.

## 10) SQL 표현 예
- `INSERT ... ON CONFLICT ... DO UPDATE` — UPSERT
- `CHECK (review_score BETWEEN 1 AND 5)` — 범위 제약
- `REFERENCES ods.orders(order_id)` — FK 무결성
- `CREATE INDEX ON ods.orders(order_id)` — 조회 가속
- `NOW() AT TIME ZONE 'UTC'` — UTC 기준 시간
