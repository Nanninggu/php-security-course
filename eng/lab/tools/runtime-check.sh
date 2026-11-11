#!/bin/bash
# [2-2] Check whether the command line PHP and the PHP that handles web requests are the same.
# Usage: sudo bash runtime-check.sh   (lab server: /opt/lab/tools/runtime-check.sh)
# To change the web runtime check URL: RUNTIME_URL=http://127.0.0.1/lab/runtime.php

RUNTIME_URL=${RUNTIME_URL:-http://127.0.0.1/lab/runtime.php}

echo "== 1. The PHP that runs when you type 'php' on the command line"
if command -v php >/dev/null; then
  echo "Path: $(command -v php) → $(readlink -f "$(command -v php)")"
  php -r 'echo "Version: ", PHP_VERSION, " (", PHP_SAPI, ")\n";'
else
  echo "There is no php command."
fi

echo
echo "== 2. PHP executables installed on this server"
ls -1 /usr/bin/php[0-9]* /usr/sbin/php-fpm* /usr/local/bin/php* /usr/local/sbin/php-fpm* /opt/*/bin/php 2>/dev/null

echo
echo "== 3. PHP processes running now (FPM · Apache · CGI)"
ps -eo pid,user,lstart,args | awk 'NR==1 || /php-fpm|php-cgi|apache2|httpd|frankenphp|lsphp/' | grep -v awk

echo
echo "== 4. Where the web server hands PHP requests"
grep -RhoE 'fastcgi_pass[^;]+|proxy_pass[^;]+' /etc/nginx/sites-enabled/ /etc/nginx/conf.d/ 2>/dev/null | sort -u
ls /etc/apache2/mods-enabled/ 2>/dev/null | grep -E '^php|proxy_fcgi' | sed 's/^/apache module: /'

echo
echo "== 5. The PHP that actually handles web requests"
if out=$(curl -fsS "$RUNTIME_URL" 2>/dev/null); then
  echo "$out" | head -4
else
  echo "Could not open the runtime check page ($RUNTIME_URL)."
fi

echo
echo "* Items 1 and 5 can show different versions. The verdict is based on item 5 (the PHP that handles web requests)."
echo "* A distribution package may be patched even if the version number is unchanged -> package-check.sh"
