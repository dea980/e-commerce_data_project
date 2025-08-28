---
adr: 001
title: 데이터 레이어링 (RAW → ODS → DIM) 채택
status: Accepted
date: 2025-08-26
deciders: Data Eng, Analytics, ML, BA
---

## Context
- 원천은 CSV로, 향후 스키마/값 변경 가능성이 있음.
- MVP 단계에서 빠른 적재가 필요하고, 이후 신뢰 가능한 분석/피처/대시보드가 필요함.

## Decision
- **RAW**: TEXT 중심으로 느슨한 스키마 + 메타컬럼(`_batch_id`, `_ingested_at`, `_src_key`, `_src_etag`).
- **ODS**: 정타입 변환 및 **PK/FK/CHECK** 제약, 시간 순서/범위/형식 검증.
- **DIM/마트**: 리포팅·피처 목적의 집계/차원 테이블.

## Rationale
- 적재 실패 내성(스키마/값 변화)과 의미적 품질 통제를 분리.
- 배치 단위 추적성/재현성 확보(메타컬럼).

## Consequences
**Positive**
- KPI/분석 신뢰도 상승.
- 장애 원인 추적·롤백 용이.
- 소비자(분석/ML)용 단순/성능 최적 테이블 제공.

**Negative**
- 레이어 증가로 DDL/ETL 코드량 증가 및 관리 필요.

## Options Considered
- 2계층(RAW→DIM): 속도↑, 신뢰·유지보수↓
- 웨어하우스 단일 계층(Snowflake/BigQuery): 강력하나 초기 도입/비용↑

## Guardrails / Metrics
- RAW→ODS 변환 실패율
- ODS FK 위반 수
- DIM 집계 재현율
