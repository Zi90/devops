#!/bin/bash
# ---------------------------------------------------------------
# keep-web3.sh : web 컨테이너를 "항상 3개(healthy)"로 유지하는 감시 스크립트
#
#   원하는 상태(desired)  = web 3개, 모두 healthy
#   현재 상태(current)    = docker compose ps 로 확인
#   다르면 → 원하는 상태로 되돌린다 (조정 루프, reconcile loop)
#
# 사용법
#   ./keep-web3.sh            # 계속 감시 (Ctrl+C로 종료)
#   ./keep-web3.sh --once     # 한 번만 검사하고 종료 (테스트용)
#   DESIRED=5 INTERVAL=3 ./keep-web3.sh   # 개수, 검사 간격(초) 바꾸기
# ---------------------------------------------------------------

cd "$(dirname "$0")/../guestbook" || exit 1   # compose.yaml이 있는 곳으로 이동

DESIRED="${DESIRED:-3}"      # 유지할 web 개수
INTERVAL="${INTERVAL:-5}"    # 검사 간격(초)
SERVICE="web"

if ! command -v docker >/dev/null 2>&1; then
    echo "docker 명령을 찾을 수 없습니다." >&2
    exit 1
fi

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

check_once() {
    # 1) 실행 중인 web 컨테이너 ID 목록
    local ids running
    ids=$(docker compose ps -q --status running "$SERVICE")
    running=$(echo "$ids" | grep -c .)

    # 2) 실행 중이지만 unhealthy인 컨테이너는 재시작
    #    (restart: always는 '종료'된 컨테이너만 살린다. 'unhealthy'는 살리지 않는다)
    local id name health
    for id in $ids; do
        health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$id")
        if [ "$health" = "unhealthy" ]; then
            name=$(docker inspect --format '{{.Name}}' "$id")
            log "${name#/} 상태가 unhealthy → 재시작"
            docker restart "$id" >/dev/null
        fi
    done

    # 3) 개수가 다르면 원하는 개수로 맞추기
    if [ "$running" -ne "$DESIRED" ]; then
        log "web 실행 중 ${running}개 (목표 ${DESIRED}개) → 복구 시작"
        # --no-recreate : 멀쩡한 컨테이너는 건드리지 않고, 멈춘 것은 다시 켜고, 없는 것은 새로 만든다
        if docker compose up -d --no-recreate --scale "$SERVICE=$DESIRED" "$SERVICE" >/dev/null 2>&1; then
            log "복구 완료 → web $(docker compose ps -q --status running "$SERVICE" | grep -c .)개"
        else
            log "복구 실패 (docker compose up 오류)" >&2
            return 1
        fi
    fi
    return 0
}

if [ "$1" = "--once" ]; then
    check_once
    exit $?
fi

log "감시 시작: $SERVICE ${DESIRED}개 유지, ${INTERVAL}초마다 검사 (종료: Ctrl+C)"
trap 'log "감시 종료"; exit 0' INT TERM
while true; do
    check_once
    sleep "$INTERVAL"
done
