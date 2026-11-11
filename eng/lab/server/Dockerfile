# 실습용 "운영 서버" 이미지 (교육용, 외부 공개 금지)
#
# 일부러 만든 상태:
#   - 웹 요청 처리: Ubuntu 24.04 출시 당시의 php8.3-fpm 8.3.6-0maysync1 (PHP2Shell 패치 전)
#   - 명령줄 php: ondrej PPA에서 설치한 php8.4-cli 8.4.27 (패치 후 버전)
#     → `php -v`만 보면 안전해 보이지만 웹 요청은 패치 전 PHP가 처리한다.
#   - 예전에 PPA를 썼던 서버처럼, 설치 후 PPA 저장소 설정은 지워 둔다.
#
# 이 컨테이너는 VM처럼 쓴다. 강의에서 apt 업데이트와 서비스 재시작을 이 안에서 직접 해 본다.
# 처음 상태로 되돌리려면: docker compose down && docker compose up -d
FROM ubuntu:24.04

ARG OLD_PHP=8.3.6-0maysync1
ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Seoul LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl tzdata procps lsof less nano sqlite3 nginx \
      software-properties-common gpg-agent \
 && apt-get install -y --no-install-recommends \
      php8.3-fpm=${OLD_PHP} php8.3-cli=${OLD_PHP} php8.3-common=${OLD_PHP} \
      php8.3-opcache=${OLD_PHP} php8.3-readline=${OLD_PHP} \
      php8.3-sqlite3=${OLD_PHP} php8.3-xml=${OLD_PHP} php8.3-mbstring=${OLD_PHP} \
 && add-apt-repository -y ppa:ondrej/php \
 && apt-get install -y --no-install-recommends php8.4-cli php8.4-sqlite3 php8.4-xml \
 && update-alternatives --set php /usr/bin/php8.4 \
 && rm -f /etc/apt/sources.list.d/ondrej-*.list /etc/apt/sources.list.d/ondrej-*.sources \
 && apt-get update \
 && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && echo Asia/Seoul > /etc/timezone \
 && printf 'date.timezone = Asia/Seoul\n' > /etc/php/8.3/mods-available/lab-timezone.ini \
 && phpenmod -v 8.3 lab-timezone \
 && printf 'date.timezone = Asia/Seoul\n' > /etc/php/8.4/mods-available/lab-timezone.ini \
 && phpenmod -v 8.4 lab-timezone

COPY nginx-site.conf /etc/nginx/sites-available/default
COPY entrypoint.sh /usr/local/sbin/lab-entrypoint
RUN chmod +x /usr/local/sbin/lab-entrypoint \
 && mkdir -p /var/lib/lab /var/www/app/storage/uploads \
 && chown -R www-data:www-data /var/lib/lab

EXPOSE 80
ENTRYPOINT ["/usr/local/sbin/lab-entrypoint"]
