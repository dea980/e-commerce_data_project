---
adr: 005
title: 경로·환경 일관성 (SQL_DIR=/opt/airflow/sql, S3_PREFIX 규칙)
status: Accepted
date: 2025-08-26
---

## Context
- 로컬/EC2/MWAA 간 코드 변경 없이 배포하고자 함.

## Decision
- DAG/SQL은 컨테이너 내부에서 항상 `/opt/airflow/sql` 사용.
- 호스트별로 볼륨 마운트만 다르게 설정.
- `S3_PREFIX`는 앞 슬래시 없음, **끝에 `/`**, 루트면 빈값.

## Rationale
- 경로 차이로 인한 배포 실패 제거, 코드 불변 유지.

## Consequences
**Positive**: 배포 리스크↓, 온보딩 단순화.  
**Negative**: 호스트 경로 관리가 compose에 의존.

## Snippet
```python
# dag/_common.py
import os
SQL_DIR = os.getenv("SQL_DIR", "/opt/airflow/sql")
def read_sql(basename:str)->str:
    with open(f"{SQL_DIR}/{basename}.sql","r",encoding="utf-8") as f:
        return f.read()
```
