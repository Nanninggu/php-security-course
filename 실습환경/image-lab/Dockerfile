# [4-3] 공식 php Docker 이미지로 만든 앱 (Apache + mod_php: PHP2Shell 위험이 가장 큰 구성)
#
# 실습 순서
#   1) 이 상태로 빌드하고 버전 확인 → 8.3.35 (패치 전)
#   2) 아래 FROM 줄을 8.3.36-apache로 바꾼다
#   3) docker compose --profile image up -d --build image-app   ← 다시 빌드해야 바뀐다
#
# 운영에서는 태그를 고정하고(8.3.36-apache), 가능하면 digest(@sha256:...)까지 고정해
# "어떤 이미지가 돌고 있는지"를 기록으로 남긴다.
FROM php:8.3.35-apache

COPY index.php /var/www/html/index.php
