#!/bin/bash
# [2-2] 명령줄 PHP와 웹 요청 PHP가 같은지 확인한다.
# 사용: sudo bash runtime-check.sh   (실습 서버: /opt/lab/tools/runtime-check.sh)
# 웹 런타임 확인 주소를 바꾸려면: RUNTIME_URL=http://127.0.0.1/lab/runtime.php

RUNTIME_URL=${RUNTIME_URL:-http://127.0.0.1/lab/runtime.php}

echo "== 1. 명령줄에서 'php'를 입력하면 실행되는 PHP"
if command -v php >/dev/null; then
  echo "경로: $(command -v php) → $(readlink -f "$(command -v php)")"
  php -r 'echo "버전: ", PHP_VERSION, " (", PHP_SAPI, ")\n";'
else
  echo "php 명령이 없습니다."
fi

echo
echo "== 2. 이 서버에 설치된 PHP 실행 파일"
ls -1 /usr/bin/php[0-9]* /usr/sbin/php-fpm* /usr/local/bin/php* /usr/local/sbin/php-fpm* /opt/*/bin/php 2>/dev/null

echo
echo "== 3. 지금 실행 중인 PHP 프로세스 (FPM · Apache · CGI)"
ps -eo pid,user,lstart,args | awk 'NR==1 || /php-fpm|php-cgi|apache2|httpd|frankenphp|lsphp/' | grep -v awk

echo
echo "== 4. 웹 서버가 PHP 요청을 넘기는 곳"
grep -RhoE 'fastcgi_pass[^;]+|proxy_pass[^;]+' /etc/nginx/sites-enabled/ /etc/nginx/conf.d/ 2>/dev/null | sort -u
ls /etc/apache2/mods-enabled/ 2>/dev/null | grep -E '^php|proxy_fcgi' | sed 's/^/apache 모듈: /'

echo
echo "== 5. 웹 요청을 실제로 처리하는 PHP"
if out=$(curl -fsS "$RUNTIME_URL" 2>/dev/null); then
  echo "$out" | head -4
else
  echo "런타임 확인 페이지($RUNTIME_URL)를 열지 못했습니다."
fi

echo
echo "※ 1번과 5번의 버전이 다를 수 있습니다. 판정은 5번(웹 요청을 처리하는 PHP)을 기준으로 합니다."
echo "※ 배포판 패키지는 버전 숫자가 그대로여도 패치됐을 수 있습니다 → package-check.sh"
