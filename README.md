# DevOps

2026-2 인하공업전문대학 컴퓨터정보공학과 DevOps 실습 저장소 (Zi90)

리눅스와 셸 스크립트로 시작해서 Git 협업, 네트워크, 도커, 도커파일, 도커 컴포즈까지 주차별로 실습한 내용을 기록합니다.

## 주차별 내용

| 주차 | 주제 | 핵심 | 기록 |
|---|---|---|---|
| 1주차 | 오리엔테이션 | 강의 소개, DevOps란 | (없음) |
| 2주차 | 실습 환경 구축과 버전 관리 기초 | 가상화, WSL2, 리눅스 명령어, Git | [week02](./week02/) |
| 3주차 | 셸 스크립팅 | Ollama + Qwen, `start.sh`, 종료 코드, 리다이렉션 | [week03](./week03/) |
| 4주차 | 자동화와 협업 / 네트워크 | grep·find·파이프, 백업 스크립트, 브랜치·PR·Merge, IP·포트·DNS | [week04](./week04/) |
| 5주차 | 도커 w/ GitHub Issue | 이미지와 컨테이너, docker 명령어, Issue 기반 작업 | [week05](./week05/) |
| 6주차 | 도커파일 | Dockerfile, 레이어 캐시, ghcr.io 푸시 | [week06](./week06/) |
| 7주차 | 도커 컴포즈 | nginx + web x3 + redis, healthcheck, .env, scale, web=3 유지 | [week07](./week07/) |

## 방명록 앱 (guestbook)

6주차부터 계속 업데이트하는 앱입니다. 주차별로 복사하지 않고 [`guestbook/`](./guestbook/) 하나를 고쳐 나가며, 변화는 Git 이력과 태그(`week06`, `week07`)로 남깁니다.

```bash
# 이미지 하나로 실행 (6주차)
docker run -d -p 8081:5000 ghcr.io/zi90/guestbook:v2

# 전체 서비스로 실행 (7주차): nginx 1 + web 3 + redis 1
cd guestbook
cp .env.example .env          # 비밀번호를 내 값으로 바꾸기
docker compose up -d
# → http://localhost:8080
```

| 항목 | 값 |
|---|---|
| 내 이미지 | `ghcr.io/zi90/guestbook:v2` |
| 구성 | [`compose.yaml`](./guestbook/compose.yaml), [`nginx.conf`](./guestbook/nginx.conf), [`.env.example`](./guestbook/.env.example) |
| web=3 유지 | [`week07/keep-web3.sh`](./week07/keep-web3.sh) |

## Issue에서 Merge까지

작업은 **Issue로 할 일을 정의 → 이슈 번호로 브랜치 → 커밋 → Pull Request(`Closes #번호`) → Merge**의 순서로 진행합니다. Merge되면 이슈가 자동으로 닫힙니다.

- [닫힌 이슈 목록](https://github.com/Zi90/devops/issues?q=is%3Aissue+is%3Aclosed)
- [병합된 PR 목록](https://github.com/Zi90/devops/pulls?q=is%3Apr+is%3Amerged)

## 실습 자동 실행 스크립트

주차별 실습 명령을 그대로 다시 실행하고, 결과를 `weekNN/results/`에 저장해 README에 채워 넣습니다.

| 스크립트 | 하는 일 |
|---|---|
| [`scripts/run-week02-04.sh`](./scripts/run-week02-04.sh) | 2~4주차: 환경 정보, 종료 코드, grep/find, 백업·복원, 네트워크, 포트 충돌 |
| [`scripts/run-week05.sh`](./scripts/run-week05.sh) | 5주차: hello-world, nginx, 파이썬 버전 비교, nginx 3개 |
| [`scripts/run-week07.sh`](./scripts/run-week07.sh) | 7주차: config 검사, healthy, scale, down vs down -v, 네트워크 격리, web=3 복구 |
| [`scripts/fill-readme.py`](./scripts/fill-readme.py) | 결과 파일을 README의 표시 자리에 채워 넣기 |
| [`scripts/publish.sh`](./scripts/publish.sh) | Issue → 브랜치 → 커밋 → PR → Merge 자동 진행 |

## 저장소 구조

```text
devops/
├── README.md
├── guestbook/        # 방명록 앱 (Dockerfile, compose.yaml, nginx.conf)
├── scripts/          # 실습 자동 실행, README 채우기, Issue→Merge
├── week02/ ... week07/
│   ├── README.md
│   └── results/      # 실습 명령 실행 결과
└── .gitignore        # .env, 백업 파일 등 제외
```
