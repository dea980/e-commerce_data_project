---
adr: 006
title: 보안·권한 (IAM Role, SSE-KMS, SG, 비밀관리)
status: Accepted
date: 2025-08-26
---

## Context
- 키 유출 방지, 저장 시 암호화, 최소 노출 네트워크가 필요.

## Decision
- EC2 IAM Role로 S3 접근(Access Key 미사용).
- S3 SSE-S3/SSE-KMS, RDS 저장소 암호화 + 백업/PITR.
- SG 화이트리스트, 8080 접근 제한.
- `.env.aws`는 Git ignore, 장차 Secrets Manager/SSM으로 이관.

## Rationale
- 보안 모범사례 준수, 운영 단순화, 컴플라이언스 대응.

## Consequences
**Positive**: 비밀 관리 사고 리스크↓, 복구 가능성↑.  
**Negative**: KMS/SG 설정 오류 시 접근 실패 → 연동 테스트 필수.

## Alternatives
- RDS Proxy(커넥션/비밀 회전), VPC 엔드포인트(S3) 등 단계적 도입.
