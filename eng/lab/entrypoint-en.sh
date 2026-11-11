#!/bin/bash
# English-edition entrypoint. docker-compose.yml mounts this file over the image's /usr/local/sbin/lab-entrypoint
# so the startup message is in English without rebuilding the image shared with the Korean lab.
set -e

mkdir -p /var/www/app/storage/uploads /var/lib/lab
chown -R www-data:www-data /var/www/app/storage /var/lib/lab

# Create the sample service DB if it does not exist (account: admin / lab-password-1234, for teaching)
if [ ! -f /var/lib/lab/board.sqlite ]; then
  su -s /bin/sh www-data -c "php8.3 /var/www/app/bin/setup.php"
fi

service php8.3-fpm start
service nginx start

echo "The lab server is ready: http://localhost:8090"
exec sleep infinity
