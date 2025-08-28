---
adr: 002
title: 저장소 선택 (S3/MinIO + RDS PostgreSQL)
status: Accepted
date: 2025-08-26
---

## Context
- 원천 파일의 버저닝/저장·저비용 필요, 분석은 SQL로 시작.

## Decision
- **원천 저장**: AWS S3 (로컬은 MinIO, `S3_ENDPOINT`로 전환).
- **쿼리/집계**: RDS PostgreSQL.

## Rationale
- S3: 표준/저비용/수명주기 관리, MinIO로 로컬-클라우드 코드 동일성 유지.
- Postgres: Olist 스케일에서 친숙하고 충분한 성능, 생태계 풍부.

## Consequences
**Positive**: MVP 가성비 최적, 관리 명확.  
**Negative**: 수 TB 이상에서 Postgres 한계 → 인덱스/IO 튜닝 필요.

## Alternatives
- Redshift/Snowflake/BigQuery, Athena/Presto (규모·워크로드에 맞춰 단계 도입).

## Notes
- 지오 100만 로우 등 특정 워크로드는 인덱스 전략 최소화/선택적 적용.
