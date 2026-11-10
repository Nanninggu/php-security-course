#!/bin/bash
# [4-2] 업데이트한 PHP가 "실제로" 돌고 있는지 확인한다.
# 패키지를 업데이트해도 이미 떠 있는 프로세스는 메모리에 옛 코드를 그대로 들고 있다.
# 사용: sudo bash restart-check.sh   (root로 실행해야 다른 사용자의 프로세스까지 볼 수 있다)

echo "== 1. PHP 패키지가 마지막으로 바뀐 시각 (/var/log/dpkg.log)"
last=$(grep -hE ' (upgrade|install) php[0-9.]+-(fpm|common|cgi)|libapache2-mod-php' /var/log/dpkg.log 2>/dev/null | tail -1)
echo "  ${last:-기록 없음}"

echo
echo "== 2. 실행 중인 PHP 프로세스와 시작 시각"
echo "  PID     사용자    시작 시각                  실행 파일"
for pid in $(pgrep -f 'php-fpm|php-cgi|apache2|httpd|frankenphp|lsphp'); do
  [ -d /proc/$pid ] || continue
  exe=$(readlink /proc/$pid/exe 2>/dev/null); exe=${exe:-"(권한 없음 · 마스터 기준으로 판단)"}
  printf "  %-7s %-9s %-26s %s\n" "$pid" "$(ps -o user= -p $pid)" "$(ps -o lstart= -p $pid)" "$exe"
done

echo
echo "== 3. 지워진 옛 실행 파일·라이브러리를 아직 쓰는 프로세스"
found=0
for maps in /proc/[0-9]*/maps; do
  pid=${maps#/proc/}; pid=${pid%/maps}
  hits=$(grep -oE '/[^ ]*(\.so[^ ]*|php-fpm[0-9.]*|php-cgi[0-9.]*|apache2|httpd) \(deleted\)' "$maps" 2>/dev/null | sort -u)
  [ -n "$hits" ] || continue
  found=1
  echo "  PID $pid ($(ps -o comm= -p $pid)): $(echo "$hits" | head -3 | sed 's/ (deleted)//' | tr '\n' ' ')$( [ $(echo "$hits" | wc -l) -gt 3 ] && echo '...')"
done
if [ $found = 0 ]; then
  echo "  없음"
  echo
  echo "결과: 실행 중인 PHP 프로세스가 지금 설치된 파일을 쓰고 있습니다."
else
  echo
  echo "결과: 재시작이 필요합니다. 예) systemctl restart php8.3-fpm   (실습 서버: service php8.3-fpm restart)"
fi
echo "※ 웹 응답의 PHP_VERSION(예: 8.3.6)은 배포판 패키지에서 패치 전후가 같으므로, 이 확인을 대신하지 못합니다."
