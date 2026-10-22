# 5주차 - 도커 (Docker) w/ GitHub Issue

> "내 컴퓨터에서는 되는데요?" → 앱만 보내지 말고 앱 + 라이브러리 + 설정을 함께 묶어서 보내자 = **컨테이너**

## 오늘 배운 내용

- **Docker** = 애플리케이션을 개발(Develop), 배포(Ship), 실행(Run)하기 위한 플랫폼
- **VM vs 컨테이너**: VM은 하드웨어를 가상화해서 Guest OS를 각각 띄우고, 컨테이너는 호스트 OS 커널을 **공유**하면서 실행 환경만 격리한다 → 가볍고 빠름
  - 격리 기술: **namespace**(프로세스, 파일 시스템, 네트워크 격리), **cgroup**(CPU, 메모리 사용량 제한)
  - 윈도우는 WSL2, 맥은 Linux VM 위에서 돌아간다 (윈도우/맥 커널을 직접 공유하는 게 아님)
- **구성 요소**: Dockerfile →(build)→ **Image**(읽기 전용 틀) →(run)→ **Container**(실행 중인 인스턴스), **Registry**(이미지 창고, 예: Docker Hub)
  - 이미지 : 컨테이너 = 붕어빵 틀 : 붕어빵 = 프로그램 : 프로세스
- **Client-Server 구조**: `docker` 명령(클라이언트)이 직접 실행하는 게 아니라 `dockerd`(데몬)에게 요청한다
- 컨테이너 안에서 고친 내용은 컨테이너를 지우면 **사라진다** (쓰기 계층) → 6주차 Dockerfile, 7주차 볼륨으로 해결
- **GitHub Issue 기반 작업 흐름**: Issue(할 일 정의) → 이슈 번호로 브랜치 → 커밋 → PR(`Closes #번호`) → Merge → 이슈 자동 종료

## docker run 옵션 읽기

```text
docker run -d -p 8080:80 --name web nginx
           │  │          │          └ 이미지
           │  │          └ 컨테이너 이름 (같은 이름은 2개 불가)
           │  └ 호스트 8080 → 컨테이너 80 (같은 호스트 포트는 2개 불가)
           └ 백그라운드 실행 (detached)
```

## 실습 결과

실습은 [`scripts/run-week05.sh`](../scripts/run-week05.sh)로 다시 실행했고, 결과는 [`results/`](results/)에 저장했다.

### 1. 설치 확인

로컬에 hello-world 이미지가 없었는데 레지스트리에서 **환경째로** 내려받아 실행됐다.

<!-- RESULT: results/01-docker-version.txt -->
```text
$ docker --version
Docker version 29.1.3, build 29.1.3-0ubuntu3~24.04.2
$ docker run --rm hello-world | head -4

Hello from Docker!
This message shows that your installation appears to be working correctly.
```
<!-- /RESULT -->

### 2. nginx 컨테이너 (서버 설치 없이 웹 서버)

nginx도 파이썬도 설치하지 않았는데 웹 서버가 떴다. 컨테이너 안은 Debian이다.

<!-- RESULT: results/02-nginx.txt -->
```text
$ docker run -d -p 8080:80 --name web nginx
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
9a2c3eb3312e: Pulling fs layer
8334177aa35b: Pulling fs layer
dd00b11a22aa: Pulling fs layer
24bf03b6a474: Pulling fs layer
a856bfc2a772: Pulling fs layer
f2be67225471: Pulling fs layer
d5f3a4724daf: Pulling fs layer
9a2c3eb3312e: Download complete
8334177aa35b: Download complete
dd00b11a22aa: Download complete
24bf03b6a474: Download complete
a856bfc2a772: Download complete
ee284e8d8c11: Download complete
6542b5f86ffd: Download complete
d5f3a4724daf: Download complete
f2be67225471: Download complete
f2be67225471: Pull complete
9a2c3eb3312e: Pull complete
8334177aa35b: Pull complete
dd00b11a22aa: Pull complete
24bf03b6a474: Pull complete
a856bfc2a772: Pull complete
d5f3a4724daf: Pull complete
Digest: sha256:4c41e2d0a3a55b325ed572cd0200bdb72af1433c3daa2bca6ef8eea68ce504a2
Status: Downloaded newer image for nginx:latest
5a45da5148f4e61d2ef80a5f6fd6e69262c6ceb07ae191f313db0a40b1ec6a0c
$ curl -sI http://localhost:8080 | head -3
HTTP/1.1 200 OK
Server: nginx/1.31.8
Date: Thu, 22 Oct 2026 06:14:20 GMT
$ docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'
NAMES     IMAGE     PORTS                                     STATUS
web       nginx     0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   Up 2 seconds
$ docker logs web 2>&1 | tail -3
2026/10/22 06:14:18 [notice] 1#1: start worker process 36
2026/10/22 06:14:18 [notice] 1#1: start worker process 37
172.17.0.1 - - [22/Oct/2026:06:14:20 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/8.5.0" "-"
$ docker exec web cat /etc/os-release | head -2
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
```
<!-- /RESULT -->

