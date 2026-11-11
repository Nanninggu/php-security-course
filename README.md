# PHP 보안 공지 대응 실습 저장소

인프런 강의 **"PHP 보안 공지, 내 서버는 영향받나? 판정부터 패치 확인까지"** 의 실습 파일입니다.

## 구성

| 경로 | 내용 |
|---|---|
| `실습환경/` | Docker로 띄우는 실습 서버(패치 전 PHP가 도는 작은 운영 서버), 점검·확인 스크립트, 임시 완화 설정, 교육용 데이터 |
| `학습자료/실습과제.md` | 실습 과제 10개 |
| `학습자료/실습과제_해설.md` | 실습 과제 해설 (직접 해 본 뒤 확인하세요) |

## 시작하기

```sh
git clone https://github.com/Nanninggu/php-security-course.git
cd php-security-course/실습환경
docker compose up -d --build
```

자세한 준비물과 사용법은 [`실습환경/README.md`](실습환경/README.md)를 보세요.

## 주의

- 실습 서버에는 일부러 **패치 전 PHP**가 들어 있습니다. 포트는 내 컴퓨터(127.0.0.1)에서만 열리도록 묶여 있으니, 설정을 바꿔 외부에 공개하거나 회사 서버에 그대로 올리지 마세요.
- `training-data/`의 로그와 기록은 교육용 가상 사례이며, IP는 문서 예시용 대역입니다.
- 정보 기준일: 2026-11-08. 버전 번호와 지원 일정은 사용 시점에 php.net과 사용하는 배포판 공지에서 다시 확인하세요.

---

## English edition

Lab files for the Udemy course **"PHP Security Alert: Is Your Server Really Patched?"**. Everything is under [`eng/`](eng/).

| Path | Content |
|---|---|
| `eng/lab/` | The Docker lab server (a small production server running an unpatched PHP), check scripts, temporary mitigation settings and training data, in English. Start here: [`eng/lab/README.md`](eng/lab/README.md) |
| `eng/exercises/exercises.md` | The 10 exercises |
| `eng/exercises/exercises_solutions.md` | The solutions (try the exercises yourself first) |
| `eng/exercises/6-3_report_template.md`, `6-3_example_report.md` | The final assignment report template and an example |

```sh
git clone https://github.com/Nanninggu/php-security-course.git
cd php-security-course/eng/lab
docker compose up -d --build
```

The English lab uses ports 8090 and 8091 and a separate Compose project, so it can run next to the Korean lab. The server contains an unpatched PHP on purpose; do not expose it to the internet. Information current as of 2026-11-08.
