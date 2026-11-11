<?php
// For teaching: shows the PHP version that handles web requests in this container. Do not expose the version in production.
header('Content-Type: text/plain; charset=utf-8');
printf("PHP_VERSION  %s\nPHP_SAPI     %s\n", PHP_VERSION, PHP_SAPI);
