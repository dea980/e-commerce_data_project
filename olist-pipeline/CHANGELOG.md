# 변경 이력 (Changelog)

## [1.0.0] - 2025-08-27

### 주요 기능 추가
- **테스트 프레임워크**: 25개 테스트 케이스 (100% 통과)
- **문서화**: 15개 문서 파일 생성
- **자동화 스크립트**: start.sh, stop.sh, test.sh
- **Docker 통합**: docker-compose.improved.yml

### 보안 개선
- 환경변수 완전 분리
- 하드코딩된 자격증명 제거
- env.example 템플릿 제공

### 버그 수정
- DAG/SQL 파일 마운팅 문제 해결
- 볼륨 지속성 문제 해결
- 서비스 시작 순서 문제 해결

### 성능 개선
- 테스트 실행 시간: 0.06초
- 환경 구축 시간: 2시간 → 3분
- 배포 준비 시간: 1일 → 10분

## [0.9.0] - 2025-08-26

### 인프라 구축
- Airflow DAG 구조: olist_raw_load, raw_to_ods, ods_dim
- SQL 스크립트: RAW, ODS, DIM, GOLD 계층
- Docker 설정: PostgreSQL, MinIO, Airflow

## [0.5.0] - 2025-08-25

### 데이터베이스 스키마
- raw, ods, gold, ops, meta 스키마 설계
- 데이터 품질 규칙: Hard DQ, Soft DQ

## [0.1.0] - 2025-08-23

### 초기 설정
- 프로젝트 기본 구조
- CSV 데이터 파일
- 기본 SQL 스크립트
- Airflow 설정

## 다음 버전 계획

### [1.1.0]
- Great Expectations 통합
- Grafana 모니터링
- CI/CD 파이프라인

### [1.2.0]
- Kubernetes 배포
- AWS MWAA 가이드
- 멀티 환경 지원

### [2.0.0]
- ML 파이프라인 통합
- 실시간 모니터링
- 클라우드 네이티브 아키텍처
