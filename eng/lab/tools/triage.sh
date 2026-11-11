#!/bin/bash
# [3-1] Quickly scan for signs of compromise before patching or restarting. (a first-pass check, not a forensic tool)
#
# Usage:
#   sudo bash triage.sh                         check this server now
#   bash triage.sh /opt/lab/training-data       check the training data (exercise)
#
# This script changes nothing. If the result shows signs, decide about preserving
# evidence before restarting or patching (lessons 3-1, 5-2).
# No signs does not mean no compromise. Logs may be erased or never written.

ROOT=${1:-/}; ROOT=${ROOT%/}
WEBROOT=${WEBROOT:-/var/www}
WEBUSER=${WEBUSER:-www-data}
ACCESS="$ROOT/var/log/nginx/access.log"
ERROR="$ROOT/var/log/nginx/error.log"
FPMLOG=$(ls "$ROOT"/var/log/php*-fpm.log 2>/dev/null | head -1)
warn=0
flag() { echo "  ⚠ $1"; warn=$((warn+1)); }

echo "Target: ${ROOT:-/}"
echo

echo "== 1. Abnormal PHP worker exits (often seen in memory-corruption attempts)"
if [ -f "$FPMLOG" ]; then
  n=$(grep -cE 'exited on signal (11|6|7)' "$FPMLOG")
  if [ "$n" -gt 0 ]; then
    flag "${n} abnormal exits ($FPMLOG)"
    grep -E 'exited on signal' "$FPMLOG" | grep -oE '^\[[0-9]{2}-[A-Za-z]{3}-[0-9]{4} [0-9]{2}' | sort | uniq -c | sed 's/^/    /; s/\[//; s/$/h/'
  else
    echo "  none"
  fi
else
  echo "  No FPM log."
fi

echo
echo "== 2. Connection drops between the web server and PHP"
if [ -f "$ERROR" ]; then
  n=$(grep -cE 'upstream prematurely closed|Connection reset by peer\) while reading response header from upstream' "$ERROR")
  [ "$n" -gt 0 ] && flag "${n} dropped connections ($ERROR)" || echo "  none"
fi

if [ -f "$ACCESS" ]; then
  echo
  echo "== 3. IPs with many 502 and 500 responses (top 5)"
  awk '$9 ~ /^50[02]$/ {print $1}' "$ACCESS" | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /'

  echo
  echo "== 4. POST requests from programs, not people (by User-Agent)"
  awk -F'"' '$2 ~ /^POST/ && $6 ~ /python-requests|curl|Go-http-client|wget|libwww|zgrab|masscan/ {split($1,a," "); print a[1], $6}' "$ACCESS" \
    | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /'

  echo
  echo "== 5. Requests aimed at version information"
  grep -E '"GET /(phpinfo|info|test|php_info)\.php|"GET /\.env' "$ACCESS" | awk '{print "    "$1, $7, $9}' | head -8

  echo
  echo "== 6. Requests to PHP files the service never had"
  known='^/(index|login|logout|board|post|download|import)\.php$|^/lab/'
  unknown=$(awk '{split($7,u,"?"); if (u[1] ~ /\.php$/) print u[1], $9}' "$ACCESS" | awk -v k="$known" '$1 !~ k && $2 == 200' | sort | uniq -c)
  if [ -n "$unknown" ]; then flag "A PHP file not on the list answered 200"; echo "$unknown" | sed 's/^/    /'; else echo "  none"; fi
fi

echo
echo "== 7. PHP files where there should be none (upload and image folders)"
hits=$(find "$ROOT$WEBROOT" -type f -name '*.php*' \( -path '*/uploads/*' -o -path '*/storage/*' -o -path '*/img/*' -o -path '*/images/*' -o -path '*/cache/*' -o -path '*/tmp/*' \) 2>/dev/null)
if [ -n "$hits" ]; then flag "Suspicious file"; echo "$hits" | sed "s|^$ROOT|    |"; else echo "  none"; fi

echo
echo "== 8. PHP files changed in the last 14 days (compare with deploy records)"
find "$ROOT$WEBROOT" -type f -name '*.php' -mtime -14 2>/dev/null | head -20 | sed "s|^$ROOT|    |"

echo
echo "== 9. Scheduled jobs of the web server account ($WEBUSER)"
cron="$ROOT/var/spool/cron/crontabs/$WEBUSER"
if [ -f "$cron" ] && grep -vqE '^\s*(#|$)' "$cron"; then
  flag "The web server account has a crontab"
  grep -vE '^\s*(#|$)' "$cron" | sed 's/^/    /'
else
  echo "  none"
fi

if [ "$ROOT" = "" ]; then
  echo
  echo "== 10. Processes other than PHP running as the web server account"
  others=$(ps -u "$WEBUSER" -o pid=,args= 2>/dev/null | grep -vE 'php-fpm|nginx: worker|apache2|httpd')
  if [ -n "$others" ]; then flag "Processes besides PHP and the web server"; echo "$others" | sed 's/^/    /'; else echo "  none"; fi
fi

echo
echo "────────────────────────────────────────"
if [ $warn -gt 0 ]; then
  echo "Result: ${warn} signs of concern. Before restarting or patching, decide about preserving evidence (memory, logs, file copies)."
  echo "        Do not confirm or rule out a compromise from this result alone."
else
  echo "Result: this check found no signs. That does not mean there was no compromise."
fi
