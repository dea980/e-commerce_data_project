#!/bin/bash

# 테스트 리포트 자동 생성 스크립트
# 사용법: ./generate-report.sh

set -e

echo "🧪 테스트 리포트 생성 시작..."

# 현재 날짜
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# 테스트 실행 및 결과 수집
echo "📊 테스트 실행 중..."
cd ..
TEST_OUTPUT=$(python -m pytest test_simple.py test_sql_validation.py -v --tb=short 2>&1 || true)
TEST_RESULT=$?
echo "테스트 실행 완료 (exit code: $TEST_RESULT)"

# 결과 파싱
TOTAL_TESTS=$(echo "$TEST_OUTPUT" | grep -o "[0-9]\+ passed" | grep -o "[0-9]\+")
FAILED_TESTS=$(echo "$TEST_OUTPUT" | grep -o "[0-9]\+ failed" | grep -o "[0-9]\+" || echo "0")
EXEC_TIME=$(echo "$TEST_OUTPUT" | grep -o "in [0-9.]\+s" | grep -o "[0-9.]\+")

if [ -z "$TOTAL_TESTS" ]; then
    TOTAL_TESTS="0"
fi
if [ -z "$EXEC_TIME" ]; then
    EXEC_TIME="0.00"
fi

# 상태 결정
if [ "$TEST_RESULT" -eq 0 ]; then
    STATUS="🎉 PASS"
    STATUS_EMOJI="🟢"
else
    STATUS="❌ FAIL"
    STATUS_EMOJI="🔴"
fi

echo "📝 리포트 생성 중..."

# 간단한 리포트 생성
cat > docs/test-report-${DATE}.md << EOF
# 테스트 실행 리포트

**작성일**: ${DATE}  
**실행 시각**: ${TIMESTAMP}  
**자동 생성**: generate-report.sh  

---

## 📋 실행 요약

| 항목 | 결과 |
|------|------|
| **총 테스트 수** | ${TOTAL_TESTS}개 |
| **성공** | ✅ $((TOTAL_TESTS - FAILED_TESTS))개 |
| **실패** | ❌ ${FAILED_TESTS}개 |
| **실행 시간** | ${EXEC_TIME}초 |
| **전체 상태** | ${STATUS} |

---

## 🔍 상세 실행 로그

\`\`\`
${TEST_OUTPUT}
\`\`\`

---

## 📊 파일 현황

### SQL 파일 현황
EOF

# SQL 파일 목록 추가
echo "$(ls -la ../sql/*.sql | wc -l) 개의 SQL 파일 확인됨" >> docs/test-report-${DATE}.md
echo "" >> docs/test-report-${DATE}.md
echo "```" >> docs/test-report-${DATE}.md
ls -la ../sql/*.sql >> docs/test-report-${DATE}.md
echo "```" >> docs/test-report-${DATE}.md

# 요약 대시보드 업데이트
cat > docs/test-summary.md << EOF
# 테스트 현황 요약

> **최종 업데이트**: ${TIMESTAMP}  
> **상태**: ${STATUS_EMOJI} ${STATUS}

---

## 🎯 핵심 지표

\`\`\`
┌─────────────────────────────────────────────────────┐
│                 테스트 현황 요약                      │
├─────────────────────────────────────────────────────┤
│  총 테스트        │  ${TOTAL_TESTS}개                           │
│  성공            │  $((TOTAL_TESTS - FAILED_TESTS))개 ($((100 * (TOTAL_TESTS - FAILED_TESTS) / TOTAL_TESTS))%)                    │
│  실패            │  ${FAILED_TESTS}개 ($((100 * FAILED_TESTS / TOTAL_TESTS))%)                      │
│  실행시간         │  ${EXEC_TIME}초                         │
│  상태            │  ${STATUS}                        │
└─────────────────────────────────────────────────────┘
\`\`\`

## 📈 최근 실행 결과

| 날짜 | 상태 | 성공률 | 실행시간 |
|------|------|--------|----------|
| ${DATE} | ${STATUS_EMOJI} | $((100 * (TOTAL_TESTS - FAILED_TESTS) / TOTAL_TESTS))% | ${EXEC_TIME}s |

---

## 🚀 빠른 액션

### 테스트 재실행
\`\`\`bash
cd olist-pipeline/tests
python -m pytest test_simple.py test_sql_validation.py -v
\`\`\`

### 새 리포트 생성
\`\`\`bash
./docs/generate-report.sh
\`\`\`

---

**🔄 자동 업데이트**: ${TIMESTAMP}
EOF

echo "✅ 리포트 생성 완료!"
echo "📄 생성된 파일:"
echo "   - docs/test-report-${DATE}.md"
echo "   - docs/test-summary.md (업데이트됨)"

# 결과에 따른 종료 코드
exit $TEST_RESULT
