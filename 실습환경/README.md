# 실습 환경 안내

PHP 긴급 보안 대응 실습 강의의 실습 서버입니다. Docker로 "패치 전 PHP가 돌고 있는 작은 운영 서버"를 내 컴퓨터에 만듭니다.

> **주의**: 이 서버에는 PHP2Shell(CVE-2026-109618·109619) 패치 전 PHP가 들어 있습니다. 포트는 내 컴퓨터(127.0.0.1)에서만 열리게 묶여 있습니다. 설정을 바꿔 외부에 공개하거나 회사 서버에 그대로 올리지 마세요.

## 준비물

- Docker Desktop (Windows·macOS) 또는 Docker Engine + Compose v2 (Linux)
- 디스크 여유 2GB, 메모리 여유 2GB
- 인터넷 연결 (처음 빌드, 실습 중 `apt update`)

Apple Silicon(M1~M4) Mac과 Intel/AMD PC 모두 같은 명령으로 동작합니다.

## 시작하기

```sh
cd 실습환경
docker compose up -d --build        # 처음에는 3~5분 걸립니다
docker compose exec server bash     # 서버 안으로 들어가기 (SSH 접속과 같은 역할)
```

브라우저에서 http://localhost:8080 을 열면 샘플 서비스(사내 공지 게시판)가 보입니다.
로그인: `admin` / `lab-password-1234` (교육용 계정)

## 처음 상태로 되돌리기

실습 중에 업데이트하거나 설정을 바꾼 내용은 컨테이너를 지우면 사라집니다. 몇 번이고 처음부터 다시 해 볼 수 있습니다.

```sh
docker compose down
docker compose up -d
```

샘플 서비스의 글과 첨부 파일(`app/storage/`)은 내 컴퓨터 폴더에 남습니다. 완전히 비우려면 `docker compose down` 뒤 `app/storage/uploads/` 안의 파일을 지우세요. DB는 컨테이너 안(`/var/lib/lab`)에 있어서 down과 함께 초기화됩니다.

## 서버의 처음 상태 (일부러 만든 상태)

| 항목 | 상태 | 강의 |
|---|---|---|
| 웹 요청을 처리하는 PHP | Ubuntu `php8.3-fpm 8.3.6-0maysync1` (24.04 출시 당시 버전, **패치 전**) | 2-2, 2-3 |
| 명령줄 `php` | ondrej PPA `php8.4-cli 8.4.27` (**패치 후**) → `php -v`만 보면 안전해 보임 | 1-1, 2-2 |
| 웹 서버 | Nginx → `unix:/run/php/php8.3-fpm.sock` | 2-2 |
| 샘플 서비스 | 로그인 · 세션 · 첨부 업로드/다운로드 · SQLite · XML 가져오기 · CLI 배치 | 4-4 |
| 서비스 재시작 | `service php8.3-fpm restart` (실제 서버의 `systemctl restart php8.3-fpm`과 같은 역할) | 4-2 |
| 자동 재시작 | 패키지를 업데이트해도 PHP-FPM이 자동으로 다시 시작되지 않음 | 4-2 |

실제 Ubuntu 서버에서는 패키지 업데이트 때 PHP-FPM이 자동으로 재시작되는 경우가 많습니다. 하지만 설정이나 환경에 따라 다르므로, 강의에서는 "자동으로 됐겠지"가 아니라 직접 확인하는 방법을 배웁니다.

## 폴더 구성

```text
실습환경/
├── docker-compose.yml
├── server/          실습 서버 이미지 (Ubuntu 24.04 + Nginx + PHP-FPM)
├── app/             샘플 서비스 소스 (서버의 /var/www/app)
├── tools/           점검 스크립트 (서버의 /opt/lab/tools)
├── mitigation/      임시 완화 설정 (서버의 /opt/lab/mitigation)
├── training-data/   침해 징후 찾기용 교육 데이터 (서버의 /opt/lab/training-data)
└── image-lab/       4-3 Docker 이미지 실습
```

## 점검 스크립트

모두 서버 안에서 실행합니다. 아무것도 바꾸지 않고 읽기만 합니다. 실제 Ubuntu/Debian 서버에서도 그대로 쓸 수 있습니다(경로·서비스 이름은 환경에 맞게 확인).

| 스크립트 | 하는 일 | 강의 |
|---|---|---|
| `runtime-check.sh` | 명령줄 PHP와 웹 요청 PHP 비교 | 2-2 |
| `package-check.sh` | 패키지 changelog·원본 버전으로 수정 여부 판정 | 2-3 |
| `triage.sh [경로]` | 침해 의심 징후 1차 점검 | 3-1 |
| `timeline.sh <경로>` | 로그·파일 변경 기록을 시간순 한 장으로 합침 (교육용 데이터용) | 5-1 |
| `restart-check.sh` | 업데이트한 코드가 실제로 돌고 있는지 확인 | 4-2 |
| `smoke-test.sh` | 패치 후 주요 기능 점검 | 4-4 |

## 4-3 Docker 이미지 실습

```sh
docker compose --profile image up -d --build image-app
curl http://localhost:8081/
```

`image-lab/Dockerfile`의 `FROM` 줄을 바꿔 가며 실습합니다. 끝나면 `FROM php:8.3.35-apache`로 되돌려 두세요.

## 문제 해결

| 증상 | 확인할 것 |
|---|---|
| `project name must not be empty` | Compose v2.x 최신 버전인지 확인. `docker-compose.yml`의 `name: php-lab` 줄이 지워지지 않았는지 확인 |
| 8080 포트 사용 중 | `docker-compose.yml`의 `127.0.0.1:8080:80`을 `127.0.0.1:18080:80` 등으로 변경 |
| `apt update`가 실패함 | 인터넷 연결과 회사 프록시 확인. 프록시가 있으면 컨테이너 안에서 `export http_proxy=...` |
| 502 Bad Gateway | PHP-FPM이 꺼짐. `service php8.3-fpm status`, `tail /var/log/php8.3-fpm.log` |
| 빌드가 `8.3.6-0maysync1`을 못 찾음 | Ubuntu 저장소 상황이 바뀌었을 수 있습니다. 강의 Q&A에 알려 주세요 |

## 검증 기록

- 2026-11-08, macOS(Apple Silicon) + Docker Desktop 29.8.0 (linux/arm64)에서 빌드부터 업데이트·재시작·스모크 테스트까지 전체 흐름을 실행해 확인했습니다.
- Windows(WSL2)와 Intel/AMD(linux/amd64) 환경은 아직 검증하지 않았습니다.
