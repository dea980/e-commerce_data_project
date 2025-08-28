---
adr: 007
title: 비용·성능·스케일 전략
status: Accepted
date: 2025-08-26
---

## Context
- MVP 비용 최소화, 병목에 한해 증설.

## Decision
- RDS 스펙 t3.micro/small → 필요 시 단계적 상향.
- 핵심 조인키/시간축 인덱스 우선.
- 증가 시: RDS 스케일업/리드리플리카 → 캐시 → 웨어하우스 이관.

## Rationale
- 가성비 중심, 실제 병목에만 투자.

## Consequences
**Positive**: 과투자 회피, 예측가능한 비용.  
**Negative**: 대폭 성장 시 리플랫폼 필요.

## Migration Path
- Redshift/Snowflake PoC 후 점진 이관, S3 축 유지.
