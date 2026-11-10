#!/bin/bash
# [3-1] 패치·재시작 전에 침해 의심 징후를 빠르게 훑어본다. (1차 점검용, 정밀 분석 도구가 아님)
#
# 사용:
#   sudo bash triage.sh                         지금 서버를 점검
#   bash triage.sh /opt/lab/training-data       교육용 데이터를 점검 (실습)
#
# 이 스크립트는 아무것도 바꾸지 않는다. 결과에 징후가 있으면 재시작·패치 전에
# 증거 보존 여부를 먼저 판단한다 (강의 3-1, 5-2).
# 징후가 없다고 해서 침해되지 않았다는 뜻은 아니다. 로그는 지워지거나 남지 않을 수 있다.

ROOT=${1:-/}; ROOT=${ROOT%/}
WEBROOT=${WEBROOT:-/var/www}
WEBUSER=${WEBUSER:-www-data}
ACCESS="$ROOT/var/log/nginx/access.log"
ERROR="$ROOT/var/log/nginx/error.log"
FPMLOG=$(ls "$ROOT"/var/log/php*-fpm.log 2>/dev/null | head -1)
warn=0
flag() { echo "  ⚠ $1"; warn=$((warn+1)); }

echo "점검 대상: ${ROOT:-/}"
echo

echo "== 1. PHP 워커 비정상 종료 (메모리 손상 공격 시도에서 흔히 보임)"
if [ -f "$FPMLOG" ]; then
  n=$(grep -cE 'exited on signal (11|6|7)' "$FPMLOG")
  if [ "$n" -gt 0 ]; then
    flag "비정상 종료 ${n}건 ($FPMLOG)"
    grep -E 'exited on signal' "$FPMLOG" | grep -oE '^\[[0-9]{2}-[A-Za-z]{3}-[0-9]{4} [0-9]{2}' | sort | uniq -c | sed 's/^/    /; s/\[//; s/$/시대/'
  else
    echo "  없음"
  fi
else
  echo "  FPM 로그가 없습니다."
fi

echo
echo "== 2. 웹 서버와 PHP 사이의 연결 끊김"
if [ -f "$ERROR" ]; then
  n=$(grep -cE 'upstream prematurely closed|Connection reset by peer\) while reading response header from upstream' "$ERROR")
  [ "$n" -gt 0 ] && flag "연결 끊김 ${n}건 ($ERROR)" || echo "  없음"
fi

if [ -f "$ACCESS" ]; then
  echo
  echo "== 3. 502·500 응답이 많은 IP (상위 5개)"
  awk '$9 ~ /^50[02]$/ {print $1}' "$ACCESS" | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /'

  echo
  echo "== 4. 사람이 아닌 프로그램의 POST 요청 (User-Agent 기준)"
  awk -F'"' '$2 ~ /^POST/ && $6 ~ /python-requests|curl|Go-http-client|wget|libwww|zgrab|masscan/ {split($1,a," "); print a[1], $6}' "$ACCESS" \
    | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /'

  echo
  echo "== 5. 버전 정보를 노리는 요청"
  grep -E '"GET /(phpinfo|info|test|php_info)\.php|"GET /\.env' "$ACCESS" | awk '{print "    "$1, $7, $9}' | head -8

  echo
  echo "== 6. 서비스에 원래 없는 PHP 파일로 들어온 요청"
  known='^/(index|login|logout|board|post|download|import)\.php$|^/lab/'
  unknown=$(awk '{split($7,u,"?"); if (u[1] ~ /\.php$/) print u[1], $9}' "$ACCESS" | awk -v k="$known" '$1 !~ k && $2 == 200' | sort | uniq -c)
  if [ -n "$unknown" ]; then flag "목록에 없는 PHP 파일이 200으로 응답함"; echo "$unknown" | sed 's/^/    /'; else echo "  없음"; fi
fi

echo
echo "== 7. 있으면 안 되는 곳의 PHP 파일 (업로드·이미지 폴더)"
hits=$(find "$ROOT$WEBROOT" -type f -name '*.php*' \( -path '*/uploads/*' -o -path '*/storage/*' -o -path '*/img/*' -o -path '*/images/*' -o -path '*/cache/*' -o -path '*/tmp/*' \) 2>/dev/null)
if [ -n "$hits" ]; then flag "의심 파일"; echo "$hits" | sed "s|^$ROOT|    |"; else echo "  없음"; fi

echo
echo "== 8. 최근 14일 안에 바뀐 PHP 파일 (배포 기록과 대조할 것)"
find "$ROOT$WEBROOT" -type f -name '*.php' -mtime -14 2>/dev/null | head -20 | sed "s|^$ROOT|    |"

echo
echo "== 9. 웹 서버 계정($WEBUSER)의 예약 작업"
cron="$ROOT/var/spool/cron/crontabs/$WEBUSER"
if [ -f "$cron" ] && grep -vqE '^\s*(#|$)' "$cron"; then
  flag "웹 서버 계정에 crontab이 있음"
  grep -vE '^\s*(#|$)' "$cron" | sed 's/^/    /'
else
  echo "  없음"
fi

if [ "$ROOT" = "" ]; then
  echo
  echo "== 10. 웹 서버 계정으로 실행 중인 PHP 이외의 프로세스"
  others=$(ps -u "$WEBUSER" -o pid=,args= 2>/dev/null | grep -vE 'php-fpm|nginx: worker|apache2|httpd')
  if [ -n "$others" ]; then flag "PHP·웹 서버 외 프로세스"; echo "$others" | sed 's/^/    /'; else echo "  없음"; fi
fi

echo
echo "────────────────────────────────────────"
if [ $warn -gt 0 ]; then
  echo "결과: 의심 징후 ${warn}개. 재시작·패치 전에 증거 보존을 판단하세요 (메모리·로그·파일 사본)."
  echo "      이 결과만으로 침해를 확정하거나 부정하지 마세요."
else
  echo "결과: 이 점검에서 걸린 징후는 없습니다. 침해되지 않았다는 뜻은 아닙니다."
fi
