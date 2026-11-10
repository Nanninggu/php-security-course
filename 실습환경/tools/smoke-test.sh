#!/bin/bash
# [4-4] 패치 후 샘플 서비스의 주요 기능이 그대로 동작하는지 확인한다.
# 사용: bash smoke-test.sh   (실습 서버 안에서 실행)
# 확인 항목: 첫 화면 · 로그인 · 세션 유지 · 첨부 업로드/다운로드 · XML 가져오기 · CLI 배치 · PHP 워커 비정상 종료

BASE=${BASE:-http://127.0.0.1}
USER_ID=${USER_ID:-admin}
USER_PW=${USER_PW:-lab-password-1234}
FPM_LOG=${FPM_LOG:-/var/log/php8.3-fpm.log}

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
jar=$work/cookies; pass=0; fail=0
crash_before=$(grep -cE 'exited on signal' "$FPM_LOG" 2>/dev/null || echo 0)

ok()  { echo "  [통과] $1"; pass=$((pass+1)); }
bad() { echo "  [실패] $1"; fail=$((fail+1)); }
csrf() { grep -oE 'name="csrf" value="[0-9a-f]+"' "$1" | head -1 | sed 's/.*value="//; s/"//'; }

echo "== 샘플 서비스 점검 ($BASE)"

code=$(curl -s -c "$jar" -b "$jar" -o "$work/index.html" -w '%{http_code}' "$BASE/")
[ "$code" = 200 ] && grep -q '로그인' "$work/index.html" && ok "첫 화면 열림" || bad "첫 화면 (HTTP $code)"

token=$(csrf "$work/index.html")
loc=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{redirect_url}' \
  --data-urlencode "csrf=$token" --data-urlencode "username=$USER_ID" --data-urlencode "password=$USER_PW" "$BASE/login.php")
[[ $loc == */board.php ]] && ok "로그인" || bad "로그인 (이동 주소: ${loc:-없음})"

curl -s -c "$jar" -b "$jar" -o "$work/board.html" "$BASE/board.php"
grep -q '로그아웃' "$work/board.html" && ok "세션 유지 (로그인 상태로 목록 열림)" || bad "세션 유지"

token=$(csrf "$work/board.html")
name="smoke-$(date +%H%M%S).txt"; echo "smoke test $(date)" > "$work/$name"
loc=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{redirect_url}' \
  -F "csrf=$token" -F "title=점검용 공지 $name" -F "body=자동 점검" -F "attachment=@$work/$name" "$BASE/post.php")
[[ $loc == *msg=posted* ]] && ok "공지 등록 + 첨부 업로드" || bad "공지 등록 + 첨부 업로드 (이동 주소: ${loc:-없음})"

curl -s -c "$jar" -b "$jar" -o "$work/board.html" "$BASE/board.php"
id=$(grep -oE "download\.php\?id=[0-9]+\">$name" "$work/board.html" | grep -oE '[0-9]+' | head -1)
if [ -n "$id" ] && curl -s -b "$jar" "$BASE/download.php?id=$id" | cmp -s - "$work/$name"; then
  ok "첨부 다운로드 (올린 파일과 같음)"
else
  bad "첨부 다운로드"
fi

cat > "$work/notices.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<notices>
  <notice><title>XML 점검 공지 1</title><body>가져오기 확인</body></notice>
  <notice><title>XML 점검 공지 2</title><body>가져오기 확인</body></notice>
</notices>
XML
token=$(csrf "$work/board.html")
loc=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{redirect_url}' -F "csrf=$token" -F "xml=@$work/notices.xml" "$BASE/import.php")
[[ $loc == *msg=imported*n=2* ]] && ok "XML 가져오기 (SimpleXML, 2건)" || bad "XML 가져오기 (이동 주소: ${loc:-없음})"

if out=$(su -s /bin/sh www-data -c "php /var/www/app/bin/daily-report.php" 2>&1) && grep -q '일일 리포트' <<<"$out"; then
  ok "CLI 배치: $(head -1 <<<"$out" | sed 's/^\[[^]]*\] //')"
else
  bad "CLI 배치: $(head -2 <<<"$out")"
fi

crash_after=$(grep -cE 'exited on signal' "$FPM_LOG" 2>/dev/null || echo 0)
[ "$crash_after" = "$crash_before" ] && ok "점검 중 PHP 워커 비정상 종료 없음" \
  || bad "점검 중 PHP 워커 비정상 종료 $((crash_after-crash_before))건 ($FPM_LOG 확인)"

echo
echo "결과: 통과 $pass · 실패 $fail"
[ $fail = 0 ]
