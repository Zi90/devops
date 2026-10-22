#!/bin/bash
cd "$(dirname "$0")" || exit 1
export WEB_PORT="8080"      # 포트를 8080으로 바꿔서 실행
exec ./start.sh
