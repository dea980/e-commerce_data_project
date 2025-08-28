---
adr: 004
title: 데이터 품질 전략 (하드/소프트, 배치ID, Slack)
status: Accepted
date: 2025-08-26
---

## Context
- 지표 신뢰 확보와 장애 조기 탐지가 필수.

## Decision
- `ops.dq_results` 로깅 테이블 도입.
- **Hard DQ**: PK 유일, FK 무결성, 범위(1~5) 위반시 DAG 실패.
- **Soft DQ**: 음수 금액 비율, 타임라인 역전, 결제↔아이템 오차율, 신선도 등 경고 기록 + Slack 알림.
- `{{BATCH_ID}}`로 배치 상관관계 유지.

## Rationale
- 오염 차단(하드), 민첩 대응/경향 파악(소프트), 추적성 강화(배치ID).

## Consequences
**Positive**: 신뢰/MTTR 개선, 투명한 품질 근거.  
**Negative**: SQL 규칙 증가 시 관리 복잡도↑ → 프레임워크 도입 여지.

## Alternatives
- Great Expectations, Soda, Deequ, OpenLineage(라인리지).

## SQL Assets
- `03_dq_hard.sql`, `04_dq_soft.sql` (Airflow 태스크로 실행).
