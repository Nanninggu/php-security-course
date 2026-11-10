<?php
// 교육용: 이 컨테이너에서 웹 요청을 처리하는 PHP 버전을 보여 준다. 운영 서비스에서는 버전을 노출하지 않는다.
header('Content-Type: text/plain; charset=utf-8');
printf("PHP_VERSION  %s\nPHP_SAPI     %s\n", PHP_VERSION, PHP_SAPI);
