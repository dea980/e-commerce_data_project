#!/bin/bash

# Git 커밋 메시지 도우미 스크립트

echo "=== Git 커밋 메시지 도우미 ==="
echo ""

# 변경사항 확인
echo "📋 변경된 파일들:"
git status --short
echo ""

# 커밋 타입 선택
echo "🎯 커밋 타입을 선택하세요:"
echo "1) feat - 새로운 기능"
echo "2) fix - 버그 수정"
echo "3) docs - 문서 수정"
echo "4) style - 코드 포맷팅"
echo "5) refactor - 코드 리팩토링"
echo "6) test - 테스트 추가/수정"
echo "7) chore - 빌드 프로세스 변경"
echo ""

read -p "타입 번호를 입력하세요 (1-7): " type_num

case $type_num in
    1) type="feat";;
    2) type="fix";;
    3) type="docs";;
    4) type="style";;
    5) type="refactor";;
    6) type="test";;
    7) type="chore";;
    *) type="feat";;
esac

# 스코프 입력
echo ""
read -p "스코프를 입력하세요 (pipeline/dag/sql/docs/docker): " scope

# 제목 입력
echo ""
read -p "제목을 입력하세요 (50자 이내): " subject

# 커밋 메시지 생성
commit_message="$type($scope): $subject"

echo ""
echo "📝 생성된 커밋 메시지:"
echo "$commit_message"
echo ""

read -p "이 메시지로 커밋하시겠습니까? (y/n): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    git commit -m "$commit_message"
    echo "✅ 커밋 완료!"
else
    echo "❌ 커밋 취소됨"
fi
