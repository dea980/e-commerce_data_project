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

## 개선 제안 사항

### 1. 자격 증명 관리
- `docker-compose.yml` 파일에서 하드코딩된 자격 증명 완전 제거
- `.env` 파일을 통한 환경변수 분리 강화
- 보안 강화를 위한 기본 단계 완료

### 2. 데이터 로딩 방식
- 현재: 컨테이너 내 로컬 파일 시스템에서 데이터 읽기
- 개선: S3(MinIO)에서 직접 데이터 가져오기
- Airflow의 `S3Hook` 사용하여 MinIO 파일을 워커로 다운로드 후 적재

### 3. 자동화된 테스트
- `pytest` 프레임워크를 사용한 자동화된 데이터 테스트 추가
- 데이터 변환 로직(ODS와 Gold 계층)의 정확성 보장
- 소량 샘플 데이터로 변환 실행 및 결과 검증

### 4. Airflow DAG 고도화
- `PostgresOperator` 활용으로 코드 간소화
- 데이터 기반 스케줄링 (Datasets) 도입
- 시간 기반이 아닌 데이터 변경에 따른 파이프라인 동작

### 5. 인프라 및 배포 개선
- Dockerfile 최적화 (Multi-stage builds)
- docker-compose.yml 단순화
- healthcheck 기반 의존성 관리

### 6. 데이터 품질(DQ) 및 테스트 강화
- Great Expectations나 soda-core 같은 전문 DQ 프레임워크 도입
- 선언적 테스트 및 데이터 프로파일링
- Python 코드 단위 테스트 추가

### 7. 문서화 전략
- 문서의 자동화 (Documentation as Code)
- DQ 리포트 자동 생성
- 중앙 허브 페이지 구축
- ADR 지속적 활용