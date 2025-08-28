---
doc: appendix-c
title: 이해관계자 설득 포인트
date: 2025-08-26
---

### Why Now
- MVP에서 빠르게 가치 + 신뢰 확보가 핵심.

### Architecture
- S3/MinIO + RDS(Postgres), Airflow 3-DAG, RAW→ODS→DIM, DQ 하드/소프트 + Slack.

### Trust
- ODS 제약 + DQ 하드/소프트로 수치 신뢰 보장.

### Operations
- Slack 알림, `ops.dq_results` 대시보드.

### Cost & Scale
- 지금은 RDS로 가성비, 필요 시 자연스러운 이관 경로.

### Security
- IAM Role, SSE-KMS, SG 최소 노출, 비밀 Git 제외, 백업/PITR.
