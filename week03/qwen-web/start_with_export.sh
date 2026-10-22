#!/bin/bash
cd "$(dirname "$0")" || exit 1
export MODEL="qwen3:0.6b"   # 원래 터미널의 환경 변수는 바꾸지 않음
exec ./start.sh
