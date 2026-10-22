#!/bin/bash
# ---------------------------------------------------------------
# 2~7주차 실습을 순서대로 다시 실행하고 README에 결과를 채운다
#   사용법: bash ~/devops/scripts/run-all.sh
# ---------------------------------------------------------------
set -u
ROOT="$HOME/devops"
S="$ROOT/scripts"
WIN_DL="/mnt/c/Users/edwin/Downloads"

pause() { echo; read -r -p ">>> $* (Enter) " _; }

bash "$S/run-week02-04.sh"
pause "2~4주차 완료. 5주차 도커 기초 실습을 시작합니다"

bash "$S/run-week05.sh"
pause "5주차 완료. 7주차 도커 컴포즈 실습을 시작합니다 (빌드 때문에 1~2분 걸릴 수 있음)"

bash "$S/run-week07.sh" || { echo "7주차 실습 중 오류. 화면의 메시지를 확인하세요." >&2; exit 1; }

cat <<EOF

================================================================
 캡처할 차례입니다 (3장)
   1. 브라우저에서 http://localhost:8080 열기
   2. 새로고침하면서 'Pod/Host:' 값이 다른 화면 3장을 캡처
   3. 다운로드 폴더에 scale-1.png, scale-2.png, scale-3.png 로 저장
      (Win + Shift + S → 캡처 → 그림판 등에 붙여넣고 저장)
================================================================
EOF
pause "3장을 저장했으면"
for i in 1 2 3; do
    if [ -f "$WIN_DL/scale-$i.png" ]; then
        cp "$WIN_DL/scale-$i.png" "$ROOT/week07/images/scale-$i.png" && echo "복사: scale-$i.png"
    else
        echo "없음: $WIN_DL/scale-$i.png (나중에 week07/images/ 에 직접 넣어도 됨)"
    fi
done

echo
echo "==== README에 실행 결과 채우기"
python3 "$S/fill-readme.py" "$ROOT"/week0*/README.md

echo
echo "완료! 다음 명령:  bash ~/devops/scripts/publish.sh   (Issue → PR → Merge)"
