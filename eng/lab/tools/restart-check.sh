#!/bin/bash
# [4-2] Check that the updated PHP is "really" running.
# Updating a package does not change processes that are already running: they keep the old code in memory.
# Usage: sudo bash restart-check.sh   (run as root so you can see other users' processes too)

echo "== 1. When the PHP packages last changed (/var/log/dpkg.log)"
last=$(grep -hE ' (upgrade|install) php[0-9.]+-(fpm|common|cgi)|libapache2-mod-php' /var/log/dpkg.log 2>/dev/null | tail -1)
echo "  ${last:-no record}"

echo
echo "== 2. Running PHP processes and their start times"
echo "  PID     USER      START TIME                 EXECUTABLE"
for pid in $(pgrep -f 'php-fpm|php-cgi|apache2|httpd|frankenphp|lsphp'); do
  [ -d /proc/$pid ] || continue
  exe=$(readlink /proc/$pid/exe 2>/dev/null); exe=${exe:-"(no permission; judge by the master process)"}
  printf "  %-7s %-9s %-26s %s\n" "$pid" "$(ps -o user= -p $pid)" "$(ps -o lstart= -p $pid)" "$exe"
done

echo
echo "== 3. Processes still using old executables or libraries that were deleted"
found=0
for maps in /proc/[0-9]*/maps; do
  pid=${maps#/proc/}; pid=${pid%/maps}
  hits=$(grep -oE '/[^ ]*(\.so[^ ]*|php-fpm[0-9.]*|php-cgi[0-9.]*|apache2|httpd) \(deleted\)' "$maps" 2>/dev/null | sort -u)
  [ -n "$hits" ] || continue
  found=1
  echo "  PID $pid ($(ps -o comm= -p $pid)): $(echo "$hits" | head -3 | sed 's/ (deleted)//' | tr '\n' ' ')$( [ $(echo "$hits" | wc -l) -gt 3 ] && echo '...')"
done
if [ $found = 0 ]; then
  echo "  none"
  echo
  echo "Result: the running PHP processes are using the files that are installed now."
else
  echo
  echo "Result: a restart is needed. e.g. systemctl restart php8.3-fpm   (lab server: service php8.3-fpm restart)"
fi
echo "* The PHP_VERSION in the web response (e.g. 8.3.6) is the same before and after a distribution patch, so it cannot replace this check."
