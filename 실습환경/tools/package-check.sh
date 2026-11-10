#!/bin/bash
# [2-3] 설치된 PHP 패키지에 PHP2Shell 수정이 들어 있는지 근거와 함께 확인한다. (Debian/Ubuntu)
# 사용: bash package-check.sh
#
# 판정 기준 (2026-11-08 확인)
#  - 배포판 패키지(Ubuntu, Debian): 패키지 changelog에 CVE 번호가 있으면 수정됨. 버전 숫자는 8.3.6처럼 그대로일 수 있다.
#  - 원본 버전을 그대로 쓰는 패키지(ondrej PPA, 공식 Docker 이미지, 직접 빌드): 8.2.35 / 8.3.36 / 8.4.27 / 8.5.12 이상이면 수정됨.

CVES="CVE-2026-109618 CVE-2026-109619"
declare -A FIXED=([8.2]=35 [8.3]=36 [8.4]=27 [8.5]=12)

echo "== 설치된 PHP 패키지"
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
    echo "  출처: 원본 버전을 쓰는 패키지 (PPA 등) → 원본 버전 $upstream 기준으로 판단"
    if [ -n "$need" ] && [ "$patch" -ge "$need" ]; then
      echo "  판정: 수정됨 (필요 버전 $branch.$need 이상)"
    elif [ -n "$need" ]; then
      echo "  판정: 취약 (필요 버전 $branch.$need 이상, 지금 $upstream)"
    else
      echo "  판정: 공식 지원이 끝난 브랜치 → 배포판·LTS 벤더 공지를 직접 확인"
    fi
  elif [ -f "$log" ]; then
    echo "  출처: 배포판 패키지 → changelog에서 CVE 번호를 찾음"
    missing=0
    for cve in $CVES; do
      if zgrep -q "$cve" "$log"; then echo "  $cve: changelog에 있음"; else echo "  $cve: changelog에 없음"; missing=1; fi
    done
    [ $missing = 0 ] && echo "  판정: 수정됨" || echo "  판정: 취약 (보안 업데이트 필요)"
  else
    echo "  changelog 파일이 없습니다. apt changelog $common 으로 온라인 확인하세요."
  fi
  echo
done

echo "※ 패키지가 수정됐어도, 실행 중인 프로세스를 다시 시작하기 전까지는 옛 코드가 돈다 → restart-check.sh"
