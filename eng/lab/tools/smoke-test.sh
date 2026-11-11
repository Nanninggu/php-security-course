#!/bin/bash
# [4-4] After patching, check that the sample service's main features still work.
# Usage: bash smoke-test.sh   (run inside the lab server)
# Checks: home page · sign in · session kept · attachment upload/download · XML import · CLI batch · PHP worker crash

BASE=${BASE:-http://127.0.0.1}
USER_ID=${USER_ID:-admin}
USER_PW=${USER_PW:-lab-password-1234}
FPM_LOG=${FPM_LOG:-/var/log/php8.3-fpm.log}

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
jar=$work/cookies; pass=0; fail=0
crash_before=$(grep -cE 'exited on signal' "$FPM_LOG" 2>/dev/null || echo 0)

ok()  { echo "  [PASS] $1"; pass=$((pass+1)); }
bad() { echo "  [FAIL] $1"; fail=$((fail+1)); }
csrf() { grep -oE 'name="csrf" value="[0-9a-f]+"' "$1" | head -1 | sed 's/.*value="//; s/"//'; }

echo "== Sample service check ($BASE)"

code=$(curl -s -c "$jar" -b "$jar" -o "$work/index.html" -w '%{http_code}' "$BASE/")
[ "$code" = 200 ] && grep -q 'Sign in' "$work/index.html" && ok "Home page opens" || bad "Home page (HTTP $code)"

token=$(csrf "$work/index.html")
loc=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{redirect_url}' \
  --data-urlencode "csrf=$token" --data-urlencode "username=$USER_ID" --data-urlencode "password=$USER_PW" "$BASE/login.php")
[[ $loc == */board.php ]] && ok "Sign in" || bad "Sign in (redirected to: ${loc:-none})"

curl -s -c "$jar" -b "$jar" -o "$work/board.html" "$BASE/board.php"
grep -q 'Sign out' "$work/board.html" && ok "Session kept (board opens while signed in)" || bad "Session kept"

token=$(csrf "$work/board.html")
name="smoke-$(date +%H%M%S).txt"; echo "smoke test $(date)" > "$work/$name"
loc=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{redirect_url}' \
  -F "csrf=$token" -F "title=Smoke test notice $name" -F "body=Automatic check" -F "attachment=@$work/$name" "$BASE/post.php")
[[ $loc == *msg=posted* ]] && ok "Post notice + attachment upload" || bad "Post notice + attachment upload (redirected to: ${loc:-none})"

curl -s -c "$jar" -b "$jar" -o "$work/board.html" "$BASE/board.php"
id=$(grep -oE "download\.php\?id=[0-9]+\">$name" "$work/board.html" | grep -oE '[0-9]+' | head -1)
if [ -n "$id" ] && curl -s -b "$jar" "$BASE/download.php?id=$id" | cmp -s - "$work/$name"; then
  ok "Attachment download (same as uploaded)"
else
  bad "Attachment download"
fi

cat > "$work/notices.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<notices>
  <notice><title>XML check notice 1</title><body>Import check</body></notice>
  <notice><title>XML check notice 2</title><body>Import check</body></notice>
</notices>
XML
token=$(csrf "$work/board.html")
loc=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{redirect_url}' -F "csrf=$token" -F "xml=@$work/notices.xml" "$BASE/import.php")
[[ $loc == *msg=imported*n=2* ]] && ok "XML import (SimpleXML, 2 items)" || bad "XML import (redirected to: ${loc:-none})"

if out=$(su -s /bin/sh www-data -c "php /var/www/app/bin/daily-report.php" 2>&1) && grep -q 'Daily report' <<<"$out"; then
  ok "CLI batch: $(head -1 <<<"$out" | sed 's/^\[[^]]*\] //')"
else
  bad "CLI batch: $(head -2 <<<"$out")"
fi

crash_after=$(grep -cE 'exited on signal' "$FPM_LOG" 2>/dev/null || echo 0)
[ "$crash_after" = "$crash_before" ] && ok "No PHP worker crash during the check" \
  || bad "PHP worker crashed $((crash_after-crash_before)) time(s) during the check (see $FPM_LOG)"

echo
echo "Result: $pass passed · $fail failed"
[ $fail = 0 ]
