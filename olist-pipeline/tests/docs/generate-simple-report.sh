#!/bin/bash

# 간단한 테스트 리포트 생성 스크립트

echo "🧪 테스트 리포트 생성 중..."

DATE=$(date +%Y-%m-%d)
TIME=$(date +"%H:%M:%S")

# 테스트 실행
cd ..
echo "📊 테스트 실행..."
python -m pytest test_simple.py test_sql_validation.py -v > test_results.log 2>&1
TEST_STATUS=$?

# 결과 파싱
PASSED_COUNT=$(grep -c "PASSED" test_results.log || echo "0")
FAILED_COUNT=$(grep -c "FAILED" test_results.log || echo "0")
TOTAL_COUNT=$((PASSED_COUNT + FAILED_COUNT))

if [ $TEST_STATUS -eq 0 ]; then
    STATUS="🎉 ALL PASS"
    STATUS_COLOR="🟢"
else
    STATUS="❌ SOME FAILED"
    STATUS_COLOR="🔴"
fi

# 리포트 생성
cat > docs/latest-test-report.md << EOF
# 테스트 실행 리포트

**생성일시**: ${DATE} ${TIME}  
**상태**: ${STATUS_COLOR} ${STATUS}

## 📊 실행 결과

- **총 테스트**: ${TOTAL_COUNT}개
- **성공**: ✅ ${PASSED_COUNT}개
- **실패**: ❌ ${FAILED_COUNT}개
- **성공률**: $((PASSED_COUNT * 100 / TOTAL_COUNT))%

## 📋 상세 로그

\`\`\`
$(cat test_results.log)
\`\`\`

## 📁 SQL 파일 현황

$(ls -la sql/*.sql | wc -l)개의 SQL 파일이 확인되었습니다.

---
*자동 생성: generate-simple-report.sh*
EOF

# 요약 업데이트
cat > docs/current-status.md << EOF
# 현재 테스트 상태

> 최종 업데이트: ${DATE} ${TIME}

## 🎯 현재 상태
- **상태**: ${STATUS_COLOR} ${STATUS}
- **총 테스트**: ${TOTAL_COUNT}개
- **성공률**: $((PASSED_COUNT * 100 / TOTAL_COUNT))%

## 🔗 상세 리포트
- [최신 테스트 리포트](./latest-test-report.md)

EOF

# 정리
rm test_results.log

echo "✅ 리포트 생성 완료!"
echo "📄 생성된 파일:"
echo "   - docs/latest-test-report.md"
echo "   - docs/current-status.md"
echo ""
echo "📊 결과 요약:"
echo "   - 총 ${TOTAL_COUNT}개 테스트"
echo "   - ${PASSED_COUNT}개 성공, ${FAILED_COUNT}개 실패"
echo "   - 상태: ${STATUS}"
