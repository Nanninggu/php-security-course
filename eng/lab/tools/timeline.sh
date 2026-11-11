#!/bin/bash
# [5-1] Merge scattered records (access log, error log, FPM log, file-change record) into one time-ordered table. (First-pass tidy-up, not a precise analysis tool)
#
# Usage:
#   bash timeline.sh /opt/lab/training-data      merge the training data in time order
#
# If records of the same kind fall within one hour, they are grouped into one line with a count and a time range.
# For the access log, only requests whose User-Agent is not a browser (Mozilla) are looked at. This table only gathers "candidates to look at together"
# and does not confirm a compromise. It changes nothing.

ROOT=${1:?'Usage: timeline.sh <records folder>'}; ROOT=${ROOT%/}
ACCESS="$ROOT/var/log/nginx/access.log"
ERROR="$ROOT/var/log/nginx/error.log"
FPMLOG=$(ls "$ROOT"/var/log/php*-fpm.log 2>/dev/null | head -1)
FILES="$ROOT/records/file-changes.txt"

MON='BEGIN{split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec",m," "); for(i=1;i<=12;i++) M[m[i]]=sprintf("%02d",i)}'

{
  # FPM log: [23-Oct-2026 03:15:27] WARNING: ... exited on signal 11
  [ -f "$FPMLOG" ] && awk "$MON"'
    /exited on signal/ { split($1,a,"-"); d=substr(a[1],2); mo=M[a[2]]; yr=a[3]; t=substr($2,1,8); h=substr(t,1,2)
      k=yr"-"mo"-"d" "h; if(!(k in n)){first[k]=t}; n[k]++; last[k]=t }
    /fpm is running/ { split($1,a,"-"); printf "%s-%s-%s %s\tFPM log\tFPM started\n", a[3], M[a[2]], substr(a[1],2), substr($2,1,5) }
    END{ for(k in n) printf "%s:%s\tFPM log\tworker exited abnormally x%d (%s~%s)\n", k, substr(first[k],4,2), n[k], first[k], last[k] }' "$FPMLOG"

  # Error log: 2026/10/23 03:15:27 [error] ... Connection reset by peer
  [ -f "$ERROR" ] && awk '
    /Connection reset by peer|prematurely closed/ { gsub("/","-",$1); h=substr($2,1,2); k=$1" "h; if(!(k in n)) first[k]=$2; n[k]++; last[k]=$2 }
    END{ for(k in n) printf "%s:%s\tNginx error log\tconnection to PHP reset x%d (%s~%s)\n", k, substr(first[k],4,2), n[k], first[k], last[k] }' "$ERROR"

  # Access log: only non-browser User-Agents. The same address and hour become one line
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
        for(code in done){ if((k" "code) in st) codes=codes (codes==""?"":", ") code" x"st[k" "code] }
        delete done
        where = (np[k]==1) ? path[k] : np[k]" paths"
        printf "%s %s:%s\taccess log\t%s made %d requests (%s, responses %s)\n", p[2], p[3], substr(first[k],4,2), p[1], n[k], where, codes } }' "$ACCESS"

  # File-change record: date time owner path. The same minute and owner become one line
  [ -f "$FILES" ] && grep -v '^#' "$FILES" | awk '
    { k=$1" "substr($2,1,5)" "$3; if(!(k in n)){order[++c]=k; ex[k]=$4}; n[k]++ }
    END{ for(i=1;i<=c;i++){ k=order[i]; split(k,p," "); who=p[3]
        if(n[k]>1) printf "%s %s\tfile change\t%s changed %d files (%s and others)\n", p[1], p[2], who, n[k], ex[k]
        else printf "%s %s\tfile change\t%s changed: %s\n", p[1], p[2], who, ex[k] } }'
} | sort | awk -F'\t' '{ printf "%s  [%s] %s\n", $1, $2, $3 }'
echo
echo "────────────────────────────────────────"
echo "This table gathers candidates to look at together, in time order. Do not confirm or rule out a compromise from it alone."
