# 테스트 문서화 센터

이 디렉토리는 E-commerce 데이터 파이프라인 테스트의 모든 문서를 중앙화하여 관리합니다.

## 📚 문서 구조

```
tests/docs/
├── README.md                      # 이 파일 (문서 가이드)
├── test-report-2025-08-27.md      # 상세 테스트 실행 리포트
├── test-summary.md                # 테스트 현황 요약 대시보드
└── (향후 추가 예정)
    ├── performance-report.md       # 성능 테스트 리포트
    ├── coverage-report.md          # 코드 커버리지 리포트
    └── integration-test-report.md  # 통합 테스트 리포트
```

## 🎯 각 문서의 목적

### 📊 [test-summary.md](./test-summary.md)
- **용도**: 빠른 현황 파악
- **대상**: 팀 리더, 프로젝트 매니저
- **내용**: 핵심 지표, 상태 대시보드, 트렌드
- **업데이트**: 매 테스트 실행 후

### 📋 [test-report-2025-08-27.md](./test-report-2025-08-27.md)
- **용도**: 상세한 테스트 분석
- **대상**: 개발자, QA 엔지니어
- **내용**: 테스트별 상세 결과, 이슈 분석, 개선 방안
- **업데이트**: 주요 테스트 실행 시

## 🔄 문서 업데이트 주기

| 문서 | 업데이트 주기 | 담당자 | 자동화 여부 |
|------|--------------|--------|------------|
| test-summary.md | 매 테스트 실행 후 | CI/CD 파이프라인 | ✅ 예정 |
| test-report-*.md | 주간/중요 변경 시 | 개발팀 | ❌ 수동 |
| README.md | 구조 변경 시 | 테크 리드 | ❌ 수동 |

## 📈 리포트 생성 가이드

### 새로운 테스트 리포트 생성
```bash
# 테스트 실행 및 리포트 생성
cd olist-pipeline/tests
python -m pytest test_simple.py test_sql_validation.py -v --tb=short > results.txt

# 리포트 파일명 규칙: test-report-YYYY-MM-DD.md
cp test-report-template.md test-report-$(date +%Y-%m-%d).md
```

### 요약 대시보드 업데이트
```bash
# test-summary.md 업데이트 (수동 또는 스크립트)
# - 테스트 수행 결과 반영
# - 트렌드 데이터 업데이트
# - 마일스톤 진행 상황 갱신
```

## 🎨 문서 작성 가이드

### 스타일 가이드
- **제목**: H1(#)은 문서당 1개만
- **섹션**: H2(##), H3(###) 계층적 사용
- **상태 표시**: 이모지 활용 (✅❌⚠️🟢🟡🔴)
- **코드 블록**: 언어 명시 (```bash, ```sql 등)
- **표**: 가독성을 위해 정렬 사용

### 필수 포함 내용
1. **실행 요약**: 테스트 수, 성공/실패 수, 실행 시간
2. **상세 결과**: 테스트별 성공/실패 상태
3. **발견된 이슈**: 경고, 에러, 개선 사항
4. **다음 단계**: 액션 아이템, 개선 계획

### 템플릿 활용
```markdown
# 테스트 리포트 템플릿

**작성일**: YYYY-MM-DD
**실행자**: [이름]
**테스트 환경**: [환경 정보]

## 📋 실행 요약
- 총 테스트: [수]개
- 성공: [수]개
- 실패: [수]개
- 상태: [PASS/FAIL]

## 🔍 상세 결과
[테스트별 결과]

## ⚠️ 발견된 이슈
[이슈 목록]

## 🚀 다음 단계
[액션 아이템]
```

## 🔗 관련 리소스

### 내부 문서
- [../README.md](../README.md): 테스트 실행 가이드
- [../../sql/Glossary.md](../../sql/Glossary.md): SQL 용어집
- [../../../README-Roadmap.md](../../../README-Roadmap.md): 프로젝트 로드맵

### 외부 참조
- [pytest 문서](https://docs.pytest.org/)
- [SQL 테스트 모범 사례](https://www.getdbt.com/blog/how-we-test-our-sql/)
- [데이터 품질 테스트 가이드](https://greatexpectations.io/blog/testing-data-quality/)

## 📞 문의 및 지원

### 테스트 관련 문의
- **Slack**: #data-engineering
- **이메일**: data-team@company.com
- **이슈 트래킹**: GitHub Issues

### 문서 개선 제안
1. GitHub Pull Request 생성
2. 문서 리뷰 요청
3. 팀 승인 후 병합

## 🏷️ 버전 히스토리

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| v1.0 | 2025-08-27 | 초기 문서화 센터 구축 | Data Engineering Team |
| v1.1 | (예정) | 자동화 스크립트 추가 | DevOps Team |
| v2.0 | (예정) | 통합 테스트 리포트 추가 | QA Team |

---

**📌 중요**: 이 문서들은 팀의 데이터 파이프라인 품질 보장을 위한 핵심 자료입니다. 정기적인 업데이트와 검토를 통해 최신 상태를 유지해 주세요.
