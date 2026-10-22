# 4주차 - 자동화와 협업 / 네트워크

> 반복 작업은 스크립트로, 변경은 브랜치와 PR로 안전하게 합친다. 서버는 IP(건물)와 포트(호실)로 찾아간다.

## Part 1. 자동화와 협업

### 배운 내용

- **절대 경로**(`/home/edwin/devops/...`)와 **상대 경로**(`./week03/...`). 스크립트에서 `cd "$(dirname "$0")"`를 쓰는 이유는 어디서 실행해도 상대 경로가 깨지지 않게 하기 위해서
- **검색**: `find`(파일 이름으로), `grep`(파일 내용으로), `|`(파이프: 앞 명령의 출력을 뒤 명령의 입력으로)
  - grep의 유래: `g/re/p` (global / regular expression / print)
- **셸 스크립트 기본기**: 변수(`NAME="값"`, 공백 없이), 명령 치환(`$(date +%Y%m%d)`), 인자(`$1`, `$#`), 조건(`[ -f 파일 ]`, `[ -d 폴더 ]`, `[ -z 문자열 ]`), 반복(`for f in *.sh`)
- **프로그램 vs 프로세스**: 디스크의 실행 파일 vs 메모리에서 실행 중인 것(PID). `kill`(SIGTERM, 정리할 기회) / `kill -9`(SIGKILL, 즉시) / Ctrl+C(SIGINT)
- **백업**: `tar -czf`로 묶고 압축, `diff -rq`로 원본과 복원본 비교. 백업 파일은 Git에 올리지 않음 → `.gitignore`
- **협업 흐름**: 브랜치(실패해도 안전한 평행 세계) → Pull Request(합치기 전 리뷰) → Conflict 해결 → Merge
  - Conflict는 Git이 모르는 게 아니라 **함부로 결정하지 않는 것**. `<<<<<<< HEAD ... ======= ... >>>>>>>` 부분을 사람이 고른다
  - Merge 옵션: `--merge`(머지 커밋), `--squash`(커밋을 하나로), `--rebase`(줄 세우기)

### 실습 결과

[`scripts/run-week02-04.sh`](../scripts/run-week02-04.sh)로 명령을 다시 실행한 결과다.

#### grep, find, 파이프

<!-- RESULT: results/01-grep-find.txt -->
```text
$ find /home/edwin/devops -type f -name '*.sh' -not -path '*/.git/*' | sed "s|/home/edwin/devops/||" | sort
scripts/publish.sh
scripts/run-all.sh
scripts/run-week02-04.sh
scripts/run-week05.sh
scripts/run-week07.sh
week03/qwen-web/start.sh
week03/qwen-web/start_with_export.sh
week03/qwen-web/start_with_export_2.sh
week04/backup.sh
week04/test/check.sh
week04/test/greet.sh
week04/test/var.sh
week07/keep-web3.sh
$ grep ERROR test/server.log
2026-07-13 10:02:11 ERROR DB 연결 끊김
2026-07-13 10:02:12 ERROR 재시도 실패
2026-07-13 10:09:13 ERROR 요청 타임아웃
$ grep -c ERROR test/server.log
3
$ grep -v INFO test/server.log | wc -l
5
$ grep -R -n 'exit 1' test | head -5
test/greet.sh:4:  exit 1
test/check.sh:4:  echo "파일명을 입력하세요"; exit 1
test/check.sh:12:  echo "없음"; exit 1
```
<!-- /RESULT -->

#### 변수, 인자, 조건, 반복 (`test/*.sh`)

<!-- RESULT: results/02-scripts.txt -->
```text
$ bash test/var.sh
이름: 홍길동
파일명: backup_20261022.tar.gz
$ bash test/greet.sh; echo "종료 코드: $?"
사용법: test/greet.sh [이름]
종료 코드: 1
$ bash test/greet.sh Edwin
안녕하세요, Edwin님! (인자 개수: 1)
$ bash test/check.sh test
디렉터리
$ bash test/check.sh test/server.log
파일
$ bash test/check.sh nothing; echo "종료 코드: $?"
없음
종료 코드: 1
$ for f in test/*.sh; do echo "스크립트: $f"; done
스크립트: test/check.sh
스크립트: test/greet.sh
스크립트: test/var.sh
```
<!-- /RESULT -->

#### 프로세스 만들고 종료하기

<!-- RESULT: results/03-process.txt -->
```text
$ ps -o pid,stat,cmd -p 1035
    PID STAT CMD
   1035 S+   sleep 300
$ kill 1035; sleep 1; ps -p 1035 >/dev/null || echo 'PID 1035 종료됨 (SIGTERM)'
PID 1035 종료됨 (SIGTERM)
```
<!-- /RESULT -->

#### 백업과 복원 확인 ([`backup.sh`](backup.sh))

`diff` 종료 코드 0 = 원본과 복원본이 같다. `backups/`, `restore-check/`는 `.gitignore`로 제외했다.

