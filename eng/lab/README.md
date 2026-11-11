# Lab Environment Guide

This is the lab server for the PHP emergency security response course. Using Docker, it builds "a small production server running an unpatched PHP" on your own computer.

> **Warning**: This server contains a PHP from before the PHP2Shell (CVE-2026-109618 and 109619) patch. The port is bound so that it opens only on your own computer (127.0.0.1). Do not change the settings to expose it to the outside, and do not put it as is on a company server.

## What you need

- Docker Desktop (Windows, macOS) or Docker Engine + Compose v2 (Linux)
- 2GB of free disk space and 2GB of free memory
- An internet connection (for the first build, and for `apt update` during the labs)

Apple Silicon (M1 to M4) Macs and Intel/AMD PCs both work with the same commands.

## Getting started

```sh
cd lab
docker compose up -d --build        # the first time takes 3 to 5 minutes
docker compose exec server bash     # get inside the server (does the same job as an SSH login)
```

Open http://localhost:8090 in a browser and you will see the sample service (an internal notice board).
Sign in: `admin` / `lab-password-1234` (a training account)

## Returning to the starting state

Whatever you updated or changed in the settings during the labs disappears when you remove the container. You can start over from the beginning as many times as you like.

```sh
docker compose down
docker compose up -d
```

The sample service's posts and attachments (`app/storage/`) remain in a folder on your computer. To clear them completely, delete the files in `app/storage/uploads/` after `docker compose down`. The database is inside the container (`/var/lib/lab`), so it is reset along with `down`.

## The server's starting state (made that way on purpose)

| Item | State | Lesson |
|---|---|---|
| The PHP that handles web requests | Ubuntu `php8.3-fpm 8.3.6-0maysync1` (the version at the time of the 24.04 release, **before the patch**) | 2-2, 2-3 |
| The command-line `php` | ondrej PPA `php8.4-cli 8.4.27` (**after the patch**) → it looks safe if you look only at `php -v` | 1-1, 2-2 |
| Web server | Nginx → `unix:/run/php/php8.3-fpm.sock` | 2-2 |
| Sample service | Login · session · attachment upload/download · SQLite · XML import · CLI batch job | 4-4 |
| Restarting the service | `service php8.3-fpm restart` (does the same job as `systemctl restart php8.3-fpm` on a real server) | 4-2 |
| Automatic restart | PHP-FPM is not restarted automatically even when the packages are updated | 4-2 |

On a real Ubuntu server, PHP-FPM is often restarted automatically when packages are updated. But it depends on the settings and environment, so the course teaches you how to check it yourself instead of assuming "it must have happened automatically."

## Folder layout

```text
lab/
├── docker-compose.yml
├── server/          the lab server image (Ubuntu 24.04 + Nginx + PHP-FPM)
├── app/             the sample service source (the server's /var/www/app)
├── tools/           check scripts (the server's /opt/lab/tools)
├── mitigation/      temporary mitigation settings (the server's /opt/lab/mitigation)
├── training-data/   training data for finding signs of compromise (the server's /opt/lab/training-data)
└── image-lab/       the 4-3 Docker image lab
```

## Check scripts

You run all of them inside the server. They change nothing and only read. You can use them as they are on a real Ubuntu or Debian server too (check the paths and service names for your environment).

| Script | What it does | Lesson |
|---|---|---|
| `runtime-check.sh` | Compares the command-line PHP and the web-request PHP | 2-2 |
| `package-check.sh` | Judges whether the fix is present from the package changelog or upstream version | 2-3 |
| `triage.sh [path]` | A first-pass check for signs of compromise | 3-1 |
| `timeline.sh <path>` | Merges log and file change records into one time-ordered table (for the training data) | 5-1 |
| `restart-check.sh` | Checks whether the updated code is really running | 4-2 |
| `smoke-test.sh` | Checks the main features after patching | 4-4 |

## 4-3 Docker image lab

```sh
docker compose --profile image up -d --build image-app
curl http://localhost:8091/
```

You do the lab by changing the `FROM` line in `image-lab/Dockerfile`. When you are done, put it back to `FROM php:8.3.35-apache`.

## Troubleshooting

| Symptom | What to check |
|---|---|
| `project name must not be empty` | Make sure you have a recent Compose v2.x. Make sure the `name: php-lab-en` line in `docker-compose.yml` has not been deleted |
| Port 8090 is in use | Change `127.0.0.1:8090:80` in `docker-compose.yml` to something like `127.0.0.1:18090:80` |
| `apt update` fails | Check your internet connection and any company proxy. If there is a proxy, run `export http_proxy=...` inside the container |
| 502 Bad Gateway | PHP-FPM is off. `service php8.3-fpm status`, `tail /var/log/php8.3-fpm.log` |
| The build cannot find `8.3.6-0maysync1` | The state of the Ubuntu repository may have changed. Please tell us in the course Q&A |

## Verification record

- On 2026-11-08, I ran and confirmed the whole flow, from the build through the update, the restart and the smoke test, on macOS (Apple Silicon) + Docker Desktop 29.8.0 (linux/arm64).
- Windows (WSL2) and Intel/AMD (linux/amd64) environments have not been verified yet.
