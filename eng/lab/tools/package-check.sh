#!/bin/bash
# [2-3] Check, with evidence, whether the installed PHP packages contain the PHP2Shell fix. (Debian/Ubuntu)
# Usage: bash package-check.sh
#
# Verdict rules (checked 2026-11-08)
#  - Distribution packages (Ubuntu, Debian): if the package changelog lists the CVE numbers, it is fixed. The version number can stay 8.3.6.
#  - Packages that keep the upstream version (ondrej PPA, official Docker images, self-built): 8.2.35 / 8.3.36 / 8.4.27 / 8.5.12 or newer is fixed.

CVES="CVE-2026-109618 CVE-2026-109619"
declare -A FIXED=([8.2]=35 [8.3]=36 [8.4]=27 [8.5]=12)

echo "== Installed PHP packages"
dpkg-query -W -f='${Package}\t${Version}\t${db:Status-Abbrev}\n' 'php*' 2>/dev/null \
  | awk -F'\t' '$3 ~ /^ii/ {printf "  %-20s %s\n", $1, $2}'

echo
for common in $(dpkg-query -W -f='${Package}\n' 'php[0-9]*-common' 2>/dev/null); do
  [ "$(dpkg-query -W -f='${db:Status-Abbrev}' "$common")" = "ii " ] || continue
  branch=${common#php}; branch=${branch%-common}
  version=$(dpkg-query -W -f='${Version}' "$common")
  log=/usr/share/doc/$common/changelog.Debian.gz
  echo "== PHP $branch ($common $version)"

  if [[ $version == *deb.sury.org* || $version == *-1+* ]]; then
    upstream=${version%%-*}; patch=${upstream##*.}
    need=${FIXED[$branch]}
    echo "  Source: package that keeps the upstream version (PPA etc.) -> judged by upstream version $upstream"
    if [ -n "$need" ] && [ "$patch" -ge "$need" ]; then
      echo "  Verdict: FIXED (needs $branch.$need or newer)"
    elif [ -n "$need" ]; then
      echo "  Verdict: VULNERABLE (needs $branch.$need or newer, now $upstream)"
    else
      echo "  Verdict: branch is end-of-life -> check the distribution / LTS vendor advisory yourself"
    fi
  elif [ -f "$log" ]; then
    echo "  Source: distribution package -> looking for the CVE numbers in the changelog"
    missing=0
    for cve in $CVES; do
      if zgrep -q "$cve" "$log"; then echo "  $cve: in the changelog"; else echo "  $cve: not in the changelog"; missing=1; fi
    done
    [ $missing = 0 ] && echo "  Verdict: FIXED" || echo "  Verdict: VULNERABLE (security update needed)"
  else
    echo "  No changelog file. Check online with: apt changelog $common"
  fi
  echo
done

echo "* Even when the package is fixed, the old code keeps running until you restart the running processes -> restart-check.sh"