<!-- RESULT: results/04-backup.txt -->
```text
$ ./backup.sh test
백업 시작: test → backups/20261022_151404_1052.tar.gz
백업 완료! (크기: 4.0K)
현재 보관 중인 백업:
20261022_151404_1052.tar.gz
$ tar -tzf backups/20261022_151404_1052.tar.gz
test/
test/greet.sh
test/diary.txt
test/var.sh
test/check.sh
test/errors.txt
test/server.log
$ mkdir -p restore-check && tar -xzf backups/20261022_151404_1052.tar.gz -C restore-check
$ diff -rq test restore-check/test; echo "diff 종료 코드: $? (0이면 원본과 같음)"
diff 종료 코드: 0 (0이면 원본과 같음)
```
<!-- /RESULT -->

#### 브랜치 → PR → Merge

```bash
git switch -c feature/backup-log
git add week04/backup.sh && git commit -m "feat: 백업 로그 기록 기능 추가"
git push -u origin feature/backup-log
gh pr create --title "백업 로그 기록 기능 추가" --base main
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
# 충돌이 나면: gh pr checkout 번호 → git merge origin/main → 파일 수정 → add → commit → push → merge
```

이 흐름은 중간 프로젝트에서 Issue부터 Merge까지 실제로 진행했다 ([루트 README](../README.md#issue에서-merge까지)).

## Part 2. 네트워크

### 배운 내용

- **IP** = 컴퓨터의 주소(건물), **포트** = 그 안의 서비스(호실). `IP:포트`로 표현
  - 공인 IP / 사설 IP, 사설 IP는 **NAT**로 인터넷에 나간다. `127.0.0.1` = localhost = 나 자신
  - 자주 쓰는 포트: 22(SSH), 80(HTTP), 443(HTTPS), 6379(Redis), 11434(Ollama)
- **DNS** = 이름(github.com)을 IP로 바꿔 주는 전화번호부
- **TCP/IP** = 택배: IP는 주소, 포트는 받는 사람, TCP는 빠짐없이 순서대로 전달
- **HTTP 응답 코드**: 200 성공, 301/302 이동, 404 없음, 500 서버 오류, 502 게이트웨이 오류
- **0.0.0.0**에서 대기하면 모든 네트워크에서 접속 가능, **127.0.0.1**이면 내 PC 안에서만
- 같은 포트를 두 프로그램이 쓰면 **포트 충돌**(`Address already in use`) → 다른 포트 사용 또는 기존 프로세스 종료
- 포트가 LISTEN이어도 **방화벽**이 막으면 바깥에서 접근 불가
- WSL2는 기본 NAT 방식이라 윈도우와 다른 가상 네트워크 IP를 쓴다

### 실습 결과

#### 내 IP, 연결, DNS, HTTP

<!-- RESULT: results/05-network.txt -->
```text
$ ip -4 addr show | grep inet
    inet 127.0.0.1/8 scope host lo
    inet 10.255.255.254/32 brd 10.255.255.254 scope global lo
    inet 172.27.153.47/20 brd 172.27.159.255 scope global eth0
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
$ ping -c 2 8.8.8.8 | tail -2
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 35.155/35.970/36.786/0.815 ms
$ getent hosts github.com
20.200.245.247  github.com
$ curl -sI https://github.com | head -1
HTTP/2 200
```
<!-- /RESULT -->

#### 웹 서버 띄우기와 포트 충돌

`python3 -m http.server 8090`으로 웹 서버를 띄우고 curl로 접속한 뒤, 같은 포트로 하나 더 띄워서 충돌을 확인했다.

<!-- RESULT: results/06-webserver-port.txt -->
```text
$ curl -s http://localhost:8090
<h1>Edwin week04 web server</h1>
$ ss -tln | grep -E 'State|:8090'
State  Recv-Q Send-Q  Local Address:Port  Peer Address:PortProcess
LISTEN 0      5             0.0.0.0:8090       0.0.0.0:*          
$ cd /tmp/week04-web && timeout 3 python3 -m http.server 8090 2>&1 | tail -1
OSError: [Errno 98] Address already in use
$ kill 1114; sleep 1; ss -tln | grep -q ':8090 ' || echo '8090 포트 해제됨'
8090 포트 해제됨
```
<!-- /RESULT -->

## 새로 배운 명령어

```bash
find . -type f -name "*.sh" / grep -R -n "exit 1" week03 / grep -c ERROR / wc -l
head / tail -f / sort / uniq / cut / tee
ps aux | grep bash / jobs / sleep 300 & / kill PID / kill -9 PID / htop
tar -czf a.tar.gz 폴더 / tar -tzf / tar -xzf a.tar.gz -C 대상 / diff -rq
ip addr / ping -c 3 / dig +short / curl -I / curl -s url | jq / ss -tlnp
python3 -m http.server 8080
git switch -c / git diff / gh pr create / gh pr merge --squash --delete-branch
```
