#!/bin/bash
# [5-1] 흩어진 기록(접근 로그·오류 로그·FPM 로그·파일 변경 기록)을 시간순 한 줄 표로 합친다. (1차 정리용, 정밀 분석 도구가 아님)
#
# 사용:
#   bash timeline.sh /opt/lab/training-data      교육용 데이터를 시간순으로 합친다
#
# 같은 종류의 기록이 한 시간 안에 여러 건이면 한 줄로 묶어 건수와 시각 범위를 적는다.
# 접근 로그는 브라우저(Mozilla)가 아닌 User-Agent의 요청만 본다. 이 표는 "같이 볼 후보"를 모아 줄 뿐
# 침해를 확정하지 않는다. 아무것도 바꾸지 않는다.

ROOT=${1:?'사용: timeline.sh <기록 폴더>'}; ROOT=${ROOT%/}
ACCESS="$ROOT/var/log/nginx/access.log"
ERROR="$ROOT/var/log/nginx/error.log"
FPMLOG=$(ls "$ROOT"/var/log/php*-fpm.log 2>/dev/null | head -1)
FILES="$ROOT/records/file-changes.txt"

MON='BEGIN{split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec",m," "); for(i=1;i<=12;i++) M[m[i]]=sprintf("%02d",i)}'

{
  # FPM 로그: [23-Oct-2026 03:15:27] WARNING: ... exited on signal 11
  [ -f "$FPMLOG" ] && awk "$MON"'
    /exited on signal/ { split($1,a,"-"); d=substr(a[1],2); mo=M[a[2]]; yr=a[3]; t=substr($2,1,8); h=substr(t,1,2)
      k=yr"-"mo"-"d" "h; if(!(k in n)){first[k]=t}; n[k]++; last[k]=t }
    /fpm is running/ { split($1,a,"-"); printf "%s-%s-%s %s\tFPM 로그\tFPM 시작\n", a[3], M[a[2]], substr(a[1],2), substr($2,1,5) }
    END{ for(k in n) printf "%s:%s\tFPM 로그\t워커 비정상 종료 %d건 (%s~%s)\n", k, substr(first[k],4,2), n[k], first[k], last[k] }' "$FPMLOG"

  # 오류 로그: 2026/10/23 03:15:27 [error] ... Connection reset by peer
  [ -f "$ERROR" ] && awk '
    /Connection reset by peer|prematurely closed/ { gsub("/","-",$1); h=substr($2,1,2); k=$1" "h; if(!(k in n)) first[k]=$2; n[k]++; last[k]=$2 }
    END{ for(k in n) printf "%s:%s\t엔진엑스 오류 로그\tPHP와 연결 끊김 %d건 (%s~%s)\n", k, substr(first[k],4,2), n[k], first[k], last[k] }' "$ERROR"

  # 접근 로그: 브라우저가 아닌 User-Agent만. 같은 주소·같은 시간대를 한 줄로 묶는다
  [ -f "$ACCESS" ] && awk "$MON"'
    { ua=$0; sub(/.*" "/,"",ua)
      if (ua ~ /^Mozilla/) next
      split($4,a,/[\/:\[]/); d=a[2]; mo=M[a[3]]; yr=a[4]; h=a[5]; mi=a[6]; ss=a[7]; t=h":"mi":"ss
      url=$7; sub(/\?.*/,"",url)
      k=$1" "yr"-"mo"-"d" "h
      if(!(k in n)){first[k]=t; order[++c]=k}; n[k]++; last[k]=t; st[k" "$9]++; sk[k]=sk[k]" "$9
      if(!((k" "url) in seen)){seen[k" "url]=1; np[k]++; path[k]=url} }
    END{ for(i=1;i<=c;i++){ k=order[i]; split(k,p," ")
        codes=""; split(sk[k],cs," "); for(j in cs){ if(!(cs[j] in done)){ done[cs[j]]=1 } }
        for(code in done){ if((k" "code) in st) codes=codes (codes==""?"":", ") code" "st[k" "code]"건" }
        delete done
        where = (np[k]==1) ? path[k] : np[k]"개 경로"
        printf "%s %s:%s\t접근 로그\t%s 요청 %d건 (%s, 응답 %s)\n", p[2], p[3], substr(first[k],4,2), p[1], n[k], where, codes } }' "$ACCESS"

  # 파일 변경 기록: 날짜 시각 소유자 경로. 같은 분·같은 소유자는 한 줄로 묶는다
  [ -f "$FILES" ] && grep -v '^#' "$FILES" | awk '
    { k=$1" "substr($2,1,5)" "$3; if(!(k in n)){order[++c]=k; ex[k]=$4}; n[k]++ }
    END{ for(i=1;i<=c;i++){ k=order[i]; split(k,p," "); who=p[3]
        if(n[k]>1) printf "%s %s\t파일 변경\t%s가 파일 %d개 변경 (%s 외)\n", p[1], p[2], who, n[k], ex[k]
        else printf "%s %s\t파일 변경\t%s가 변경: %s\n", p[1], p[2], who, ex[k] } }'
} | sort | awk -F'\t' '{ printf "%s  [%s] %s\n", $1, $2, $3 }'
echo
echo "────────────────────────────────────────"
echo "이 표는 같이 볼 후보를 시간순으로 모은 것입니다. 이것만으로 침해를 확정하거나 부정하지 마세요."
