#!/bin/bash
# chat.py가 어디서 실행되든 이 스크립트가 있는 폴더로 이동한 뒤 실행
cd "$(dirname "$0")" || exit 1

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3가 설치되어 있지 않습니다." >&2
    if [ "$(uname)" = "Darwin" ]; then
        echo "[Mac] brew install python" >&2
    else
        echo "[Windows(WSL)/Ubuntu] sudo apt update && sudo apt install python3 -y" >&2
    fi
    exit 1
fi

exec python3 chat.py   # 현재 bash를 python3로 대체 (PID 유지)
