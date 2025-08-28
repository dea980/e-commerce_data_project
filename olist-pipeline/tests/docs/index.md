# 📊 테스트 문서 인덱스

> **E-commerce 데이터 파이프라인 테스트 센터**  
> 모든 테스트 관련 문서와 리포트를 한 곳에서 관리합니다.

---

## 🚀 빠른 시작

### 현재 테스트 상태 확인
👉 **[테스트 현황 요약](./test-summary.md)** - 한눈에 보는 테스트 상태

### 상세 분석이 필요하다면
👉 **[상세 테스트 리포트](./test-report-2025-08-27.md)** - 완전한 분석과 권고사항

---

## 📚 문서 목록

| 문서 | 설명 | 대상 독자 | 업데이트 |
|------|------|-----------|----------|
| 📋 [test-summary.md](./test-summary.md) | 핵심 지표 대시보드 | 관리자, 팀 리더 | 자동 |
| 📊 [test-report-2025-08-27.md](./test-report-2025-08-27.md) | 상세 실행 리포트 | 개발자, QA | 수동 |
| 📖 [README.md](./README.md) | 문서화 가이드 | 모든 팀원 | 필요시 |
| 🏠 [index.md](./index.md) | 이 파일 (인덱스) | 모든 팀원 | 필요시 |

---

## 🎯 목적별 문서 선택

### 👨‍💼 관리자 / 팀 리더
```
빠른 현황 파악이 필요하다면
└── 📋 test-summary.md (2분 읽기)

프로젝트 상태 보고가 필요하다면  
└── 📊 test-report-2025-08-27.md (10분 읽기)
```

### 👩‍💻 개발자 / QA 엔지니어
```
테스트 실패 원인을 찾고 있다면
└── 📊 test-report-2025-08-27.md → "발견된 이슈" 섹션

새로운 테스트를 추가하고 싶다면
└── 📖 README.md → "테스트 작성 가이드" 섹션

테스트 실행 방법을 알고 싶다면
└── ../README.md (상위 디렉토리)
```

### 🔧 DevOps / 자동화 담당자
```
CI/CD 통합을 계획하고 있다면
└── 📊 test-report-2025-08-27.md → "다음 단계" 섹션

자동화 스크립트가 필요하다면
└── generate-report.sh, generate-simple-report.sh
```

---

## 📈 최신 테스트 현황 (요약)

```
🎯 상태: 🟢 ALL PASS
📊 성공률: 100% (25/25)
⏱️ 실행시간: 0.06초
📅 마지막 업데이트: 2025-08-27
```

### 검증 완료 영역
- ✅ SQL 파일 구조 (23개 파일)
- ✅ 데이터 품질 로직 (Hard/Soft DQ)
- ✅ 비즈니스 규칙 검증
- ✅ 파일 명명 규칙
- ✅ 스키마 참조 무결성

---

## 🔄 정기 업데이트 스케줄

| 문서 | 주기 | 담당 | 방법 |
|------|------|------|------|
| test-summary.md | 매 테스트 실행 | 자동화 | CI/CD |
| test-report-*.md | 주간/중요 변경시 | 개발팀 | 수동 |
| README.md | 구조 변경시 | 테크리드 | 수동 |
| index.md | 월간 | 문서 관리자 | 수동 |

---

## 🛠️ 유용한 명령어

### 테스트 실행
```bash
# 기본 테스트
cd ../
python -m pytest test_simple.py test_sql_validation.py -v

# 특정 테스트만
python -m pytest test_sql_validation.py::TestSQLFileStructure -v

# 커버리지 포함
python -m pytest --cov=../sql --cov-report=term
```

### 리포트 생성 (향후 개선 예정)
```bash
# 자동 리포트 생성 (개발 중)
./generate-report.sh

# 간단 리포트 생성 (개발 중)  
./generate-simple-report.sh
```

---

## 🔗 관련 리소스

### 내부 문서
- [../README.md](../README.md) - 테스트 실행 가이드
- [../../sql/Glossary.md](../../sql/Glossary.md) - SQL 용어집  
- [../../../README-Roadmap.md](../../../README-Roadmap.md) - 프로젝트 로드맵

### 테스트 파일들
- [../test_simple.py](../test_simple.py) - 기본 기능 테스트
- [../test_sql_validation.py](../test_sql_validation.py) - SQL 검증 테스트
- [../conftest.py](../conftest.py) - pytest 설정

---

## 📞 도움이 필요하다면

### 💬 즉시 도움
- **Slack**: #data-engineering 채널
- **이메일**: data-team@company.com

### 🐛 버그 리포트 / 개선 제안
- **GitHub Issues**: 새로운 이슈 생성
- **Pull Request**: 직접 개선사항 제안

### 📖 추가 학습 자료
- [pytest 공식 문서](https://docs.pytest.org/)
- [SQL 테스트 모범 사례](https://www.getdbt.com/blog/how-we-test-our-sql/)
- [데이터 품질 테스트 가이드](https://greatexpectations.io/blog/testing-data-quality/)

---

## 🏆 성과 요약

이 테스트 프레임워크를 통해 달성한 것들:

- 🎯 **100% 테스트 통과**: 25개 모든 테스트 성공
- 🔍 **포괄적 검증**: SQL, 데이터 품질, 비즈니스 로직 모두 커버
- ⚡ **빠른 실행**: 0.06초만에 전체 검증 완료
- 📚 **체계적 문서화**: 모든 과정과 결과를 문서로 관리
- 🔄 **지속적 개선**: 자동화와 확장을 위한 기반 마련

---


*마지막 업데이트: 2025-08-27 | 문서 버전: v1.0*
