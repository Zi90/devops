#!/bin/bash
# ---------------------------------------------------------------
# 5주차 도커 기초 실습을 다시 실행하고 결과를 week05/results/에 저장
#   사용법: bash ~/devops/scripts/run-week05.sh
#   8080, 8091~8093 포트를 잠깐 사용하고 끝나면 컨테이너를 정리함
# ---------------------------------------------------------------
set -u
ROOT="$HOME/devops"
OUT="$ROOT/week05/results"
mkdir -p "$OUT"
rm -f "$OUT"/*.txt

rec() {
    local file="$OUT/$1"; shift
    { echo "\$ $*"; bash -c "$*" 2>&1; } | tee -a "$file"
}

# 7주차 compose가 8080을 쓰고 있으면 잠시 다른 포트 사용
PORT=8080
if ss -ltn 2>/dev/null | grep -q ':8080 '; then PORT=8088; fi

docker rm -f web nginx1 nginx2 nginx3 >/dev/null 2>&1

echo "==== 1. 설치 확인"
rec 01-docker-version.txt "docker --version"
rec 01-docker-version.txt "docker run --rm hello-world | head -4"

echo "==== 2. nginx 컨테이너 실행과 기본 명령어"
rec 02-nginx.txt "docker run -d -p $PORT:80 --name web nginx"
sleep 2
rec 02-nginx.txt "curl -sI http://localhost:$PORT | head -3"
rec 02-nginx.txt "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'"
rec 02-nginx.txt "docker logs web 2>&1 | tail -3"
rec 02-nginx.txt "docker exec web cat /etc/os-release | head -2"

echo "==== 3. 같은 코드, 다른 파이썬 버전 (--rm 일회용 컨테이너)"
rec 03-python-versions.txt "docker run --rm python:3.9-slim python --version"
rec 03-python-versions.txt "docker run --rm python:3.12-slim python --version"
rec 03-python-versions.txt "docker run --rm -e MY_NAME=Edwin python:3.12-slim python -c \"import os; print('MY_NAME =', os.environ['MY_NAME'])\""

echo "==== 4. 혼자 해보기: nginx 3개를 다른 포트로"
for i in 1 2 3; do
    rec 04-nginx3.txt "docker run -d -p 809$i:80 --name nginx$i nginx"
done
sleep 2
for i in 1 2 3; do
    docker exec nginx$i sh -c "printf '<!doctype html><meta charset="utf-8"><h1>nginx$i - Edwin의 컨테이너 $i번</h1>' > /usr/share/nginx/html/index.html"
done
for i in 1 2 3; do
    rec 04-nginx3.txt "curl -s http://localhost:809$i"
done
rec 04-nginx3.txt "docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}'"

echo
echo "브라우저 캡처를 원하면 지금 http://localhost:8091 ~ 8093 을 열어서 찍으세요."
read -r -p "캡처가 끝났거나 건너뛰려면 Enter → 컨테이너 정리 " _
rec 05-cleanup.txt "docker rm -f web nginx1 nginx2 nginx3"
rec 05-cleanup.txt "docker ps -a --format '{{.Names}}' | grep -E '^(web|nginx[123])$' || echo '정리 완료'"
echo "완료! 결과 파일: $OUT"
