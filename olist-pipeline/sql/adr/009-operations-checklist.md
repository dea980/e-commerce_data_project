---
doc: appendix-a
title: 운영 체크리스트
date: 2025-08-26
---

- 스케줄러가 반드시 실행(웹서버만 X).
- Airflow 볼륨 마운트: `../dag:/opt/airflow/dags`, `../sql:/opt/airflow/sql`.
- `.env.local/.env.aws`: `AIRFLOW_CONN_POSTGRES_DEFAULT`, S3 변수, (선택) Slack.
- `ops.dq_results` 최근 24h 소프트 실패율 관측, 하드 실패 즉시 RCA.
- S3 권한/KMS 정책: `s3:GetObject,ListBucket`, 필요 시 `kms:Decrypt`.
