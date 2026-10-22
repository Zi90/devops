#!/bin/bash
# ---------------------------------------------------------------
# Issue → Branch → Commit → Push → Pull Request → Merge 를 순서대로 진행
#   사용법: bash ~/devops/scripts/publish.sh
#   각 단계의 결과(이슈 번호, PR 주소)를 화면에 보여주고 ~/devops-workflow-log.txt 에 남김
# ---------------------------------------------------------------
set -eu
cd "$HOME/devops"
LOG="$HOME/devops-workflow-log.txt"   # 저장소 밖에 기록 (보고서 작성용)
: > "$LOG"
say() { echo; echo "==== $*" | tee -a "$LOG"; }
run() { echo "\$ $*" | tee -a "$LOG"; "$@" 2>&1 | tee -a "$LOG"; }

say "0. 사전 확인"
gh auth status >/dev/null 2>&1 || { echo "gh 로그인이 필요합니다: gh auth login" >&2; exit 1; }
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "저장소: $REPO" | tee -a "$LOG"
run git switch main
run git pull --ff-only

say "1. Issue 만들기"
BODY=$(cat <<'EOF'
## 목표
중간 프로젝트 보고서 제출을 위해 저장소를 정리하고 7주차 도커 컴포즈 실습을 반영한다.

## 할 일
- [ ] 저장소 정리: Windows 다운로드 흔적(`*:Zone.Identifier`) 삭제, `.gitignore`에 `.env` 추가
- [ ] 루트 `README.md` 목차 작성
- [ ] 주차별 `README.md` 작성 (week02 ~ week07)
- [ ] 7주차: `compose.yaml`(nginx + web x3 + redis), `nginx.conf`, `.env.example`
- [ ] 7주차: healthcheck, `.env` 분리, scale, down / down -v 결과 기록
- [ ] web=3을 항상 유지하는 방법 (`deploy.replicas`, `restart: always`, `keep-web3.sh`)

## 완료 조건
- `docker compose ps`에서 web 3개가 모두 healthy
- `.env`는 Git에 올라가지 않음
EOF
)
ISSUE_URL=$(gh issue create --title "중간 프로젝트: 7주차 도커 컴포즈 실습 + 주차별 README 정리" --body "$BODY")
ISSUE_NO=${ISSUE_URL##*/}
echo "이슈 생성: #$ISSUE_NO  $ISSUE_URL" | tee -a "$LOG"

say "2. 이슈 번호로 작업 브랜치 만들기"
BRANCH="feature/issue-${ISSUE_NO}-week07-compose"
run git switch -c "$BRANCH"

say "3. 작업 내용 반영 (정리 + 추가)"
# Windows에서 받은 파일에 붙는 흔적 파일 삭제
git ls-files | grep 'Zone.Identifier$' | while IFS= read -r f; do git rm -q --cached -- "$f"; rm -f -- "$f"; echo "삭제: $f"; done | tee -a "$LOG"
find . -name '*Zone.Identifier' -not -path './.git/*' -type f -print -delete | tee -a "$LOG"
run git add -A
# 안전 장치: .env 가 올라가려 하면 중단
if git diff --cached --name-only | grep -E '(^|/)\.env$'; then
    echo ".env 가 커밋에 포함되어 있어 중단합니다." >&2; exit 1
fi
run git status --short
run git commit -q -m "feat: 7주차 compose + nginx + healthcheck, 주차별 README 정리 (#${ISSUE_NO})"
run git log --oneline -1

say "4. Push 후 Pull Request 만들기"
run git push -u origin "$BRANCH"
PR_URL=$(gh pr create --base main --head "$BRANCH" \
    --title "7주차 도커 컴포즈 실습 + 주차별 README 정리" \
    --body "Closes #${ISSUE_NO}

## 변경 내용
- 7주차: compose.yaml (nginx + web x3 + redis), nginx.conf, .env.example
- web=3 유지: deploy.replicas: 3, restart: always, week07/keep-web3.sh
- 주차별 README (week02 ~ week07), 루트 README 목차
- 실습 자동 실행 스크립트 (scripts/)
- Zone.Identifier 정리, .gitignore에 .env 추가

## 확인
- [x] docker compose config --quiet 통과
- [x] web 3개 healthy, scale 후 Pod/Host 변경 확인
- [x] .env 미포함")
PR_NO=${PR_URL##*/}
echo "PR 생성: #$PR_NO  $PR_URL" | tee -a "$LOG"

say "5. 이슈 체크박스 완료 표시"
gh issue edit "$ISSUE_NO" --body "${BODY//- \[ \]/- [x]}" >/dev/null && echo "체크 완료" | tee -a "$LOG"

echo
echo "브라우저에서 PR을 확인하고 캡처하세요: $PR_URL"
echo "  (Files changed 탭, Conversation 탭에 'Closes #${ISSUE_NO}'가 보이면 좋습니다)"
read -r -p "캡처가 끝나면 Enter → Merge 진행 " _

say "6. Merge (squash) 후 브랜치 삭제"
run gh pr merge "$PR_NO" --squash --delete-branch
run git switch main
run git pull --ff-only
run git log --oneline -3

say "7. 결과 확인"
run gh issue view "$ISSUE_NO" --json state,url -q '"이슈 상태: \(.state)  \(.url)"'
run gh pr view "$PR_NO" --json state,mergedAt,url -q '"PR 상태: \(.state)  병합: \(.mergedAt)  \(.url)"'
if ! git rev-parse -q --verify refs/tags/week07 >/dev/null; then
    run git tag week07
    run git push origin week07
fi

echo
echo "완료! 이슈: $ISSUE_URL"
echo "      PR : $PR_URL"
echo "기록 파일: $LOG"
