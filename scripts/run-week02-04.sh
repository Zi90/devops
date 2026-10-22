#!/bin/bash
# ---------------------------------------------------------------
# 2~4주차 실습 명령을 다시 실행하고 결과를 weekNN/results/에 저장
#   사용법: bash ~/devops/scripts/run-week02-04.sh
#   파일을 지우거나 시스템을 바꾸는 명령은 없음 (백업 파일은 .gitignore로 제외됨)
# ---------------------------------------------------------------
set -u
ROOT="$HOME/devops"

rec() {
    local file="$1"; shift
    mkdir -p "$(dirname "$file")"
    { echo "\$ $*"; bash -c "$*" 2>&1; } | tee -a "$file"
}

# ---------------- 2주차: 실습 환경과 Git ----------------
O="$ROOT/week02/results"; mkdir -p "$O"; rm -f "$O"/*.txt
cd "$ROOT/week02" || exit 1
echo "==== 2주차"
rec "$O/01-environment.txt" "whoami"
rec "$O/01-environment.txt" "uname -r"
rec "$O/01-environment.txt" "grep -E '^(NAME|VERSION)=' /etc/os-release"
rec "$O/01-environment.txt" "pwd"
rec "$O/01-environment.txt" "df -h / | tail -1"
rec "$O/01-environment.txt" "free -h | head -2"
rec "$O/02-files.txt" "ls -l"
rec "$O/02-files.txt" "cat hello.txt"
rec "$O/02-files.txt" "cat text.txt"
rec "$O/03-git.txt" "git --version"
rec "$O/03-git.txt" "git -C $ROOT remote -v"
rec "$O/03-git.txt" "git -C $ROOT log --oneline --reverse | head -5"

# ---------------- 3주차: 셸 스크립트 ----------------
O="$ROOT/week03/results"; mkdir -p "$O"; rm -f "$O"/*.txt
cd "$ROOT/week03/qwen-web" || exit 1
echo "==== 3주차"
rec "$O/01-start-sh.txt" "ls -l"
rec "$O/01-start-sh.txt" "head -1 start.sh"
rec "$O/01-start-sh.txt" "bash -n start.sh && echo '문법 검사 통과'"
rec "$O/02-exit-code.txt" "command -v python3; echo \"종료 코드: \$?\""
rec "$O/02-exit-code.txt" "command -v 없는명령; echo \"종료 코드: \$?\""
rec "$O/02-exit-code.txt" "cd /no-such-dir || echo '실패하면 || 뒤가 실행됨'"
rec "$O/03-heredoc.txt" "MODEL=qwen3; cat << 'END'
echo \"\$MODEL\"
END"
rec "$O/03-heredoc.txt" "MODEL=qwen3; cat << END
echo \"\$MODEL\"
END"
if command -v ollama >/dev/null 2>&1; then
    rec "$O/04-ollama.txt" "ollama list"
fi

# ---------------- 4주차: 자동화, 프로세스, 백업, 네트워크 ----------------
O="$ROOT/week04/results"; mkdir -p "$O"; rm -f "$O"/*.txt
cd "$ROOT/week04" || exit 1
echo "==== 4주차"
# 검색과 파이프
rec "$O/01-grep-find.txt" "find $ROOT -type f -name '*.sh' -not -path '*/.git/*' | sed \"s|$ROOT/||\" | sort"
rec "$O/01-grep-find.txt" "grep ERROR test/server.log"
rec "$O/01-grep-find.txt" "grep -c ERROR test/server.log"
rec "$O/01-grep-find.txt" "grep -v INFO test/server.log | wc -l"
rec "$O/01-grep-find.txt" "grep -R -n 'exit 1' test | head -5"
# 변수, 인자, 조건
rec "$O/02-scripts.txt" "bash test/var.sh"
rec "$O/02-scripts.txt" "bash test/greet.sh; echo \"종료 코드: \$?\""
rec "$O/02-scripts.txt" "bash test/greet.sh Edwin"
rec "$O/02-scripts.txt" "bash test/check.sh test"
rec "$O/02-scripts.txt" "bash test/check.sh test/server.log"
rec "$O/02-scripts.txt" "bash test/check.sh nothing; echo \"종료 코드: \$?\""
rec "$O/02-scripts.txt" "for f in test/*.sh; do echo \"스크립트: \$f\"; done"
# 프로세스
sleep 300 &
SPID=$!
rec "$O/03-process.txt" "ps -o pid,stat,cmd -p $SPID"
rec "$O/03-process.txt" "kill $SPID; sleep 1; ps -p $SPID >/dev/null || echo 'PID $SPID 종료됨 (SIGTERM)'"
# 백업과 복원 확인
rec "$O/04-backup.txt" "./backup.sh test"
ARCHIVE=$(ls -1t backups/*.tar.gz | head -1)
rm -rf restore-check
rec "$O/04-backup.txt" "tar -tzf $ARCHIVE"
rec "$O/04-backup.txt" "mkdir -p restore-check && tar -xzf $ARCHIVE -C restore-check"
rec "$O/04-backup.txt" "diff -rq test restore-check/test; echo \"diff 종료 코드: \$? (0이면 원본과 같음)\""
# 네트워크
rec "$O/05-network.txt" "ip -4 addr show | grep inet"
rec "$O/05-network.txt" "ping -c 2 8.8.8.8 | tail -2"
if command -v dig >/dev/null 2>&1; then
    rec "$O/05-network.txt" "dig +short github.com"
else
    rec "$O/05-network.txt" "getent hosts github.com"
fi
rec "$O/05-network.txt" "curl -sI https://github.com | head -1"
mkdir -p /tmp/week04-web && echo '<h1>Edwin week04 web server</h1>' > /tmp/week04-web/index.html
( cd /tmp/week04-web && exec python3 -m http.server 8090 >/dev/null 2>&1 ) &
WPID=$!
sleep 1
rec "$O/06-webserver-port.txt" "curl -s http://localhost:8090"
rec "$O/06-webserver-port.txt" "ss -tln | grep -E 'State|:8090'"
rec "$O/06-webserver-port.txt" "cd /tmp/week04-web && timeout 3 python3 -m http.server 8090 2>&1 | tail -1"
rec "$O/06-webserver-port.txt" "kill $WPID; sleep 1; ss -tln | grep -q ':8090 ' || echo '8090 포트 해제됨'"

echo
echo "완료! 결과: week02/results, week03/results, week04/results"
