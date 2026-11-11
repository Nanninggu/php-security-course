# [4-3] An app built from the official php Docker image (Apache + mod_php: the setup with the biggest PHP2Shell risk)
#
# Lab steps
#   1) Build as is and check the version -> 8.3.35 (before the patch)
#   2) Change the FROM line below to 8.3.36-apache
#   3) docker compose --profile image up -d --build image-app   <- it changes only if you rebuild
#
# In production, pin the tag (8.3.36-apache), and if you can, pin the digest (@sha256:...) too,
# so that "which image is running" is on record.
FROM php:8.3.35-apache

COPY index.php /var/www/html/index.php
