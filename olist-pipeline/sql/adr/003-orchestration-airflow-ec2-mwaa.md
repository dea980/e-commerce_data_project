---
adr: 003
title: 오케스트레이션 전략 (Airflow: 로컬 → EC2 → MWAA)
status: Accepted
date: 2025-08-26
---

## Context
- 로컬에서 빠른 개발/디버깅, 운영은 클라우드. 장차 완전관리형으로 이관 계획.

## Decision
- 로컬: Docker Compose (Airflow + Postgres + MinIO)
- 클라우드: EC2에서 Airflow(웹+스케줄러). RDS/S3는 관리형.
- 차후: MWAA로 무중단에 가까운 전환.

## Rationale
- 개발 속도, 제어, 이관 난이도 사이의 균형. DAG/경로 동일성 유지.

## Consequences
**Positive**: 환경 패리티, 3-DAG 분리로 운영성↑  
**Negative**: EC2 자가운영 부담(패치/재시작/로그)

## Alternatives
- Prefect/Dagster, Step Functions (팀 역량/요건에 따라 고려)

## Implementation Hints
- 컨테이너 내부 경로 고정 `/opt/airflow/sql` + 볼륨 마운트로 환경 차등.
- 스케줄러 프로세스 반드시 실행.
