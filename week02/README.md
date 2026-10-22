# 2주차 - 실습 환경 구축과 버전 관리 기초

> WSL2 + Ubuntu로 리눅스 실습 환경을 만들고, Git으로 버전을 관리하고, GitHub에 공유한다.

## 오늘 배운 내용

### 서버와 가상화

- **서버**는 하드웨어이기도 하고 소프트웨어이기도 하다. "전원을 켠다"는 하드웨어, "서버를 설치했다"는 소프트웨어 → 문맥으로 구분
- 서버(Serve: 제공하다)는 클라이언트의 **요청(Request)**을 받아 **응답(Response)**한다
- 서버 운영 방법 세 가지

| 방식 | 구조 | 특징 |
|---|---|---|
| 베어메탈 | PC 1대에 OS 1개, 그 위에 여러 프로그램 | 관리는 쉽지만 하나가 뚫리거나 자원을 많이 쓰면 나머지도 위험 |
| 하이퍼바이저 | PC 1대에 가상 머신 여러 개, 각자 Guest OS와 커널 | 격리는 강하지만 무겁다 (커널이 여러 개) |
| 컨테이너 | PC 1대에 컨테이너 여러 개, **호스트 커널 공유** | 가볍고 빠름. 격리는 **namespace**, 자원 제한은 **cgroups** |

- 저사양 컴퓨터 여러 대보다 고사양 한 대를 가상화해서 나눠 쓰는 편이 비용, 공간, 인력 면에서 경제적이다

### WSL2와 Ubuntu

- **WSL**(Windows Subsystem for Linux): 윈도우에서 리눅스를 가상 머신보다 가볍게 실행. 탐색기에서 `\\wsl.localhost\Ubuntu-24.04`로 파일 접근 가능
- 설치와 확인은 파워셸(관리자)에서

```powershell
wsl --install -d Ubuntu-24.04      # 설치 (-d: distribution)
wsl -l -v                          # 목록 (-l: list, -v: verbose)
wsl --set-version Ubuntu-24.04 2   # WSL 2로
wsl --set-default Ubuntu-24.04     # 기본 배포판
```

- 작업 공간은 리눅스 쪽 홈에 만든다: `mkdir ~/devops`
- Ubuntu = "I am because we are" (우리가 있기에 내가 있다) → 오픈소스의 나눔과 협력

### 리눅스 기본 명령어

- `ls -l` 권한 읽기: `-rwxr-xr--` = 파일 종류 / 소유자 rwx / 그룹 r-x / 기타 r--
- `chmod 750 a.sh` = 소유자 7(4+2+1), 그룹 5(4+1), 기타 0 (r=4, w=2, x=1)
- `>`는 덮어쓰기, `>>`는 이어 쓰기
- 파일 이름이 `.`으로 시작하면 숨김 파일 (`ls -a`로 보임)

### Git

```text
[작업 디렉터리] ──git add──> [스테이징 영역] ──git commit──> [저장소] ──git push──> [GitHub]
   (수정한 파일)                (장바구니)                    (확정된 기록)
```

- `git add`는 저장이 아니라 **다음 커밋에 담을 파일을 고르는 것**
- 커밋은 버전 하나. `git log`로 이력, `git diff`로 변경 비교, 브랜치로 평행 세계를 만든다

## 실습 결과

[`scripts/run-week02-04.sh`](../scripts/run-week02-04.sh)로 명령을 다시 실행한 결과다.

### 내 실습 환경

<!-- RESULT: results/01-environment.txt -->
```text
$ whoami
edwin
$ uname -r
6.18.33.2-microsoft-standard-WSL2
$ grep -E '^(NAME|VERSION)=' /etc/os-release
NAME="Ubuntu"
VERSION="24.04.4 LTS (Noble Numbat)"
$ pwd
/home/edwin/devops/week02
$ df -h / | tail -1
/dev/sdd       1007G  4.9G  951G   1% /
$ free -h | head -2
               total        used        free      shared  buff/cache   available
Mem:            15Gi       595Mi        14Gi       3.5Mi       290Mi        14Gi
```
<!-- /RESULT -->

### 첫 커밋에 올렸던 파일

처음에는 저장소 루트에 있던 `hello.txt`, `text.txt`를 2주차 폴더로 옮겨 정리했다.

<!-- RESULT: results/02-files.txt -->
```text
$ ls -l
total 16
-rw-r--r-- 1 edwin edwin 3624 Oct 22 15:12 README.md
-rw-r--r-- 1 edwin edwin    3 Sep 14 17:51 hello.txt
drwxr-xr-x 2 edwin edwin 4096 Oct 22 15:14 results
-rw-r--r-- 1 edwin edwin   15 Sep 14 17:50 text.txt
$ cat hello.txt
hi
$ cat text.txt
Hello, Devops!
```
<!-- /RESULT -->

### Git 저장소

<!-- RESULT: results/03-git.txt -->
```text
$ git --version
git version 2.43.0
$ git -C /home/edwin/devops remote -v
origin	https://github.com/Zi90/devops.git (fetch)
origin	https://github.com/Zi90/devops.git (push)
$ git -C /home/edwin/devops log --oneline --reverse | head -5
1603c8e devops
c2cbeeb week06: 나만의 방명록 v2
```
<!-- /RESULT -->

## 새로 배운 명령어

```bash
pwd / ls -la / cd ~ .. - / mkdir / rmdir / touch
cat / less / head / tail / cp / mv / rm
chmod +x 파일 / chmod 755 파일
whoami / id / uname -a / df -h / free -h
history / !! / !103 / !ls / sudo !!
sudo apt update / sudo apt install 패키지
nano 파일          # ^O 저장, ^X 종료, ^K 잘라내기, ^U 붙여넣기
git init / git add / git commit -m "메시지" / git log --oneline / git diff
git switch -c 브랜치 / git push / gh auth login
```
