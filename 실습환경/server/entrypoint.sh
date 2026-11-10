#!/bin/bash
# 컨테이너를 작은 서버처럼 띄운다: php-fpm과 nginx를 서비스로 시작하고 컨테이너는 계속 켜 둔다.
# 서비스는 `service php8.3-fpm restart`처럼 운영 서버와 같은 방식으로 다시 시작할 수 있다.
# (실제 서버의 systemctl 대신 컨테이너에는 systemd가 없어서 service 명령을 쓴다.)
set -e

mkdir -p /var/www/app/storage/uploads /var/lib/lab
chown -R www-data:www-data /var/www/app/storage /var/lib/lab

# 샘플 서비스 DB가 없으면 만든다 (계정: admin / lab-password-1234, 교육용)
if [ ! -f /var/lib/lab/board.sqlite ]; then
  su -s /bin/sh www-data -c "php8.3 /var/www/app/bin/setup.php"
fi

service php8.3-fpm start
service nginx start

echo "실습 서버가 준비됐습니다: http://localhost:8080"
exec sleep infinity