### 3. 같은 코드, 다른 파이썬 버전

`--rm`으로 쓰고 버리는 컨테이너를 만들어 버전별 결과를 바로 비교할 수 있다. `-e`로 환경 변수를 넣을 수 있다.

<!-- RESULT: results/03-python-versions.txt -->
```text
$ docker run --rm python:3.9-slim python --version
Unable to find image 'python:3.9-slim' locally
3.9-slim: Pulling from library/python
ea56f685404a: Pulling fs layer
b3ec39b36ae8: Pulling fs layer
38513bd72563: Pulling fs layer
fc7443084902: Pulling fs layer
ea56f685404a: Download complete
b3ec39b36ae8: Download complete
a5e5b1b19090: Download complete
fc7443084902: Download complete
967a6079ce08: Download complete
38513bd72563: Download complete
38513bd72563: Pull complete
b3ec39b36ae8: Pull complete
ea56f685404a: Pull complete
fc7443084902: Pull complete
Digest: sha256:2d97f6910b16bd338d3060f261f53f144965f755599aab1acda1e13cf1731b1b
Status: Downloaded newer image for python:3.9-slim
Python 3.9.25
$ docker run --rm python:3.12-slim python --version
Unable to find image 'python:3.12-slim' locally
3.12-slim: Pulling from library/python
be6443c06d3c: Pulling fs layer
5c397e4307db: Pulling fs layer
b524bb3aba73: Pulling fs layer
5c397e4307db: Download complete
be6443c06d3c: Download complete
be6443c06d3c: Pull complete
a19c1c598c82: Download complete
9a229e332182: Download complete
b524bb3aba73: Download complete
5c397e4307db: Pull complete
b524bb3aba73: Pull complete
Digest: sha256:cb33f7f771ecec2ef1225cf39b159591a040391bd73e4c01f00fdfc4c47611d2
Status: Downloaded newer image for python:3.12-slim
Python 3.12.15
$ docker run --rm -e MY_NAME=Edwin python:3.12-slim python -c "import os; print('MY_NAME =', os.environ['MY_NAME'])"
MY_NAME = Edwin
```
<!-- /RESULT -->

### 4. 혼자 해보기: nginx 3개를 다른 포트로

같은 이미지로 컨테이너 3개를 만들고(`8091~8093`), 각각 `exec`로 들어가 `index.html`을 다르게 고쳤다.

<!-- RESULT: results/04-nginx3.txt -->
```text
$ docker run -d -p 8091:80 --name nginx1 nginx
9d0a65b2977c86cc68faabb8f34adf3fabd6d7cf9886e394a076d35633033301
$ docker run -d -p 8092:80 --name nginx2 nginx
39f31bd23e0556c0cb488130980deca3b88de3c6c25f0f82f542806ec540ff52
$ docker run -d -p 8093:80 --name nginx3 nginx
35096eb58973e74544379811b76c36a6527691f5a19638fb956b8753b809611a
$ curl -s http://localhost:8091
<h1>nginx1 - Edwin의 컨테이너 1번</h1>
$ curl -s http://localhost:8092
<h1>nginx2 - Edwin의 컨테이너 2번</h1>
$ curl -s http://localhost:8093
<h1>nginx3 - Edwin의 컨테이너 3번</h1>
$ docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}'
NAMES     PORTS                                     STATUS
nginx3    0.0.0.0:8093->80/tcp, [::]:8093->80/tcp   Up 2 seconds
nginx2    0.0.0.0:8092->80/tcp, [::]:8092->80/tcp   Up 2 seconds
nginx1    0.0.0.0:8091->80/tcp, [::]:8091->80/tcp   Up 2 seconds
web       0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   Up 24 seconds
```
<!-- /RESULT -->

### 5. 정리

<!-- RESULT: results/05-cleanup.txt -->
```text
$ docker rm -f web nginx1 nginx2 nginx3
web
nginx1
nginx2
nginx3
$ docker ps -a --format '{{.Names}}' | grep -E '^(web|nginx[123])$' || echo '정리 완료'
정리 완료
```
<!-- /RESULT -->

## 새로 배운 명령어

```bash
docker run [-d] [-p 호스트:컨테이너] [--name 이름] [-e KEY=값] [--rm] [-it] 이미지
docker ps [-a]                  # 실행 중 / 전체 컨테이너
docker images                   # 이미지 목록
docker logs [-f] 이름           # 로그 (-f: 실시간)
docker stop / start / restart 이름
docker rm [-f] 이름             # 컨테이너 삭제 (-f: 실행 중이어도)
docker exec -it 이름 bash       # 컨테이너 안으로 (exit 해도 컨테이너는 살아 있음)
docker system df                # 디스크 사용량
gh issue create / gh pr create / gh pr merge --squash --delete-branch
```
