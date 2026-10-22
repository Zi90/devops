#!/bin/bash
# ---------------------------------------------------------------
# 7주차 도커 컴포즈 실습을 순서대로 실행하고 결과를 week07/results/에 저장
#   사용법: bash ~/devops/scripts/run-week07.sh
#   [주의] 중간에 down -v 단계가 있어서 방명록 글(Redis 데이터)이 한 번 초기화됨
# ---------------------------------------------------------------
set -u
ROOT="$HOME/devops"
GB="$ROOT/guestbook"
OUT="$ROOT/week07/results"
mkdir -p "$OUT"
cd "$GB" || { echo "$GB 가 없습니다." >&2; exit 1; }

step() { echo; echo "==== $*"; }
# 결과 파일에 명령어와 출력을 함께 기록
rec() {
    local file="$OUT/$1"; shift
    { echo "\$ $*"; eval "$@" 2>&1; } | tee -a "$file"
}
wait_healthy() {
    local i
    for i in $(seq 1 60); do
        local n
        n=$(docker compose ps web --format '{{.Health}}' 2>/dev/null | grep -c '^healthy$')
        [ "$n" -ge "${1:-3}" ] && return 0
        sleep 2
    done
    echo "web이 healthy가 되지 않았습니다. docker compose logs web 확인" >&2
    return 1
}
count_entries() {
    curl -s localhost:8080/api/entries | python3 -c "import sys,json;print(json.load(sys.stdin)['count'])"
}
add_entry() {
    curl -s -o /dev/null -X POST localhost:8080/add --data-urlencode "name=$1" --data-urlencode "message=$2"
}

rm -f "$OUT"/*.txt

step "0. .env 준비 (Git에는 올리지 않음)"
if [ ! -f .env ]; then
    echo "REDIS_PASSWORD=$(openssl rand -hex 12)" > .env
    echo ".env 생성"
fi
grep -qx ".env" "$ROOT/.gitignore" 2>/dev/null || echo ".env" >> "$ROOT/.gitignore"

step "1. config로 미리 검사"
rec 01-config.txt "docker compose config --quiet && echo OK"
rec 01-config.txt "docker compose config | grep requirepass -A1"
rec 02-config-error.txt "REDIS_PASSWORD= docker compose config --quiet"

step "2. 전체 실행 (nginx 1 + web 3 + redis 1)"
docker compose down >/dev/null 2>&1
rec 03-up.txt "docker compose up -d --build"
wait_healthy 3
rec 04-ps-healthy.txt "docker compose ps"
rec 04-ps-healthy.txt "docker inspect --format '{{.Name}} {{.State.Health.Status}}' \$(docker compose ps -q)"
rec 04-ps-healthy.txt "docker compose logs web | grep -m3 Redis"

step "3. 글 3개 남기기"
add_entry "Edwin" "7주차 compose 실습 첫 글"
add_entry "Edwin" "web을 재시작해도 글이 남는지 확인"
add_entry "Edwin" "nginx가 web 3개에 요청을 나눠줌"
rec 05-entries.txt "curl -s localhost:8080/api/entries"

step "4. scale: 새로고침할 때마다 다른 web이 응답"
rec 06-scale-hostnames.txt "docker ps --format '{{.ID}} {{.Names}}' | sort -k2"
rec 06-scale-hostnames.txt "for i in 1 2 3 4 5 6 7 8 9; do curl -s localhost:8080/healthz; echo; done"

step "5. web만 재시작해도 글 유지"
rec 07-restart-web.txt "echo 재시작 전 글 개수: \$(count_entries)"
rec 07-restart-web.txt "docker compose restart web"
wait_healthy 3
rec 07-restart-web.txt "echo 재시작 후 글 개수: \$(count_entries)"

step "6. down 후 up (볼륨 유지) vs down -v 후 up (볼륨 삭제)"
rec 08-down-vs-down-v.txt "echo down 전 글 개수: \$(count_entries)"
rec 08-down-vs-down-v.txt "docker compose down"
rec 08-down-vs-down-v.txt "docker volume ls | grep redis-data"
rec 08-down-vs-down-v.txt "docker compose up -d"
wait_healthy 3
rec 08-down-vs-down-v.txt "echo down 후 up, 글 개수: \$(count_entries)"
rec 08-down-vs-down-v.txt "docker compose down -v"
rec 08-down-vs-down-v.txt "docker volume ls | grep redis-data || echo '볼륨 없음'"
rec 08-down-vs-down-v.txt "docker compose up -d"
wait_healthy 3
rec 08-down-vs-down-v.txt "echo down -v 후 up, 글 개수: \$(count_entries)"

step "7. 네트워크 격리: redis는 바깥에서 안 보이고 안에서는 이름으로 보임"
rec 09-network.txt "python3 -c \"import socket; socket.create_connection(('127.0.0.1', 6379), timeout=2)\" || echo '→ 호스트에서 redis 6379 접속 실패 (ports 없음)'"
rec 09-network.txt "docker compose exec web python -c \"import socket; print('redis =', socket.gethostbyname('redis'))\""
rec 09-network.txt "docker compose exec web python -c \"import socket; socket.create_connection(('redis', 6379), 2); print('TCP 연결 성공')\""

step "8. [과제 4번] web=3 항상 유지: 하나를 멈추고 keep-web3.sh로 복구"
W2=$(docker compose ps -q web | sed -n 2p)
W3=$(docker compose ps -q web | sed -n 3p)
rec 10-keep-web3.txt "docker compose ps web --format '{{.Name}} {{.Status}}'"
rec 10-keep-web3.txt "docker stop $W2 >/dev/null && echo 'web 하나 중지 (docker stop)'"
rec 10-keep-web3.txt "docker compose ps web --format '{{.Name}} {{.Status}}'"
rec 10-keep-web3.txt "$ROOT/week07/keep-web3.sh --once"
wait_healthy 3
rec 10-keep-web3.txt "docker compose ps web --format '{{.Name}} {{.Status}}'"
rec 10-keep-web3.txt "docker rm -f $W3 >/dev/null && echo 'web 하나 삭제 (docker rm -f)'"
rec 10-keep-web3.txt "docker compose ps web --format '{{.Name}} {{.Status}}'"
rec 10-keep-web3.txt "$ROOT/week07/keep-web3.sh --once"
wait_healthy 3
rec 10-keep-web3.txt "docker compose ps web --format '{{.Name}} {{.Status}}'"

step "9. 캡처용으로 글 다시 남기기 (서비스는 계속 실행 중)"
add_entry "Edwin" "7주차: nginx + web x3 + redis"
add_entry "박건희" "새로고침하면 Pod/Host가 바뀝니다"

echo
echo "완료! 결과 파일: $OUT"
ls -1 "$OUT"
echo
echo "다음: 브라우저에서 http://localhost:8080 을 열고 새로고침하며 Pod/Host가 바뀌는 화면을 캡처하세요."
