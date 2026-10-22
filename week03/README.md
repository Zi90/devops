# 3주차 - 셸 스크립팅

> 내 PC에서 AI 모델(Qwen)을 Ollama로 띄우고, 매번 경로를 외워 실행하던 과정을 셸 스크립트 하나로 만든다.

## 오늘 배운 내용

- **Ollama** = 모델을 실행하고 관리하는 로컬 서버, **Qwen** = 질문에 답을 만드는 모델 (`qwen3:0.6b`)
  - `b` = Billion. 0.6b는 약 6억 개 파라미터. 클수록 더 많은 패턴을 담지만 느리고 메모리를 많이 쓴다
- `chat.py`(파이썬 웹 앱)가 Ollama에 요청을 보내고, 브라우저 `http://localhost:8000`에서 대화한다
- 며칠 뒤에도 `cd ~/devops/week03/qwen-web && python3 chat.py`를 기억할 수 있을까? → **셸 스크립트**

## 폴더 구조

```text
week03/
└── qwen-web/
    ├── chat.py                 # LMS에서 받은 웹 앱
    ├── start.sh                # 어디서 실행해도 동작하는 실행 스크립트
    ├── start_with_export.sh    # 환경 변수 MODEL을 넣고 실행
    └── start_with_export_2.sh  # 환경 변수 WEB_PORT=8080으로 실행
```

## start.sh 분석

```bash
#!/bin/bash                          # 셔뱅: 이 파일은 bash로 해석하라
cd "$(dirname "$0")" || exit 1       # 스크립트가 있는 폴더로 이동, 실패하면 종료 코드 1
                                     #   $0 = 스크립트 경로, dirname = 폴더 부분만
                                     #   $(...) = 명령어 치환, "..." = 경로에 공백이 있어도 안전
if ! command -v python3 >/dev/null 2>&1; then   # python3가 없으면
    echo "Python3가 설치되어 있지 않습니다." >&2  # 표준 오류로 안내
    exit 1                                      # 실패 상태로 종료
fi
exec python3 chat.py                 # 현재 bash를 python3로 대체 (PID 유지, 뒤 줄은 실행 안 됨)
```

| 문법 | 뜻 |
|---|---|
| `$0`, `$1`, `$#`, `$@`, `$?` | 스크립트 이름, 첫 인자, 인자 개수, 모든 인자, 직전 명령의 종료 상태 |
| `A \|\| B` | A가 **실패**하면 B 실행 (종료 상태 0 = 성공) |
| `>/dev/null 2>&1` | 표준 출력은 버리고, 표준 오류(2)도 표준 출력(1)이 가는 곳으로 |
| `>&2` | 메시지를 표준 오류로 출력 (0 stdin, 1 stdout, 2 stderr) |
| `export VAR=값` | 자식 프로세스(실행한 프로그램)에 환경 변수 전달. 원래 터미널은 안 바뀜 |
| `cat > f << 'EOF'` | 히어독. 따옴표가 있으면 `$변수`를 글자 그대로 저장 |

`./start.sh`가 `Permission denied`면 실행 권한이 없는 것 → `chmod u+x start.sh`

## 실습 결과

[`scripts/run-week02-04.sh`](../scripts/run-week02-04.sh)로 명령을 다시 실행한 결과다.

### 실행 권한과 셔뱅

<!-- RESULT: results/01-start-sh.txt -->
```text
$ ls -l
total 20
-rw-r--r-- 1 edwin edwin 5265 Sep 14 17:23 chat.py
-rwxr-xr-x 1 edwin edwin  518 Oct 22 15:12 start.sh
-rwxr-xr-x 1 edwin edwin  143 Oct 22 15:12 start_with_export.sh
-rwxr-xr-x 1 edwin edwin  127 Oct 22 15:12 start_with_export_2.sh
$ head -1 start.sh
#!/bin/bash
$ bash -n start.sh && echo '문법 검사 통과'
문법 검사 통과
```
<!-- /RESULT -->

### 종료 코드와 `||`

<!-- RESULT: results/02-exit-code.txt -->
```text
$ command -v python3; echo "종료 코드: $?"
/usr/bin/python3
종료 코드: 0
$ command -v 없는명령; echo "종료 코드: $?"
종료 코드: 1
$ cd /no-such-dir || echo '실패하면 || 뒤가 실행됨'
bash: line 1: cd: /no-such-dir: No such file or directory
실패하면 || 뒤가 실행됨
```
<!-- /RESULT -->

### 히어독: 따옴표가 있을 때와 없을 때

`'END'`처럼 따옴표를 붙이면 `$MODEL`이 글자 그대로, 없으면 현재 값(`qwen3`)으로 바뀌어 저장된다.

<!-- RESULT: results/03-heredoc.txt -->
```text
$ MODEL=qwen3; cat << 'END'
echo "$MODEL"
END
echo "$MODEL"
$ MODEL=qwen3; cat << END
echo "$MODEL"
END
echo "qwen3"
```
<!-- /RESULT -->

## 새로 배운 명령어

```bash
ollama pull qwen3:0.6b / ollama list
curl -fsS http://127.0.0.1:11434/api/generate -d '{...}'   # 모델에 직접 요청
python3 chat.py                       # 웹 앱 실행 (Ctrl+C로 종료)
explorer.exe .                        # 현재 폴더를 윈도우 탐색기로
cp "/mnt/c/Users/PC/Downloads/chat.py" .
mkdir -p a/b/c                        # -p: 상위 폴더까지
chmod u+x start.sh && ./start.sh
command -v python3; echo $?
export PATH="$PATH:$HOME/devops/week03/qwen-web/"
```
