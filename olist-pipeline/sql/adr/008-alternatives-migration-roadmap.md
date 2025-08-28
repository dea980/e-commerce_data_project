---
adr: 008
title: 대안 비교 & 마이그레이션 로드맵
status: Draft
date: 2025-08-26
---

## Alternatives Snapshot
- **Airflow on EC2 → MWAA**: 운영 자율성 ↔ 관리 편의.
- **RDS Postgres → Redshift/Snowflake/BigQuery**: 비용/성능/워크로드 기준 전환.
- **SQL DQ → Great Expectations/Soda**: 규칙 규모·리포팅 요구에 따른 확장.

## Roadmap (Example)
1. MVP 고도화: DQ 지표 대시보드, 알림 임계 조정.
2. 운영 안정화: RDS 파라미터/인덱스 튜닝, 백업 리허설.
3. 확장: MWAA 전환, RDS Proxy/Secrets 도입.
4. 웨어하우스 PoC: 상위 집계/피처를 점진 이관.
